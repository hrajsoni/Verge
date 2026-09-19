import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  RankableProfile,
  passesFilters,
  rankCandidates,
  DiscoveryFilters,
} from './ranking';
import { haversineKm, distanceLabel, yearsSince } from '../common/geo';

@Injectable()
export class DiscoveryService {
  constructor(private readonly prisma: PrismaService) {}

  async getFeed(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        preferences: true,
        location: true,
        interests: true,
        blocksSent: true,
        blocksReceived: true,
        likesSent: true,
        passesSent: true,
      },
    });

    if (!user || !user.location || !user.preferences) {
      throw new NotFoundException('User profile, location, or preferences missing');
    }

    const { latitude, longitude } = user.location;
    const { minAge, maxAge, maxDistanceKm, genders, lookingFor } = user.preferences;

    const filters: DiscoveryFilters = {
      minAge,
      maxAge,
      maxDistanceKm,
      genders,
      lookingFor,
    };

    const blockedIds = new Set([
      ...user.blocksSent.map((b) => b.blockedId),
      ...user.blocksReceived.map((b) => b.blockerId),
    ]);
    const swipedIds = new Set([
      ...user.likesSent.map((l) => l.toUserId),
      ...user.passesSent.map((p) => p.toUserId),
    ]);
    const userInterestIds = new Set(user.interests.map((i) => i.interestId));

    const candidates = await this.prisma.user.findMany({
      where: {
        id: { not: userId },
        status: 'ACTIVE',
        dateOfBirth: { not: null },
        profile: { isNot: null },
        location: { isNot: null },
      },
      include: {
        profile: true,
        location: true,
        interests: { include: { interest: true } },
        photos: {
          include: { media: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });

    const rankableProfiles: (RankableProfile & { raw: any })[] = candidates.map((candidate) => {
      const distanceKm = haversineKm(
        latitude,
        longitude,
        candidate.location!.latitude,
        candidate.location!.longitude,
      );
      const age = candidate.dateOfBirth ? yearsSince(candidate.dateOfBirth) : 20;
      const sharedInterestCount = candidate.interests.filter((i) =>
        userInterestIds.has(i.interestId),
      ).length;
      const lastActiveHoursAgo =
        (Date.now() - candidate.lastActiveAt.getTime()) / (1000 * 60 * 60);

      return {
        id: candidate.id,
        age,
        gender: candidate.profile!.gender,
        lookingFor: candidate.profile!.lookingFor,
        distanceKm,
        sharedInterestCount,
        profileComplete: candidate.photos.length > 0 && candidate.profile!.bio.length > 0,
        lastActiveHoursAgo,
        blocked: blockedIds.has(candidate.id),
        alreadySwiped: swipedIds.has(candidate.id),
        inactive: lastActiveHoursAgo > 24 * 7,
        raw: candidate,
      };
    });

    const ranked = rankCandidates(rankableProfiles, filters) as (RankableProfile & { raw: any })[];

    return ranked.map((r) => {
      const { raw, distanceKm, age } = r;
      return {
        id: raw.id,
        displayName: raw.profile.displayName,
        age,
        distanceLabel: distanceLabel(distanceKm),
        bio: raw.profile.bio,
        lookingFor: raw.profile.lookingFor,
        interests: raw.interests.map((i: any) => ({
          id: i.interest.id,
          label: i.interest.label,
          emoji: i.interest.emoji,
        })),
        photos: raw.photos.map((p: any) => ({
          id: p.id,
          url: p.media.objectKey, // Simplified, in real app might be signed URL
        })),
      };
    });
  }
}
