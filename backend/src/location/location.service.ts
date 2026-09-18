import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateLocationDto } from './location.dto';
import { encodeGeohash } from '../common/geo';

@Injectable()
export class LocationService {
  constructor(private readonly prisma: PrismaService) {}

  async updateLocation(userId: string, dto: UpdateLocationDto) {
    const geohash = encodeGeohash(dto.latitude, dto.longitude);
    return this.prisma.userLocation.upsert({
      where: { userId },
      update: {
        latitude: dto.latitude,
        longitude: dto.longitude,
        geohash,
      },
      create: {
        userId,
        latitude: dto.latitude,
        longitude: dto.longitude,
        geohash,
      },
    });
  }
}
