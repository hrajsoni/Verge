import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const interests = [
  { slug: 'music', label: 'Music', emoji: '🎵' },
  { slug: 'gaming', label: 'Gaming', emoji: '🎮' },
  { slug: 'fitness', label: 'Fitness', emoji: '🏋️' },
  { slug: 'photography', label: 'Photography', emoji: '📷' },
  { slug: 'technology', label: 'Technology', emoji: '💻' },
  { slug: 'movies', label: 'Movies', emoji: '🎬' },
  { slug: 'travel', label: 'Travel', emoji: '✈️' },
  { slug: 'sports', label: 'Sports', emoji: '⚽' },
  { slug: 'food', label: 'Food', emoji: '🍜' },
  { slug: 'reading', label: 'Reading', emoji: '📚' },
  { slug: 'art', label: 'Art', emoji: '🎨' },
  { slug: 'animals', label: 'Animals', emoji: '🐕' },
  { slug: 'nature', label: 'Nature', emoji: '🌱' },
  { slug: 'dance', label: 'Dance', emoji: '💃' },
  { slug: 'theatre', label: 'Theatre', emoji: '🎭' },
];

async function main() {
  for (const interest of interests) {
    await prisma.interest.upsert({
      where: { slug: interest.slug },
      update: {},
      create: interest,
    });
  }
  console.log(`Seeded ${interests.length} interests`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
