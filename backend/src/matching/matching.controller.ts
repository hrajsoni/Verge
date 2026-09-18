import { Controller, Get, UseGuards } from '@nestjs/common';
import { MatchingService } from './matching.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUserId } from '../auth/current-user';

@Controller('matches')
@UseGuards(JwtAuthGuard)
export class MatchingController {
  constructor(private readonly matchingService: MatchingService) {}

  @Get()
  async getMatches(@CurrentUserId() userId: string) {
    const matches = await this.matchingService.getMatches(userId);
    return { matches };
  }
}
