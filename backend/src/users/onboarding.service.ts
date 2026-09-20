import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CompleteOnboardingDto } from './onboarding.dto';
import { yearsSince, encodeGeohash } from '../common/geo';

@Injectable()
export class OnboardingService {
  constructor(private readonly prisma: PrismaService) {}

  async completeOnboarding(userId: string, dto: CompleteOnboardingDto) {
    const dob = new Date(dto.dateOfBirth);
    if (yearsSince(dob) < 18) {
      throw new BadRequestException('Be-Snap is 18+');
    }

    await this.prisma.$transaction(async (tx) => {
      // 1. Update user core fields
      await tx.user.update({
        where: { id: userId },
        data: {
          dateOfBirth: dob,
          onboardingDone: true,
        },
      });

      // 2. Upsert profile
      await tx.profile.upsert({
        where: { userId },
        update: {
          displayName: dto.displayName,
          gender: dto.gender as any,
          lookingFor: dto.lookingFor as any,
          bio: dto.bio ?? '',
        },
        create: {
          userId,
          displayName: dto.displayName,
          gender: dto.gender as any,
          lookingFor: dto.lookingFor as any,
          bio: dto.bio ?? '',
        },
      });

      // 3. Upsert preferences
      await tx.discoveryPreference.upsert({
        where: { userId },
        update: {
          minAge: dto.minAge,
          maxAge: dto.maxAge,
          maxDistanceKm: dto.maxDistanceKm,
          genders: dto.genders as any[],
          lookingFor: [dto.lookingFor as any], // assuming array since enum says LookingFor[]
        },
        create: {
          userId,
          minAge: dto.minAge,
          maxAge: dto.maxAge,
          maxDistanceKm: dto.maxDistanceKm,
          genders: dto.genders as any[],
          lookingFor: [dto.lookingFor as any],
        },
      });

      // 4. Replace interests
      if (dto.interestIds && dto.interestIds.length > 0) {
        await tx.userInterest.deleteMany({ where: { userId } });
        await tx.userInterest.createMany({
          data: dto.interestIds.map((interestId) => ({ userId, interestId })),
          skipDuplicates: true,
        });
      }

      // 5. Upsert location
      await tx.userLocation.upsert({
        where: { userId },
        update: {
          latitude: dto.latitude,
          longitude: dto.longitude,
          geohash: encodeGeohash(dto.latitude, dto.longitude),
          updatedAt: new Date(),
        },
        create: {
          userId,
          latitude: dto.latitude,
          longitude: dto.longitude,
          geohash: encodeGeohash(dto.latitude, dto.longitude),
        },
      });
    });

    return { success: true };
  }
}
