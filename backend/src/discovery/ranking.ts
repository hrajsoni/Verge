import { Gender, LookingFor } from '@prisma/client';

export type RankableProfile = {
  id: string;
  age: number;
  gender: Gender;
  lookingFor: LookingFor;
  distanceKm: number;
  sharedInterestCount: number;
  profileComplete: boolean;
  lastActiveHoursAgo: number;
  blocked: boolean;
  alreadySwiped: boolean;
  inactive: boolean;
};

export type DiscoveryFilters = {
  minAge: number;
  maxAge: number;
  maxDistanceKm: number;
  genders: Gender[];
  lookingFor: LookingFor[];
};

export function lookingForCompatible(
  seeker: LookingFor,
  candidate: LookingFor,
): boolean {
  if (seeker === LookingFor.FRIENDS_AND_DATING || candidate === LookingFor.FRIENDS_AND_DATING) {
    return true;
  }
  return seeker === candidate;
}

export function passesFilters(
  profile: RankableProfile,
  filters: DiscoveryFilters,
): boolean {
  if (profile.blocked || profile.alreadySwiped || profile.inactive) return false;
  if (profile.age < filters.minAge || profile.age > filters.maxAge) return false;
  if (profile.distanceKm > filters.maxDistanceKm) return false;
  if (filters.genders.length && !filters.genders.includes(profile.gender)) {
    return false;
  }
  if (
    filters.lookingFor.length &&
    !filters.lookingFor.some((want) => lookingForCompatible(want, profile.lookingFor))
  ) {
    return false;
  }
  return true;
}

export function rankScore(profile: RankableProfile): number {
  const distance = Math.max(0, 40 - profile.distanceKm);
  const interests = profile.sharedInterestCount * 8;
  const activity = Math.max(0, 24 - profile.lastActiveHoursAgo);
  const completeness = profile.profileComplete ? 10 : 0;
  return distance + interests + activity + completeness;
}

export function rankCandidates(
  profiles: RankableProfile[],
  filters: DiscoveryFilters,
): RankableProfile[] {
  return profiles
    .filter((profile) => passesFilters(profile, filters))
    .sort((a, b) => rankScore(b) - rankScore(a));
}
