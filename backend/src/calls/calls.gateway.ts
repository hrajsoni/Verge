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
import { CallsService } from './calls.service';

@WebSocketGateway({ cors: { origin: '*' } })
export class CallsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(
    private readonly jwtService: JwtService,
    private readonly callsService: CallsService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token =
        client.handshake.auth.token ||
        client.handshake.headers['authorization']?.split(' ')[1];
      if (!token) {
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token, {
        secret: process.env.JWT_SECRET || 'change-me-in-production',
      });
      client.data.userId = payload.sub;
    } catch {
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    // client left
  }

  @SubscribeMessage('call_join')
  async handleJoin(
    @MessageBody() data: { callId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const userId = client.data.userId;
    if (!userId) {
      client.emit('error', { message: 'Unauthorized' });
      return;
    }

    const isParticipant = await this.callsService.checkCallParticipant(
      userId,
      data.callId,
    );
    if (!isParticipant) {
      client.emit('error', { message: 'Forbidden: not a call participant' });
      return;
    }

    const room = `call_${data.callId}`;
    await client.join(room);
  }

  @SubscribeMessage('call_leave')
  async handleLeave(
    @MessageBody() data: { callId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const room = `call_${data.callId}`;
    await client.leave(room);
  }

  @SubscribeMessage('call_signal')
  async handleSignal(
    @MessageBody() data: { callId: string; signal: any },
    @ConnectedSocket() client: Socket,
  ) {
    const userId = client.data.userId;
    if (!userId) {
      client.emit('error', { message: 'Unauthorized' });
      return;
    }

    const room = `call_${data.callId}`;
    client.to(room).emit('call_signal', {
      fromUserId: userId,
      signal: data.signal,
    });
  }
}
