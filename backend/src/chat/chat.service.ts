import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SendMessageDto } from './chat.dto';
import { MessageType, SnapViewState } from '@prisma/client';

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService) {}

  async getConversations(userId: string) {
    const memberships = await this.prisma.conversationMember.findMany({
      where: { userId },
      include: {
        conversation: {
          include: {
            members: {
              where: { userId: { not: userId } },
              include: {
                user: {
                  include: {
                    profile: true,
                  },
                },
              },
            },
            messages: {
              orderBy: { createdAt: 'desc' },
              take: 1,
            },
          },
        },
      },
    });

    const conversations: any[] = [];

    for (const membership of memberships) {
      const conv = membership.conversation;
      const otherMember = conv.members[0];
      const lastMessage = conv.messages[0] || null;

      // Count unread
      let unreadCount = 0;
      if (membership.lastReadAt) {
        unreadCount = await this.prisma.message.count({
          where: {
            conversationId: conv.id,
            createdAt: { gt: membership.lastReadAt },
            senderId: { not: userId },
          },
        });
      } else {
        unreadCount = await this.prisma.message.count({
          where: {
            conversationId: conv.id,
            senderId: { not: userId },
          },
        });
      }

      conversations.push({
        id: conv.id,
        matchId: conv.matchId,
        createdAt: conv.createdAt,
        lastMessage,
        unreadCount,
        otherParticipant: otherMember?.user?.profile || null,
      });
    }

    return conversations.sort((a, b) => {
      const tA = a.lastMessage?.createdAt?.getTime() || a.createdAt.getTime();
      const tB = b.lastMessage?.createdAt?.getTime() || b.createdAt.getTime();
      return tB - tA;
    });
  }

  async checkMembership(userId: string, conversationId: string) {
    const member = await this.prisma.conversationMember.findUnique({
      where: {
        conversationId_userId: {
          conversationId,
          userId,
        },
      },
    });

    if (!member) {
      throw new ForbiddenException('Not a member of this conversation');
    }

    return member;
  }

  async getMessages(userId: string, conversationId: string, limit: number = 50, cursor?: string) {
    await this.checkMembership(userId, conversationId);

    const messages = await this.prisma.message.findMany({
      where: { conversationId },
      take: limit,
      skip: cursor ? 1 : 0,
      cursor: cursor ? { id: cursor } : undefined,
      orderBy: { createdAt: 'desc' },
      include: {
        media: true,
      },
    });

    return messages;
  }

  async sendMessage(userId: string, conversationId: string, dto: SendMessageDto) {
    await this.checkMembership(userId, conversationId);

    const messageData: any = {
      conversationId,
      senderId: userId,
      type: dto.type,
      text: dto.text,
      mediaId: dto.mediaId,
    };

    if (dto.type === MessageType.SNAP) {
      messageData.snapViewState = SnapViewState.SENT;
    }

    const message = await this.prisma.message.create({
      data: messageData,
      include: { media: true },
    });

    // Update lastReadAt for the sender
    await this.prisma.conversationMember.update({
      where: { conversationId_userId: { conversationId, userId } },
      data: { lastReadAt: new Date() },
    });

    return message;
  }

  async markRead(userId: string, conversationId: string) {
    await this.checkMembership(userId, conversationId);

    await this.prisma.conversationMember.update({
      where: { conversationId_userId: { conversationId, userId } },
      data: { lastReadAt: new Date() },
    });

    return { success: true };
  }

  async openSnap(userId: string, messageId: string) {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
    });

    if (!message) {
      throw new NotFoundException('Message not found');
    }

    if (message.type !== MessageType.SNAP) {
      throw new ForbiddenException('Message is not a snap');
    }

    if (message.senderId === userId) {
      throw new ForbiddenException('Cannot open your own snap');
    }

    await this.checkMembership(userId, message.conversationId);

    if (message.snapViewState === SnapViewState.OPENED || message.snapViewState === SnapViewState.EXPIRED) {
      throw new ForbiddenException('Snap already opened or expired');
    }

    const expiresAt = new Date();
    // Default to 10 seconds if we had a way to store it, but for now just 10s
    expiresAt.setSeconds(expiresAt.getSeconds() + 10);

    const updated = await this.prisma.message.update({
      where: { id: messageId },
      data: {
        snapViewState: SnapViewState.OPENED,
        snapExpiresAt: expiresAt,
      },
      include: { media: true },
    });

    return updated;
  }
}
