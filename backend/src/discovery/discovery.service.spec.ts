import { Test, TestingModule } from '@nestjs/testing';
import { DiscoveryService } from './discovery.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotFoundException } from '@nestjs/common';

jest.mock('../common/geo', () => ({
  haversineKm: jest.fn().mockReturnValue(10),
  distanceLabel: jest.fn().mockReturnValue('10+ km away'),
  yearsSince: jest.fn().mockReturnValue(25),
}));

jest.mock('./ranking', () => {
  const original = jest.requireActual('./ranking');
  return {
    ...original,
    rankCandidates: jest.fn().mockReturnValue([]),
  };
});

describe('DiscoveryService', () => {
  let service: DiscoveryService;
  let prisma: PrismaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DiscoveryService,
        {
          provide: PrismaService,
          useValue: {
            user: {
              findUnique: jest.fn(),
              findMany: jest.fn(),
            },
          },
        },
      ],
    }).compile();

    service = module.get<DiscoveryService>(DiscoveryService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getFeed', () => {
    it('should throw NotFoundException if user not found', async () => {
      jest.spyOn(prisma.user, 'findUnique').mockResolvedValue(null);
      await expect(service.getFeed('user1')).rejects.toThrow(NotFoundException);
    });

    it('should throw NotFoundException if user location missing', async () => {
      jest
        .spyOn(prisma.user, 'findUnique')
        .mockResolvedValue({ preferences: {} } as any);
      await expect(service.getFeed('user1')).rejects.toThrow(NotFoundException);
    });

    it('should return empty array if no candidates', async () => {
      jest.spyOn(prisma.user, 'findUnique').mockResolvedValue({
        id: 'user1',
        preferences: {
          minAge: 18,
          maxAge: 99,
          maxDistanceKm: 100,
          genders: [],
          lookingFor: [],
        },
        location: { latitude: 0, longitude: 0 },
        interests: [],
        blocksSent: [],
        blocksReceived: [],
        likesSent: [],
        passesSent: [],
      } as any);
      jest.spyOn(prisma.user, 'findMany').mockResolvedValue([]);

      const result = await service.getFeed('user1');
      expect(result).toEqual([]);
    });
  });
});
