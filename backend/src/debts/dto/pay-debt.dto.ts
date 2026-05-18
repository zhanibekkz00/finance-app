import { IsNumber, IsPositive } from 'class-validator';

export class PayDebtDto {
  @IsNumber()
  @IsPositive()
  amount: number;
}
