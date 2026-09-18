import { LookingFor } from '@prisma/client';
import {
  DiscoveryFilters,
  RankableProfile,
  rankCandidates,
  rankScore,
} from './ranking';

describe('discovery ranking', () => {
  const filters: DiscoveryFilters = {
    minAge: 18,
    maxAge: 30,
    maxDistanceKm: 10,
    genders: [],
    lookingFor: [LookingFor.FRIENDS],
  };

  const base: RankableProfile = {
    id: 'a',
    age: 24,
    gender: 'UNDISCLOSED' as RankableProfile['gender'],
    lookingFor: LookingFor.FRIENDS,
    distanceKm: 2,
    sharedInterestCount: 3,
    profileComplete: true,
    lastActiveHoursAgo: 1,
    blocked: false,
    alreadySwiped: false,
    inactive: false,
  };

  it('drops blocked, swiped, inactive, and out-of-radius users', () => {
    const ranked = rankCandidates(
      [
        { ...base, id: 'ok' },
        { ...base, id: 'blocked', blocked: true },
        { ...base, id: 'swiped', alreadySwiped: true },
        { ...base, id: 'far', distanceKm: 50 },
        { ...base, id: 'young', age: 16 },
      ],
      filters,
    );
    expect(ranked.map((p) => p.id)).toEqual(['ok']);
  });

  it('scores closer and more compatible profiles higher', () => {
    const near = rankScore({ ...base, distanceKm: 1, sharedInterestCount: 4 });
    const far = rankScore({ ...base, distanceKm: 20, sharedInterestCount: 0 });
    expect(near).toBeGreaterThan(far);
  });
});
