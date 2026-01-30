import { IsString, IsInt, IsNumber } from 'class-validator';

export class CreateCategoryDto {
  @IsString()
  name: string;

  @IsNumber()
  colorValue: number;

  @IsInt()
  iconCode: number;
}
