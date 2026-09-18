import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { yearsSince } from '../common/geo';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto, RegisterDto, RequestOtpDto, VerifyOtpDto } from './dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const dob = new Date(dto.dateOfBirth);
    if (yearsSince(dob) < 18) {
      throw new BadRequestException('Be-Snap is 18+');
    }
    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase(),
        passwordHash,
        dateOfBirth: dob,
        profile: {
          create: { displayName: dto.displayName },
        },
        preferences: { create: {} },
      },
    });
    return this.tokenFor(user.id);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });
    if (!user?.passwordHash) throw new UnauthorizedException();
    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) throw new UnauthorizedException();
    return this.tokenFor(user.id);
  }

  async requestOtp(dto: RequestOtpDto) {
    const code = '123456';
    const codeHash = await bcrypt.hash(code, 10);
    await this.prisma.authChallenge.create({
      data: {
        target: dto.target,
        codeHash,
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      },
    });
    return { sent: true, devCode: process.env.NODE_ENV === 'production' ? undefined : code };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const challenge = await this.prisma.authChallenge.findFirst({
      where: { target: dto.target, consumed: false, expiresAt: { gt: new Date() } },
      orderBy: { createdAt: 'desc' },
    });
    if (!challenge) throw new UnauthorizedException();
    const ok = await bcrypt.compare(dto.code, challenge.codeHash);
    if (!ok) throw new UnauthorizedException();
    await this.prisma.authChallenge.update({
      where: { id: challenge.id },
      data: { consumed: true },
    });

    const email = dto.target.includes('@') ? dto.target.toLowerCase() : undefined;
    const phone = email ? undefined : dto.target;
    let user = email
      ? await this.prisma.user.findUnique({ where: { email } })
      : await this.prisma.user.findUnique({ where: { phone } });
    if (!user) {
      user = await this.prisma.user.create({
        data: {
          email,
          phone,
          dateOfBirth: new Date('2000-01-01'),
          profile: {
            create: { displayName: dto.displayName ?? 'New user' },
          },
          preferences: { create: {} },
        },
      });
    }
    return this.tokenFor(user.id);
  }

  private async tokenFor(userId: string) {
    const accessToken = await this.jwt.signAsync({ sub: userId });
    return { accessToken };
  }
}
