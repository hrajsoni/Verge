import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { SwipesService } from './swipes.service';
import { SwipeDto } from './dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUserId } from '../auth/current-user';
import { Throttle } from '@nestjs/throttler';

@Controller('swipes')
@UseGuards(JwtAuthGuard)
export class SwipesController {
  constructor(private readonly swipesService: SwipesService) {}

  @Throttle({ default: { ttl: 60000, limit: 100 } })
  @Post('like')
  async like(@CurrentUserId() userId: string, @Body() dto: SwipeDto) {
    return this.swipesService.recordLike(userId, dto.targetUserId);
  }

  @Throttle({ default: { ttl: 60000, limit: 100 } })
  @Post('pass')
  async pass(@CurrentUserId() userId: string, @Body() dto: SwipeDto) {
    return this.swipesService.recordPass(userId, dto.targetUserId);
  }
}
