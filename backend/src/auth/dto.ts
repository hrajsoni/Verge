import { IsDateString, IsEmail, IsNotEmpty, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsString()
  displayName: string;

  @IsDateString()
  dateOfBirth: string;
}

export class LoginDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;
}

export class RequestOtpDto {
  @IsString()
  target: string;
}

export class VerifyOtpDto {
  @IsString()
  target: string;

  @IsString()
  code: string;

  @IsOptional()
  @IsString()
  displayName?: string;
}

export class GoogleAuthDto {
  @IsString()
  @IsNotEmpty()
  idToken: string;
}
