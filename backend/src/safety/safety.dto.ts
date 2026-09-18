import { IsEnum, IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';
import { ReportCategory } from '@prisma/client';

export class BlockUserDto {
  @IsNotEmpty()
  @IsUUID()
  targetUserId: string;
}

export class ReportUserDto {
  @IsNotEmpty()
  @IsUUID()
  targetUserId: string;

  @IsNotEmpty()
  @IsEnum(ReportCategory)
  category: ReportCategory;

  @IsOptional()
  @IsString()
  details?: string;
}
