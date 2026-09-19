import { Module } from '@nestjs/common';
import { ChatGateway } from './chat.gateway';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { SnapService } from './snap.service';
import { SnapCleanupService } from './snap-cleanup.service';
import { MediaModule } from '../media/media.module';

@Module({
  imports: [PrismaModule, AuthModule, MediaModule],
  providers: [ChatGateway, ChatService, SnapService, SnapCleanupService],
  controllers: [ChatController],
  exports: [ChatGateway, ChatService, SnapService],
})
export class ChatModule {}
