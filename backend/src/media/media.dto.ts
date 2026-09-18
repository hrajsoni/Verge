import { IsEnum, IsInt, IsNotEmpty, IsString } from 'class-validator';
import { MediaType } from '@prisma/client';

export class GetUploadUrlDto {
  @IsEnum(MediaType)
  @IsNotEmpty()
  type: MediaType;

  @IsString()
  @IsNotEmpty()
  mimeType: string;

  @IsInt()
  @IsNotEmpty()
  sizeBytes: number;
}
