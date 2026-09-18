import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { SwipesService } from './swipes.service';
import { SwipeDto } from './dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUserId } from '../auth/current-user';

@Controller('swipes')
@UseGuards(JwtAuthGuard)
export class SwipesController {
  constructor(private readonly swipesService: SwipesService) {}

  @Post('like')
  async like(
    @CurrentUserId() userId: string,
    @Body() dto: SwipeDto,
  ) {
    return this.swipesService.recordLike(userId, dto.targetUserId);
  }

  @Post('pass')
  async pass(
    @CurrentUserId() userId: string,
    @Body() dto: SwipeDto,
  ) {
    return this.swipesService.recordPass(userId, dto.targetUserId);
  }
}
