import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CurrentUserId } from '../auth/current-user';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UsersService } from './users.service';
import { OnboardingService } from './onboarding.service';
import { CompleteOnboardingDto } from './onboarding.dto';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(
    private readonly users: UsersService,
    private readonly onboarding: OnboardingService,
  ) {}

  @Get('me')
  me(@CurrentUserId() userId: string) {
    return this.users.me(userId);
  }

  @Post('me/onboarding')
  completeOnboarding(
    @CurrentUserId() userId: string,
    @Body() dto: CompleteOnboardingDto,
  ) {
    return this.onboarding.completeOnboarding(userId, dto);
  }
}
