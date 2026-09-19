import { Test, TestingModule } from '@nestjs/testing';
import { SafetyService } from './safety.service';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ReportCategory, AccountStatus } from '@prisma/client';

describe('SafetyService', () => {
  let service: SafetyService;
  let prisma: PrismaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SafetyService,
        {
          provide: PrismaService,
          useValue: {
            user: {
              findUnique: jest.fn(),
              update: jest.fn(),
            },
            block: {
              findUnique: jest.fn(),
              create: jest.fn(),
              delete: jest.fn(),
              findMany: jest.fn(),
            },
            match: {
              findFirst: jest.fn(),
              update: jest.fn(),
            },
            report: {
              create: jest.fn(),
            },
          },
        },
      ],
    }).compile();

    service = module.get<SafetyService>(SafetyService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('blockUser', () => {
    it('should throw BadRequestException if blocking self', async () => {
      await expect(service.blockUser('user-1', 'user-1')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw NotFoundException if target user not found', async () => {
      (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);
      await expect(service.blockUser('user-1', 'user-2')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should block user and unmatch if match exists', async () => {
      (prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 'user-2' });
      (prisma.block.findUnique as jest.Mock).mockResolvedValue(null);
      (prisma.block.create as jest.Mock).mockResolvedValue({ id: 'block-1' });
      (prisma.match.findFirst as jest.Mock).mockResolvedValue({
        id: 'match-1',
      });
      (prisma.match.update as jest.Mock).mockResolvedValue({ id: 'match-1' });

      const result = await service.blockUser('user-1', 'user-2');

      expect(prisma.block.create).toHaveBeenCalled();
      expect(prisma.match.update).toHaveBeenCalled();
      expect(result).toEqual({ blocked: true });
    });
  });

  describe('unblockUser', () => {
    it('should unblock user if blocked', async () => {
      (prisma.block.findUnique as jest.Mock).mockResolvedValue({
        id: 'block-1',
      });
      (prisma.block.delete as jest.Mock).mockResolvedValue({ id: 'block-1' });

      const result = await service.unblockUser('user-1', 'user-2');

      expect(prisma.block.delete).toHaveBeenCalled();
      expect(result).toEqual({ unblocked: true });
    });
  });

  describe('getBlockedUsers', () => {
    it('should return list of blocked user ids', async () => {
      (prisma.block.findMany as jest.Mock).mockResolvedValue([
        { blockedId: 'user-2' },
        { blockedId: 'user-3' },
      ]);
      const result = await service.getBlockedUsers('user-1');
      expect(result).toEqual(['user-2', 'user-3']);
    });
  });

  describe('reportUser', () => {
    it('should throw BadRequestException if reporting self', async () => {
      await expect(
        service.reportUser('user-1', {
          targetUserId: 'user-1',
          category: ReportCategory.SPAM,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should create a report', async () => {
      (prisma.report.create as jest.Mock).mockResolvedValue({ id: 'report-1' });
      const dto = {
        targetUserId: 'user-2',
        category: ReportCategory.SPAM,
        details: 'spamming',
      };
      const result = await service.reportUser('user-1', dto);
      expect(prisma.report.create).toHaveBeenCalled();
      expect(result).toEqual({ reported: true, reportId: 'report-1' });
    });
  });

  describe('deleteAccount', () => {
    it('should mark account as deleted', async () => {
      (prisma.user.update as jest.Mock).mockResolvedValue({
        id: 'user-1',
        status: AccountStatus.DELETED,
      });
      const result = await service.deleteAccount('user-1');
      expect(prisma.user.update).toHaveBeenCalled();
      expect(result).toEqual({ deleted: true });
    });
  });
});
