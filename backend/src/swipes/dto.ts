import { IsUUID } from 'class-validator';

export class SwipeDto {
  @IsUUID()
  targetUserId: string;
}
