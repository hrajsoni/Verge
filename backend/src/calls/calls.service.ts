import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { InitiateCallDto } from './calls.dto';
import { CallState, CallKind } from '@prisma/client';

@Injectable()
export class CallsService {
  constructor(private prisma: PrismaService) {}

  async initiateCall(callerId: string, dto: InitiateCallDto) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: dto.conversationId },
      include: { members: true },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    const callerMember = conversation.members.find(m => m.userId === callerId);
    if (!callerMember) {
      throw new ForbiddenException('User is not a member of this conversation');
    }

    const otherMember = conversation.members.find(m => m.userId !== callerId);
    if (!otherMember) {
      throw new BadRequestException('Cannot initiate a call in an empty conversation');
    }

    const isBlocked = await this.prisma.block.findFirst({
      where: {
        OR: [
          { blockerId: callerId, blockedId: otherMember.userId },
          { blockerId: otherMember.userId, blockedId: callerId },
        ],
      },
    });
    if (isBlocked) {
      throw new ForbiddenException('Cannot call a blocked user');
    }

    const activeCall = await this.getActiveCall(dto.conversationId);
    if (activeCall) {
      throw new BadRequestException('An active call already exists in this conversation');
    }

    const call = await this.prisma.call.create({
      data: {
        conversationId: dto.conversationId,
        kind: dto.kind,
        state: CallState.CALLING,
        participants: {
          create: [
            { userId: callerId, role: 'caller' },
            { userId: otherMember.userId, role: 'callee' },
          ],
        },
      },
      include: {
        participants: true,
      },
    });

    return call;
  }

  async acceptCall(userId: string, callId: string) {
    const call = await this.prisma.call.findUnique({
      where: { id: callId },
      include: { participants: true },
    });

    if (!call) throw new NotFoundException('Call not found');
    
    const participant = call.participants.find(p => p.userId === userId);
    if (!participant) throw new ForbiddenException('Not a participant in this call');

    if (call.state !== CallState.CALLING && call.state !== CallState.RINGING) {
      throw new BadRequestException('Call cannot be accepted in its current state');
    }

    return this.prisma.call.update({
      where: { id: callId },
      data: {
        state: CallState.CONNECTED,
        connectedAt: new Date(),
      },
      include: { participants: true },
    });
  }

  async rejectCall(userId: string, callId: string) {
    const call = await this.prisma.call.findUnique({
      where: { id: callId },
      include: { participants: true },
    });

    if (!call) throw new NotFoundException('Call not found');
    
    const participant = call.participants.find(p => p.userId === userId);
    if (!participant) throw new ForbiddenException('Not a participant in this call');

    return this.prisma.call.update({
      where: { id: callId },
      data: {
        state: CallState.REJECTED,
        endedAt: new Date(),
      },
    });
  }

  async endCall(userId: string, callId: string) {
    const call = await this.prisma.call.findUnique({
      where: { id: callId },
      include: { participants: true },
    });

    if (!call) throw new NotFoundException('Call not found');
    
    const participant = call.participants.find(p => p.userId === userId);
    if (!participant) throw new ForbiddenException('Not a participant in this call');

    return this.prisma.call.update({
      where: { id: callId },
      data: {
        state: CallState.ENDED,
        endedAt: new Date(),
      },
    });
  }

  async getIceServers() {
    return [
      { urls: 'stun:stun.l.google.com:19302' },
      { urls: 'stun:stun1.l.google.com:19302' },
    ];
  }

  async getActiveCall(conversationId: string) {
    return this.prisma.call.findFirst({
      where: {
        conversationId,
        state: {
          notIn: [CallState.ENDED, CallState.REJECTED, CallState.MISSED],
        },
      },
      include: { participants: true },
    });
  }

  async checkCallParticipant(userId: string, callId: string): Promise<boolean> {
    const call = await this.prisma.call.findUnique({
      where: { id: callId },
      include: { participants: true },
    });
    if (!call) return false;
    return call.participants.some((p) => p.userId === userId);
  }
}
