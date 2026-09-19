import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { S3Service } from './s3.service';
import { GetUploadUrlDto } from './media.dto';

@Injectable()
export class MediaService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3Service,
  ) {}

  async getUploadUrl(userId: string, dto: GetUploadUrlDto) {
    const ext = dto.mimeType.split('/')[1] ?? 'bin';
    const objectKey = `${dto.type.toLowerCase()}s/${userId}/${Date.now()}-${Math.random().toString(36).substring(7)}.${ext}`;

    const media = await this.prisma.mediaAsset.create({
      data: {
        ownerId: userId,
        type: dto.type,
        objectKey,
        mimeType: dto.mimeType,
        sizeBytes: dto.sizeBytes,
      },
    });

    const uploadUrl = await this.s3.getUploadPresignedUrl(
      objectKey,
      dto.mimeType,
    );

    return {
      mediaId: media.id,
      uploadUrl,
      objectKey,
    };
  }

  async getDownloadUrl(objectKey: string): Promise<string> {
    return this.s3.getDownloadPresignedUrl(objectKey);
  }
}
