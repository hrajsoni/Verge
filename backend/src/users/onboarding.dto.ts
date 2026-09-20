import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsEnum,
  IsArray,
  IsOptional,
  IsUUID,
  Min,
  Max,
  IsInt,
  IsNumber,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Type } from 'class-transformer';

export enum GenderDto {
  MALE = 'MALE',
  FEMALE = 'FEMALE',
  NON_BINARY = 'NON_BINARY',
  OTHER = 'OTHER',
}

export enum LookingForDto {
  FRIENDSHIP = 'FRIENDSHIP',
  DATING = 'DATING',
  BOTH = 'BOTH',
}

export class CompleteOnboardingDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(1)
  @MaxLength(50)
  displayName: string;

  @IsDateString()
  dateOfBirth: string; // ISO date string e.g. '1995-04-12'

  @IsEnum(GenderDto)
  gender: GenderDto;

  @IsEnum(LookingForDto)
  lookingFor: LookingForDto;

  @IsArray()
  @IsUUID('4', { each: true })
  @IsOptional()
  interestIds?: string[];

  @IsInt()
  @Min(18)
  @Max(100)
  @Type(() => Number)
  minAge: number;

  @IsInt()
  @Min(18)
  @Max(100)
  @Type(() => Number)
  maxAge: number;

  @IsInt()
  @Min(1)
  @Max(500)
  @Type(() => Number)
  maxDistanceKm: number;

  @IsArray()
  @IsEnum(GenderDto, { each: true })
  genders: GenderDto[];

  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  bio?: string;
}
