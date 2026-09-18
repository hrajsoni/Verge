import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MatchingService {
  constructor(private readonly prisma: PrismaService) {}

  async getMatches(userId: string) {
    const matches = await this.prisma.match.findMany({
      where: {
        OR: [{ userAId: userId }, { userBId: userId }],
        unmatchedAt: null,
      },
      include: {
        conversation: true,
        userA: {
          include: {
            profile: true,
            photos: { include: { media: true }, orderBy: { sortOrder: 'asc' } },
          },
        },
        userB: {
          include: {
            profile: true,
            photos: { include: { media: true }, orderBy: { sortOrder: 'asc' } },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return matches.map((match) => {
      const otherUser = match.userAId === userId ? match.userB : match.userA;
      return {
        id: match.id,
        createdAt: match.createdAt,
        conversationId: match.conversation?.id,
        user: {
          id: otherUser.id,
          displayName: otherUser.profile?.displayName,
          photos: otherUser.photos.map((p) => ({
            id: p.id,
            url: p.media.objectKey,
          })),
        },
      };
    });
  }
}
