import { Controller, Post, Body, Param, Get, UseGuards } from '@nestjs/common';
import { CallsService } from './calls.service';
import { InitiateCallDto } from './calls.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUserId } from '../auth/current-user';

@UseGuards(JwtAuthGuard)
@Controller('calls')
export class CallsController {
  constructor(private readonly callsService: CallsService) {}

  @Post('initiate')
  async initiateCall(
    @CurrentUserId() userId: string,
    @Body() dto: InitiateCallDto,
  ) {
    return this.callsService.initiateCall(userId, dto);
  }

  @Post(':id/accept')
  async acceptCall(
    @CurrentUserId() userId: string,
    @Param('id') callId: string,
  ) {
    return this.callsService.acceptCall(userId, callId);
  }

  @Post(':id/reject')
  async rejectCall(
    @CurrentUserId() userId: string,
    @Param('id') callId: string,
  ) {
    return this.callsService.rejectCall(userId, callId);
  }

  @Post(':id/end')
  async endCall(
    @CurrentUserId() userId: string,
    @Param('id') callId: string,
  ) {
    return this.callsService.endCall(userId, callId);
  }

  @Get('ice-servers')
  async getIceServers() {
    return this.callsService.getIceServers();
  }
}
