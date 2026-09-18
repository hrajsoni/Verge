import { Controller, Get, Post, Body, Param, Query, UseGuards, ParseIntPipe, DefaultValuePipe } from '@nestjs/common';
import { ChatService } from './chat.service';
import { SendMessageDto } from './chat.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUserId } from '../auth/current-user';

@Controller()
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('conversations')
  async getConversations(@CurrentUserId() userId: string) {
    return this.chatService.getConversations(userId);
  }

  @Get('conversations/:id/messages')
  async getMessages(
    @CurrentUserId() userId: string,
    @Param('id') conversationId: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
    @Query('cursor') cursor?: string,
  ) {
    return this.chatService.getMessages(userId, conversationId, limit, cursor);
  }

  @Post('conversations/:id/messages')
  async sendMessage(
    @CurrentUserId() userId: string,
    @Param('id') conversationId: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.chatService.sendMessage(userId, conversationId, dto);
  }

  @Post('conversations/:id/read')
  async markRead(
    @CurrentUserId() userId: string,
    @Param('id') conversationId: string,
  ) {
    return this.chatService.markRead(userId, conversationId);
  }

  @Post('messages/:id/snap/open')
  async openSnap(
    @CurrentUserId() userId: string,
    @Param('id') messageId: string,
  ) {
    return this.chatService.openSnap(userId, messageId);
  }
}
