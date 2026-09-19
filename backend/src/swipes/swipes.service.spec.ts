import { Test, TestingModule } from '@nestjs/testing';
import { SwipesService } from './swipes.service';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException } from '@nestjs/common';

describe('SwipesService', () => {
  let service: SwipesService;
  let prisma: PrismaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SwipesService,
        {
          provide: PrismaService,
          useValue: {
            like: {
              upsert: jest.fn(),
              findUnique: jest.fn(),
            },
            pass: {
              upsert: jest.fn(),
            },
            block: {
              findFirst: jest.fn().mockResolvedValue(null),
            },
            $transaction: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<SwipesService>(SwipesService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('recordLike', () => {
    it('should throw BadRequestException if liking self', async () => {
      await expect(service.recordLike('user1', 'user1')).rejects.toThrow(BadRequestException);
    });

    it('should return matched: false if not mutual', async () => {
      jest.spyOn(prisma.like, 'upsert').mockResolvedValue(null as any);
      jest.spyOn(prisma.like, 'findUnique').mockResolvedValue(null);

      const result = await service.recordLike('user1', 'user2');
      expect(result).toEqual({ matched: false });
    });

    it('should create match and conversation if mutual like', async () => {
      jest.spyOn(prisma.like, 'upsert').mockResolvedValue(null as any);
      jest.spyOn(prisma.like, 'findUnique').mockResolvedValue({ id: 'like-id' } as any);
      jest.spyOn(prisma, '$transaction').mockResolvedValue({ matchId: 'match-id', conversationId: 'conv-id' });

      const result = await service.recordLike('user1', 'user2');
      expect(result).toEqual({ matched: true, matchId: 'match-id', conversationId: 'conv-id' });
    });
  });

  describe('recordPass', () => {
    it('should throw BadRequestException if passing self', async () => {
      await expect(service.recordPass('user1', 'user1')).rejects.toThrow(BadRequestException);
    });

    it('should create pass record', async () => {
      jest.spyOn(prisma.pass, 'upsert').mockResolvedValue(null as any);

      const result = await service.recordPass('user1', 'user2');
      expect(result).toEqual({ passed: true });
    });
  });
});
