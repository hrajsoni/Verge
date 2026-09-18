import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GetUploadUrlDto } from './media.dto';

@Injectable()
export class MediaService {
  constructor(private readonly prisma: PrismaService) {}

  async getUploadUrl(userId: string, dto: GetUploadUrlDto) {
    const objectKey = `${dto.type.toLowerCase()}s/${userId}/${Date.now()}-${Math.random().toString(36).substring(7)}`;
    
    // Create MediaAsset record
    const media = await this.prisma.mediaAsset.create({
      data: {
        ownerId: userId,
        type: dto.type,
        objectKey,
        mimeType: dto.mimeType,
        sizeBytes: dto.sizeBytes,
      },
    });

    // Generate mock presigned URL for MinIO
    // In a real app, you would use AWS SDK S3Client with getSignedUrl
    const uploadUrl = `http://localhost:9000/be-snap-media/${objectKey}?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=mock_credential&X-Amz-Signature=mock_signature`;

    return {
      mediaId: media.id,
      uploadUrl,
      objectKey,
    };
  }
}
