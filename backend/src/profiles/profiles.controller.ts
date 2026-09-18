import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { CurrentUserId } from '../auth/current-user';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UpdateProfileDto } from './dto';
import { ProfilesService } from './profiles.service';

@Controller('profiles')
@UseGuards(JwtAuthGuard)
export class ProfilesController {
  constructor(private readonly profiles: ProfilesService) {}

  @Get('me')
  me(@CurrentUserId() userId: string) {
    return this.profiles.get(userId);
  }

  @Patch('me')
  update(@CurrentUserId() userId: string, @Body() dto: UpdateProfileDto) {
    return this.profiles.update(userId, dto);
  }
}
