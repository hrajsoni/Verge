import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { MediaService } from './media.service';
import { GetUploadUrlDto } from './media.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUserId } from '../auth/current-user';

@Controller('media')
@UseGuards(JwtAuthGuard)
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post('upload-url')
  async getUploadUrl(
    @CurrentUserId() userId: string,
    @Body() dto: GetUploadUrlDto,
  ) {
    return this.mediaService.getUploadUrl(userId, dto);
  }
}
