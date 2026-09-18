import { IsEnum, IsNotEmpty, IsUUID } from 'class-validator';
import { CallKind } from '@prisma/client';

export class InitiateCallDto {
  @IsNotEmpty()
  @IsUUID()
  conversationId: string;

  @IsNotEmpty()
  @IsEnum(CallKind)
  kind: CallKind;
}
