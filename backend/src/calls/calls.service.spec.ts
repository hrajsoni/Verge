import { Test, TestingModule } from '@nestjs/testing';
import { CallsService } from './calls.service';
import { PrismaService } from '../prisma/prisma.service';
import { CallKind, CallState } from '@prisma/client';
import {
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';

describe('CallsService', () => {
  let service: CallsService;
  let prisma: PrismaService;

  const mockPrismaService = {
    conversation: {
      findUnique: jest.fn(),
    },
    call: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      findFirst: jest.fn(),
    },
    block: {
      findFirst: jest.fn().mockResolvedValue(null),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CallsService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<CallsService>(CallsService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('initiateCall', () => {
    it('should throw NotFoundException if conversation not found', async () => {
      mockPrismaService.conversation.findUnique.mockResolvedValue(null);

      await expect(
        service.initiateCall('callerId', {
          conversationId: 'convId',
          kind: CallKind.VOICE,
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should create a call successfully', async () => {
      mockPrismaService.conversation.findUnique.mockResolvedValue({
        id: 'convId',
        members: [{ userId: 'callerId' }, { userId: 'otherId' }],
      });
      mockPrismaService.call.findFirst.mockResolvedValue(null);
      mockPrismaService.call.create.mockResolvedValue({
        id: 'callId',
        state: CallState.CALLING,
      });

      const result = await service.initiateCall('callerId', {
        conversationId: 'convId',
        kind: CallKind.VOICE,
      });

      expect(result).toBeDefined();
      expect(mockPrismaService.call.create).toHaveBeenCalled();
    });
  });

  describe('acceptCall', () => {
    it('should change state to CONNECTED', async () => {
      mockPrismaService.call.findUnique.mockResolvedValue({
        id: 'callId',
        state: CallState.CALLING,
        participants: [{ userId: 'userId' }],
      });
      mockPrismaService.call.update.mockResolvedValue({
        id: 'callId',
        state: CallState.CONNECTED,
      });

      const result = await service.acceptCall('userId', 'callId');
      expect(result.state).toBe(CallState.CONNECTED);
    });
  });
});
