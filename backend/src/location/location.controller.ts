import { Controller, Patch, Body, UseGuards } from '@nestjs/common';
import { LocationService } from './location.service';
import { UpdateLocationDto } from './location.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUserId } from '../auth/current-user';

@Controller('location')
@UseGuards(JwtAuthGuard)
export class LocationController {
  constructor(private readonly locationService: LocationService) {}

  @Patch()
  async updateLocation(
    @CurrentUserId() userId: string,
    @Body() dto: UpdateLocationDto,
  ) {
    await this.locationService.updateLocation(userId, dto);
    return { success: true };
  }
}
