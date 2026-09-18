import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto';

@Injectable()
export class ProfilesService {
  constructor(private readonly prisma: PrismaService) {}

  get(userId: string) {
    return this.prisma.profile.findUnique({ where: { userId } });
  }

  update(userId: string, dto: UpdateProfileDto) {
    return this.prisma.profile.update({
      where: { userId },
      data: dto,
    });
  }
}
