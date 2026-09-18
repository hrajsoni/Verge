# Be-Snap

Nearby social discovery with swipe-to-match and camera-first private communication.

Be-Snap is **not** a Snapchat clone and **not** a BeFriend clone. The V1 loop is:

**Discover → Swipe → Match → Communicate** (text, photo, video, voice, Snap, 1:1 calls)

V1 is 18+. Exact GPS is never shown to other users.

## Repositories in this monorepo

| Path | Stack |
| --- | --- |
| `android/` | Kotlin, Jetpack Compose, Hilt, Coroutines |
| `backend/` | NestJS, PostgreSQL + PostGIS, Redis, Prisma |
| `docs/` | Camera Kit access, phase tracker |

## Quick start

### Backend

```bash
docker compose up -d
cd backend
cp .env.example .env
npm install
npx prisma migrate dev
npm run start:dev
```

API: `http://localhost:3000/v1/health`

### Android

Open `android/` in Android Studio. JDK 17+ is required. Set SDK in `local.properties`.

```bash
cd android
./gradlew assembleDebug
```

Discover is the default home tab.

## V1 out of scope

Stories, Spotlight, Snap Map, Memories, public comments, followers, livestreams, group calls, group matching.
