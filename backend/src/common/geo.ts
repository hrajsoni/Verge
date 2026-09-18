export function haversineKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export function distanceLabel(km: number): string {
  if (km < 1) return 'Nearby';
  if (km < 2) return '1 km away';
  if (km < 4) return '3 km away';
  if (km < 6) return '5 km away';
  return '10+ km away';
}

export function encodeGeohash(lat: number, lon: number): string {
  return `${lat.toFixed(2)}:${lon.toFixed(2)}`;
}

export function yearsSince(date: Date, now = new Date()): number {
  const diff = now.getTime() - date.getTime();
  return Math.floor(diff / (365.25 * 24 * 60 * 60 * 1000));
}
