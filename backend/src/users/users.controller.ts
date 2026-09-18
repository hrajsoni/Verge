import { Controller, Get, UseGuards } from '@nestjs/common';
import { CurrentUserId } from '../auth/current-user';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  me(@CurrentUserId() userId: string) {
    return this.users.me(userId);
  }
}
