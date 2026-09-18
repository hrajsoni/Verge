import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { Gender, LookingFor } from '@prisma/client';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(40)
  displayName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(280)
  bio?: string;

  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @IsOptional()
  @IsEnum(LookingFor)
  lookingFor?: LookingFor;
}
