import { IsEnum, IsNumber, IsString, IsOptional, IsBoolean, IsDateString } from 'class-validator';
import { TransactionType, RecurrenceInterval } from '@prisma/client';

export class UpdateTransactionDto {
  @IsOptional()
  @IsEnum(TransactionType)
  type?: TransactionType;

  @IsOptional()
  @IsNumber()
  amount?: number;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsDateString()
  date?: string;

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
