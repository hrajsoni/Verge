import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { S3Service } from '../media/s3.service';
import { SnapViewState } from '@prisma/client';

@Injectable()
export class SnapCleanupService implements OnModuleInit {
  private readonly logger = new Logger(SnapCleanupService.name);
  private intervalHandle: ReturnType<typeof setInterval> | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3Service,
  ) {}

  onModuleInit() {
    // Run cleanup every 5 minutes
    this.intervalHandle = setInterval(
      () => void this.runCleanup(),
      5 * 60 * 1000,
    );
    // Also run once on startup after 10 seconds
    setTimeout(() => void this.runCleanup(), 10_000);
  }

  async runCleanup(): Promise<void> {
    this.logger.log('Running Snap cleanup...');

    // Find expired snaps:
    // 1. Snaps in EXPIRED state whose media has not been deleted yet
    // 2. Snaps in any non-terminal state that are older than 24 hours (unopened expiry)
    const cutoff24h = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const toDelete = await this.prisma.message.findMany({
      where: {
        snapViewDuration: { not: null }, // only snap messages
        media: {
          is: {
            deletedAt: null,
          },
        },
        OR: [
          { snapViewState: SnapViewState.EXPIRED },
          { snapViewState: SnapViewState.REPLAYED },
          {
            snapViewState: {
              notIn: [SnapViewState.EXPIRED, SnapViewState.REPLAYED],
            },
            createdAt: { lt: cutoff24h },
          },
        ],
      },
      include: { media: true },
    });

    let deleted = 0;
    let failed = 0;

    for (const msg of toDelete) {
      const message = msg as any;
      if (!message.media) continue;
      try {
        await this.s3.deleteObject(message.media.objectKey);
        // Mark media as deleted
        await this.prisma.mediaAsset.update({
          where: { id: message.media.id },
          data: { deletedAt: new Date() },
        });
        // Ensure message state is EXPIRED
        if (
          message.snapViewState !== SnapViewState.EXPIRED &&
          message.snapViewState !== SnapViewState.REPLAYED
        ) {
          await this.prisma.message.update({
            where: { id: message.id },
            data: { snapViewState: SnapViewState.EXPIRED },
          });
        }
        deleted++;
      } catch (err) {
        this.logger.error(
          `Failed to delete snap media for message ${message.id}`,
          err,
        );
        failed++;
      }
    }

    this.logger.log(
      `Snap cleanup complete: ${deleted} deleted, ${failed} failed.`,
    );
  }
}
