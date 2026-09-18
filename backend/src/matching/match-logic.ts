export function pairKey(userAId: string, userBId: string): [string, string] {
  return userAId < userBId ? [userAId, userBId] : [userBId, userAId];
}

export function isMutualLike(
  likes: Array<{ fromUserId: string; toUserId: string }>,
  fromUserId: string,
  toUserId: string,
): boolean {
  return likes.some(
    (like) => like.fromUserId === toUserId && like.toUserId === fromUserId,
  );
}
