import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class InterestsService {
  constructor(private readonly prisma: PrismaService) {}

  list() {
    return this.prisma.interest.findMany({ orderBy: { label: 'asc' } });
  }

  setForUser(userId: string, interestIds: string[]) {
    return this.prisma.$transaction([
      this.prisma.userInterest.deleteMany({ where: { userId } }),
      this.prisma.userInterest.createMany({
        data: interestIds.map((interestId) => ({ userId, interestId })),
      }),
    ]);
  }
}
