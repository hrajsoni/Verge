import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { OnboardingService } from './onboarding.service';

@Module({
  controllers: [UsersController],
  providers: [UsersService, OnboardingService],
  exports: [UsersService],
})
export class UsersModule {}
