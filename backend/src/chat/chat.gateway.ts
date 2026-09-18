import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ChatService } from './chat.service';
import { SendMessageDto } from './chat.dto';

@WebSocketGateway({ cors: { origin: '*' } })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(
    private readonly jwtService: JwtService,
    private readonly chatService: ChatService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token || client.handshake.headers['authorization']?.split(' ')[1];
      if (!token) {
        client.disconnect();
        return;
      }
      
      const payload = this.jwtService.verify(token, { secret: process.env.JWT_SECRET || 'change-me-in-production' });
      client.data.userId = payload.sub;
    } catch (e) {
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    // client left
  }

  @SubscribeMessage('join_conversation')
  async handleJoinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    try {
      await this.chatService.checkMembership(client.data.userId, data.conversationId);
      client.join(`conversation_${data.conversationId}`);
    } catch (e) {
      // Not a member
    }
  }

  @SubscribeMessage('leave_conversation')
  handleLeaveConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    client.leave(`conversation_${data.conversationId}`);
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; message: SendMessageDto },
  ) {
    try {
      const message = await this.chatService.sendMessage(
        client.data.userId,
        data.conversationId,
        data.message,
      );

      this.server.to(`conversation_${data.conversationId}`).emit('new_message', {
        conversationId: data.conversationId,
        message,
      });
    } catch (e) {
      // Error handling
    }
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    client.to(`conversation_${data.conversationId}`).emit('user_typing', {
      conversationId: data.conversationId,
      userId: client.data.userId,
    });
  }

  @SubscribeMessage('stop_typing')
  handleStopTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    client.to(`conversation_${data.conversationId}`).emit('user_stop_typing', {
      conversationId: data.conversationId,
      userId: client.data.userId,
    });
  }

  @SubscribeMessage('message_read')
  async handleMessageRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    try {
      await this.chatService.markRead(client.data.userId, data.conversationId);
      this.server.to(`conversation_${data.conversationId}`).emit('messages_read', {
        conversationId: data.conversationId,
        userId: client.data.userId,
      });
    } catch (e) {
      // Error handling
    }
  }
}
