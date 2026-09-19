import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SwipesService {
  constructor(private readonly prisma: PrismaService) {}

  private pairKey(a: string, b: string): [string, string] {
    return a < b ? [a, b] : [b, a];
  }

  async recordLike(userId: string, targetUserId: string) {
    if (userId === targetUserId) {
      throw new BadRequestException('Cannot like yourself');
    }

    // Check if either user blocked the other
    const isBlocked = await this.prisma.block.findFirst({
      where: {
        OR: [
          { blockerId: userId, blockedId: targetUserId },
          { blockerId: targetUserId, blockedId: userId },
        ],
      },
    });
    if (isBlocked) {
      throw new BadRequestException('Cannot interact with this user');
    }

    // Upsert to handle repeated likes safely
    await this.prisma.like.upsert({
      where: {
        fromUserId_toUserId: {
          fromUserId: userId,
          toUserId: targetUserId,
        },
      },
      update: {},
      create: {
        fromUserId: userId,
        toUserId: targetUserId,
      },
    });

    // Check for mutual like
    const mutualLike = await this.prisma.like.findUnique({
      where: {
        fromUserId_toUserId: {
          fromUserId: targetUserId,
          toUserId: userId,
        },
      },
    });

    if (mutualLike) {
      const [userAId, userBId] = this.pairKey(userId, targetUserId);

      // Create Match and Conversation in transaction safely
      const result = await this.prisma.$transaction(async (tx) => {
        const match = await tx.match.upsert({
          where: {
            userAId_userBId: { userAId, userBId },
          },
          update: {},
          create: {
            userAId,
            userBId,
          },
        });

        const conversation = await tx.conversation.upsert({
          where: {
            matchId: match.id,
          },
          update: {},
          create: {
            matchId: match.id,
            members: {
              create: [{ userId: userAId }, { userId: userBId }],
            },
          },
        });

        return { matchId: match.id, conversationId: conversation.id };
      });

      return {
        matched: true,
        matchId: result.matchId,
        conversationId: result.conversationId,
      };
    }

    return { matched: false };
  }

  async recordPass(userId: string, targetUserId: string) {
    if (userId === targetUserId) {
      throw new BadRequestException('Cannot pass yourself');
    }

    await this.prisma.pass.upsert({
      where: {
        fromUserId_toUserId: {
          fromUserId: userId,
          toUserId: targetUserId,
        },
      },
      update: {},
      create: {
        fromUserId: userId,
        toUserId: targetUserId,
      },
    });

    return { passed: true };
  }
}
