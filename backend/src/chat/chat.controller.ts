import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
  Delete,
} from '@nestjs/common';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUserId } from '../auth/current-user';
import { SnapService } from './snap.service';

@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(
    private readonly chatService: ChatService,
    private readonly snapService: SnapService,
  ) {}

  @Get('conversations')
  async getConversations(@CurrentUserId() userId: string) {
    return this.chatService.getUserConversations(userId);
  }

  @Post('conversations')
  async createConversation(
    @CurrentUserId() userId: string,
    @Body('participantIds') participantIds: string[],
    @Body('isGroup') isGroup?: boolean,
    @Body('name') name?: string,
  ) {
    return this.chatService.createConversation(
      userId,
      participantIds,
      isGroup,
      name,
    );
  }

  @Get('conversations/:id/messages')
  async getMessages(
    @CurrentUserId() userId: string,
    @Param('id', ParseUUIDPipe) conversationId: string,
  ) {
    return this.chatService.getMessages(conversationId, userId);
  }

  @Delete('conversations/:id/messages/:messageId')
  async deleteMessage(
    @CurrentUserId() userId: string,
    @Param('id', ParseUUIDPipe) conversationId: string,
    @Param('messageId', ParseUUIDPipe) messageId: string,
  ) {
    return this.chatService.deleteMessage(messageId, userId);
  }

  @Post('snaps/:messageId/open')
  async openSnap(@CurrentUserId() userId: string) {
    return this.chatService.openSnap(userId, messageId);
  }
}
