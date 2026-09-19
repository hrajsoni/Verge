import { isMutualLike, pairKey } from './match-logic';

describe('matching', () => {
  it('creates a stable pair key', () => {
    expect(pairKey('b', 'a')).toEqual(['a', 'b']);
    expect(pairKey('a', 'b')).toEqual(['a', 'b']);
  });

  it('detects mutual likes', () => {
    expect(isMutualLike([{ fromUserId: 'b', toUserId: 'a' }], 'a', 'b')).toBe(
      true,
    );
    expect(isMutualLike([], 'a', 'b')).toBe(false);
  });
});
