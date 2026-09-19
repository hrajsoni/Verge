import {
  BadRequestException,
  ForbiddenException,
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
    return {
      sent: true,
      devCode: process.env.NODE_ENV === 'production' ? undefined : code,
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const challenge = await this.prisma.authChallenge.findFirst({
      where: {
        target: dto.target,
        consumed: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });
    if (!challenge) throw new UnauthorizedException();
    const ok = await bcrypt.compare(dto.code, challenge.codeHash);
    if (!ok) throw new UnauthorizedException();
    await this.prisma.authChallenge.update({
      where: { id: challenge.id },
      data: { consumed: true },
    });

    const email = dto.target.includes('@')
      ? dto.target.toLowerCase()
      : undefined;
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

  async googleLogin(
    dto: import('./dto').GoogleAuthDto,
    ipAddress: string,
    userAgent?: string,
  ) {
    const { OAuth2Client } = await import('google-auth-library');
    const clientId = process.env.GOOGLE_CLIENT_ID;
    const client = new OAuth2Client(clientId);

    let payload: any;
    try {
      const ticket = await client.verifyIdToken({
        idToken: dto.idToken,
        audience: clientId,
      });
      payload = ticket.getPayload();
    } catch {
      // In development / test environment, allow mock Google ID tokens
      if (
        process.env.NODE_ENV !== 'production' &&
        dto.idToken.startsWith('mock-google-token:')
      ) {
        const sub = dto.idToken.split(':')[1] || 'mock-sub-123';
        payload = {
          sub,
          email: `${sub}@example.com`,
          name: `User ${sub}`,
        };
      } else {
        throw new UnauthorizedException('Invalid Google ID token');
      }
    }

    if (!payload?.sub) {
      throw new UnauthorizedException('Google ID token missing subject claim');
    }

    const googleSub = payload.sub;
    const email = payload.email?.toLowerCase();
    const displayName = payload.name ?? 'User';

    let user = await this.prisma.user.findUnique({
      where: { googleSub },
      include: { profile: true },
    });

    if (!user && email) {
      user = await this.prisma.user.findUnique({
        where: { email },
        include: { profile: true },
      });
      if (user) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: { googleSub },
          include: { profile: true },
        });
      }
    }

    const existingUser = user;
    if (existingUser) {
      if (existingUser.status === 'BANNED') {
        throw new ForbiddenException({
          code: 'ACCOUNT_BANNED',
          message: 'This account has been permanently banned.',
          reason: existingUser.banReason,
        });
      }
      if (existingUser.status === 'SUSPENDED') {
        throw new ForbiddenException({
          code: 'ACCOUNT_SUSPENDED',
          message: 'This account is temporarily suspended.',
        });
      }
      if (existingUser.status === 'DELETED') {
        throw new ForbiddenException({
          code: 'ACCOUNT_DELETED',
          message: 'This account has been deleted.',
        });
      }

      await this.prisma.userLoginEvent.create({
        data: {
          userId: existingUser.id,
          ipAddress,
          userAgent,
        },
      });

      const token = await this.tokenFor(existingUser.id);
      return {
        ...token,
        isNewUser: false,
        onboardingDone: existingUser.onboardingDone,
        user: {
          id: existingUser.id,
          email: existingUser.email,
          displayName: existingUser.profile?.displayName ?? displayName,
          status: existingUser.status,
        },
      };
    }

    const newUser = await this.prisma.user.create({
      data: {
        googleSub,
        email,
        status: 'ACTIVE',
        profile: {
          create: {
            displayName,
          },
        },
        preferences: {
          create: {},
        },
      },
      include: { profile: true },
    });

    await this.prisma.userLoginEvent.create({
      data: {
        userId: newUser.id,
        ipAddress,
        userAgent,
      },
    });

    const token = await this.tokenFor(newUser.id);
    return {
      ...token,
      isNewUser: true,
      onboardingDone: false,
      user: {
        id: newUser.id,
        email: newUser.email,
        displayName,
        status: newUser.status,
      },
    };
  }

  private async tokenFor(userId: string) {
    const accessToken = await this.jwt.signAsync({ sub: userId });
    return { accessToken };
  }
}
