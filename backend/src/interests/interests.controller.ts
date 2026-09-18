import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { IsArray, IsUUID } from 'class-validator';
import { CurrentUserId } from '../auth/current-user';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { InterestsService } from './interests.service';

class SetInterestsDto {
  @IsArray()
  @IsUUID('4', { each: true })
  interestIds: string[];
}

@Controller('interests')
export class InterestsController {
  constructor(private readonly interests: InterestsService) {}

  @Get()
  list() {
    return this.interests.list();
  }

  @Put('me')
  @UseGuards(JwtAuthGuard)
  setMine(@CurrentUserId() userId: string, @Body() dto: SetInterestsDto) {
    return this.interests.setForUser(userId, dto.interestIds);
  }
}
