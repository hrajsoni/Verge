import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { BlockUserDto, ReportUserDto } from './safety.dto';
import { AccountStatus, ReportStatus } from '@prisma/client';

@Injectable()
export class SafetyService {
  constructor(private readonly prisma: PrismaService) {}

  async blockUser(userId: string, targetUserId: string) {
    if (userId === targetUserId) {
      throw new BadRequestException('You cannot block yourself');
    }

    const targetUser = await this.prisma.user.findUnique({ where: { id: targetUserId } });
    if (!targetUser) {
      throw new NotFoundException('Target user not found');
    }

    const existingBlock = await this.prisma.block.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId: userId,
          blockedId: targetUserId,
        },
      },
    });

    if (!existingBlock) {
      await this.prisma.block.create({
        data: {
          blockerId: userId,
          blockedId: targetUserId,
        },
      });
    }

    const match = await this.prisma.match.findFirst({
      where: {
        OR: [
          { userAId: userId, userBId: targetUserId },
          { userAId: targetUserId, userBId: userId },
        ],
        unmatchedAt: null,
      },
    });

    if (match) {
      await this.prisma.match.update({
        where: { id: match.id },
        data: { unmatchedAt: new Date() },
      });
    }

    return { blocked: true };
  }

  async unblockUser(userId: string, targetUserId: string) {
    const existingBlock = await this.prisma.block.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId: userId,
          blockedId: targetUserId,
        },
      },
    });

    if (existingBlock) {
      await this.prisma.block.delete({
        where: { id: existingBlock.id },
      });
    }

    return { unblocked: true };
  }

  async getBlockedUsers(userId: string) {
    const blocks = await this.prisma.block.findMany({
      where: { blockerId: userId },
      select: { blockedId: true },
    });
    return blocks.map((b) => b.blockedId);
  }

  async reportUser(userId: string, dto: ReportUserDto) {
    if (userId === dto.targetUserId) {
      throw new BadRequestException('You cannot report yourself');
    }

    const report = await this.prisma.report.create({
      data: {
        reporterId: userId,
        targetId: dto.targetUserId,
        category: dto.category,
        details: dto.details ?? '',
        status: ReportStatus.NEW,
      },
    });

    return { reported: true, reportId: report.id };
  }

  async deleteAccount(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { status: AccountStatus.DELETED },
    });

    return { deleted: true };
  }
}
