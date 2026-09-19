import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { ProfilesModule } from './profiles/profiles.module';
import { InterestsModule } from './interests/interests.module';
import { HealthModule } from './health/health.module';
import { LocationModule } from './location/location.module';
import { DiscoveryModule } from './discovery/discovery.module';
import { SwipesModule } from './swipes/swipes.module';
import { MatchingModule } from './matching/matching.module';

import { MediaModule } from './media/media.module';
import { ChatModule } from './chat/chat.module';
import { CallsModule } from './calls/calls.module';
import { SafetyModule } from './safety/safety.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 60 }]),
    PrismaModule,
    AuthModule,
    UsersModule,
    ProfilesModule,
    InterestsModule,
    HealthModule,
    LocationModule,
    DiscoveryModule,
    SwipesModule,
    MatchingModule,
    MediaModule,
    ChatModule,
    CallsModule,
    SafetyModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
