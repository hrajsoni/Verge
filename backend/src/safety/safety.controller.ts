import { Controller, Post, Delete, Get, Body, Param, UseGuards } from '@nestjs/common';
import { SafetyService } from './safety.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUserId } from '../auth/current-user';
import { BlockUserDto, ReportUserDto } from './safety.dto';

@Controller('safety')
@UseGuards(JwtAuthGuard)
export class SafetyController {
  constructor(private readonly safetyService: SafetyService) {}

  @Post('blocks')
  blockUser(@CurrentUserId() userId: string, @Body() dto: BlockUserDto) {
    return this.safetyService.blockUser(userId, dto.targetUserId);
  }

  @Delete('blocks/:targetUserId')
  unblockUser(@CurrentUserId() userId: string, @Param('targetUserId') targetUserId: string) {
    return this.safetyService.unblockUser(userId, targetUserId);
  }

  @Get('blocks')
  getBlockedUsers(@CurrentUserId() userId: string) {
    return this.safetyService.getBlockedUsers(userId);
  }

  @Post('reports')
  reportUser(@CurrentUserId() userId: string, @Body() dto: ReportUserDto) {
    return this.safetyService.reportUser(userId, dto);
  }

  @Delete('account')
  deleteAccount(@CurrentUserId() userId: string) {
    return this.safetyService.deleteAccount(userId);
  }
}
