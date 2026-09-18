import { IsEnum, IsInt, IsOptional, IsString, IsUUID } from 'class-validator';
import { MessageType } from '@prisma/client';

export class SendMessageDto {
  @IsEnum(MessageType)
  type: MessageType;

  @IsString()
  @IsOptional()
  text?: string;

  @IsUUID()
  @IsOptional()
  mediaId?: string;

  @IsInt()
  @IsOptional()
  snapExpiresInSeconds?: number;
}
