import { IsEnum, IsNumber, IsString, IsOptional, IsBoolean, IsDateString } from 'class-validator';
import { TransactionType, RecurrenceInterval } from '@prisma/client';

export class CreateTransactionDto {
  @IsEnum(TransactionType)
  type: TransactionType;

  @IsNumber()
  amount: number;

  @IsString()
  currency: string;

  @IsString()
  categoryId: string;

  @IsDateString()
  date: string;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsBoolean()
  isRecurring?: boolean;

  @IsOptional()
  @IsEnum(RecurrenceInterval)
  recurrenceInterval?: RecurrenceInterval;

  @IsOptional()
  @IsDateString()
  nextOccurrence?: string;

  @IsOptional()
  @IsBoolean()
  isPinned?: boolean;

  @IsOptional()
  @IsString()
  groupId?: string;
}
