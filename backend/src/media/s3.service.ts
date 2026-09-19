import { Injectable, Logger } from '@nestjs/common';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  HeadObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class S3Service {
  private readonly logger = new Logger(S3Service.name);
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor() {
    this.bucket = process.env.S3_BUCKET ?? 'be-snap-media';
    this.client = new S3Client({
      region: process.env.AWS_REGION ?? 'us-east-1',
      endpoint: process.env.S3_ENDPOINT, // for MinIO in dev
      forcePathStyle: !!process.env.S3_ENDPOINT, // needed for MinIO
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID ?? 'minioadmin',
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY ?? 'minioadmin',
      },
    });
  }

  async getUploadPresignedUrl(
    objectKey: string,
    mimeType: string,
    expiresInSeconds = 300,
  ): Promise<string> {
    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: objectKey,
      ContentType: mimeType,
    });
    return getSignedUrl(this.client, command, { expiresIn: expiresInSeconds });
  }

  async getDownloadPresignedUrl(
    objectKey: string,
    expiresInSeconds = 45,
  ): Promise<string> {
    // Use GetObjectCommand
    const { GetObjectCommand } = await import('@aws-sdk/client-s3');
    const command = new GetObjectCommand({
      Bucket: this.bucket,
      Key: objectKey,
    });
    return getSignedUrl(this.client, command, { expiresIn: expiresInSeconds });
  }

  async deleteObject(objectKey: string): Promise<void> {
    try {
      await this.client.send(
        new DeleteObjectCommand({ Bucket: this.bucket, Key: objectKey }),
      );
      this.logger.log(`Deleted S3 object: ${objectKey}`);
    } catch (err) {
      this.logger.error(`Failed to delete S3 object ${objectKey}`, err);
      throw err;
    }
  }

  async objectExists(objectKey: string): Promise<boolean> {
    try {
      await this.client.send(
        new HeadObjectCommand({ Bucket: this.bucket, Key: objectKey }),
      );
      return true;
    } catch {
      return false;
    }
  }

  getBucket(): string {
    return this.bucket;
  }
}
