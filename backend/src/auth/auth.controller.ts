import { Body, Controller, Post, Req } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto, RegisterDto, RequestOtpDto, VerifyOtpDto } from './dto';
import { Throttle } from '@nestjs/throttler';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Post('otp/request')
  requestOtp(@Body() dto: RequestOtpDto) {
    return this.auth.requestOtp(dto);
  }

  @Post('otp/verify')
  verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.auth.verifyOtp(dto);
  }

  @Throttle({ default: { ttl: 60000, limit: 5 } })
  @Post('google')
  googleLogin(@Body() dto: import('./dto').GoogleAuthDto, @Req() req: any) {
    const ip =
      req.ip || req.headers?.['x-forwarded-for']?.toString() || '127.0.0.1';
    const userAgent = req.headers?.['user-agent'];
    return this.auth.googleLogin(dto, ip, userAgent);
  }
}
