import { Test, TestingModule } from '@nestjs/testing';
import { ChatService } from './chat.service';
import { PrismaService } from '../prisma/prisma.service';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { MessageType, SnapViewState } from '@prisma/client';

describe('ChatService', () => {
  let service: ChatService;
  let prisma: PrismaService;

  const mockPrisma = {
    conversationMember: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    message: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChatService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<ChatService>(ChatService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('checkMembership', () => {
    it('should throw ForbiddenException if user is not a member', async () => {
      mockPrisma.conversationMember.findUnique.mockResolvedValue(null);
      await expect(service.checkMembership('user-1', 'conv-1')).rejects.toThrow(ForbiddenException);
    });

    it('should return member if user is a member', async () => {
      const mockMember = { conversationId: 'conv-1', userId: 'user-1' };
      mockPrisma.conversationMember.findUnique.mockResolvedValue(mockMember);
      const res = await service.checkMembership('user-1', 'conv-1');
      expect(res).toEqual(mockMember);
    });
  });

  describe('sendMessage', () => {
    it('should send a message and update lastReadAt', async () => {
      const dto = { type: MessageType.TEXT, text: 'Hello' };
      const mockMember = { conversationId: 'conv-1', userId: 'user-1' };
      mockPrisma.conversationMember.findUnique.mockResolvedValue(mockMember);
      mockPrisma.message.create.mockResolvedValue({ id: 'msg-1', ...dto });
      mockPrisma.conversationMember.update.mockResolvedValue({});

      const res = await service.sendMessage('user-1', 'conv-1', dto);
      expect(res.id).toEqual('msg-1');
      expect(mockPrisma.message.create).toHaveBeenCalled();
      expect(mockPrisma.conversationMember.update).toHaveBeenCalled();
    });

    it('should set snapViewState if type is SNAP', async () => {
      const dto = { type: MessageType.SNAP, text: '' };
      const mockMember = { conversationId: 'conv-1', userId: 'user-1' };
      mockPrisma.conversationMember.findUnique.mockResolvedValue(mockMember);
      mockPrisma.message.create.mockResolvedValue({ id: 'msg-1', snapViewState: SnapViewState.SENT, ...dto });

      await service.sendMessage('user-1', 'conv-1', dto);
      expect(mockPrisma.message.create).toHaveBeenCalledWith(expect.objectContaining({
        data: expect.objectContaining({
          snapViewState: SnapViewState.SENT,
        }),
      }));
    });
  });

  describe('openSnap', () => {
    it('should throw NotFoundException if message not found', async () => {
      mockPrisma.message.findUnique.mockResolvedValue(null);
      await expect(service.openSnap('user-1', 'msg-1')).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException if message is not a snap', async () => {
      mockPrisma.message.findUnique.mockResolvedValue({ type: MessageType.TEXT });
      await expect(service.openSnap('user-1', 'msg-1')).rejects.toThrow(ForbiddenException);
    });

    it('should throw ForbiddenException if opening own snap', async () => {
      mockPrisma.message.findUnique.mockResolvedValue({
        type: MessageType.SNAP,
        senderId: 'user-1',
      });
      await expect(service.openSnap('user-1', 'msg-1')).rejects.toThrow(ForbiddenException);
    });

    it('should update snap to OPENED and set expiresAt', async () => {
      mockPrisma.message.findUnique.mockResolvedValue({
        type: MessageType.SNAP,
        senderId: 'user-2',
        conversationId: 'conv-1',
        snapViewState: SnapViewState.DELIVERED,
      });
      const mockMember = { conversationId: 'conv-1', userId: 'user-1' };
      mockPrisma.conversationMember.findUnique.mockResolvedValue(mockMember);
      mockPrisma.message.update.mockResolvedValue({ id: 'msg-1', snapViewState: SnapViewState.OPENED });

      const res = await service.openSnap('user-1', 'msg-1');
      expect(res.snapViewState).toEqual(SnapViewState.OPENED);
      expect(mockPrisma.message.update).toHaveBeenCalledWith(expect.objectContaining({
        data: expect.objectContaining({
          snapViewState: SnapViewState.OPENED,
          snapExpiresAt: expect.any(Date),
        }),
      }));
    });
  });
});
