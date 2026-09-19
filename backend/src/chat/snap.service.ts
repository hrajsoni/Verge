import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { S3Service } from '../media/s3.service';
import { SnapViewState } from '@prisma/client';

@Injectable()
export class SnapService {
  private readonly logger = new Logger(SnapService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3Service,
  ) {}

  /**
   * Called when sender creates a snap message.
   * Returns a short-lived presigned download URL for the recipient.
   */
  async openSnap(
    messageId: string,
    userId: string,
  ): Promise<{ viewUrl: string; durationSeconds: number; canReplay: boolean }> {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
      include: { media: true, conversation: { include: { members: true } } },
    });

    if (!message) throw new NotFoundException('Snap not found');
    if (!message.media) throw new BadRequestException('Snap has no media');

    // Verify recipient is a member of the conversation
    const isMember = message.conversation.members.some(
      (m) => m.userId === userId,
    );
    if (!isMember)
      throw new ForbiddenException('Not a member of this conversation');

    // Sender cannot "open" their own snap (they already have the media)
    if (message.senderId === userId)
      throw new ForbiddenException('Sender cannot open own snap');

    const currentState = message.snapViewState as SnapViewState;

    if (currentState === SnapViewState.EXPIRED) {
      throw new BadRequestException('This Snap has expired');
    }
    if (currentState === SnapViewState.REPLAYED) {
      throw new BadRequestException('This Snap has already been replayed');
    }

    // Determine if this is a replay
    const isReplay = currentState === SnapViewState.REPLAY_AVAILABLE;

    if (isReplay && !message.snapReplayUsedAt) {
      // Mark replay used
      await this.prisma.message.update({
        where: { id: messageId },
        data: {
          snapViewState: SnapViewState.REPLAYED,
          snapViewCount: { increment: 1 },
          snapReplayUsedAt: new Date(),
        },
      });
    } else if (!isReplay) {
      // First open
      const nowState =
        currentState === SnapViewState.CREATED ||
        currentState === SnapViewState.DELIVERED
          ? SnapViewState.OPENED
          : currentState;

      const snapMaxViews = message.snapMaxViews ?? 1;
      const nextState =
        snapMaxViews > 1
          ? SnapViewState.REPLAY_AVAILABLE
          : SnapViewState.OPENED;

      await this.prisma.message.update({
        where: { id: messageId },
        data: {
          snapViewState: nextState,
          snapViewCount: { increment: 1 },
          snapOpenedAt: message.snapOpenedAt ?? new Date(),
        },
      });
    }

    // Generate short-lived signed URL (45 seconds — just enough to view)
    const viewUrl = await this.s3.getDownloadPresignedUrl(
      message.media.objectKey,
      45,
    );

    const durationSeconds = message.snapViewDuration ?? 5;
    const canReplay =
      (message.snapMaxViews ?? 1) > 1 && !message.snapReplayUsedAt;

    return { viewUrl, durationSeconds, canReplay };
  }

  /**
   * Called after the client-side viewing timer ends.
   * Marks the snap as expired if no replay is pending.
   */
  async markSnapViewed(messageId: string, userId: string): Promise<void> {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
      include: { conversation: { include: { members: true } } },
    });

    if (!message) throw new NotFoundException('Snap not found');

    const isMember = message.conversation.members.some(
      (m) => m.userId === userId,
    );
    if (!isMember) throw new ForbiddenException();

    const currentState = message.snapViewState as SnapViewState;

    if (
      currentState === SnapViewState.OPENED ||
      currentState === SnapViewState.REPLAYED
    ) {
      await this.prisma.message.update({
        where: { id: messageId },
        data: { snapViewState: SnapViewState.EXPIRED },
      });
      this.logger.log(`Snap ${messageId} marked EXPIRED after viewing`);
    }
  }
}
