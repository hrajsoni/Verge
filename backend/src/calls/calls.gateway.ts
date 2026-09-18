import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { CallsService } from './calls.service';

@WebSocketGateway({ cors: { origin: '*' } })
export class CallsGateway {
  @WebSocketServer()
  server: Server;

  constructor(private readonly callsService: CallsService) {}

  @SubscribeMessage('call_join')
  async handleJoin(
    @MessageBody() data: { callId: string },
    @ConnectedSocket() client: Socket,
  ) {
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
    const room = `call_${data.callId}`;
    client.to(room).emit('call_signal', data.signal);
  }
}
