import { IsOptional, IsEnum, IsString } from 'class-validator';
import { ThemeMode, Locale } from '@prisma/client';

export class UpdateSettingsDto {
  @IsOptional()
  @IsEnum(ThemeMode)
  themeMode?: ThemeMode;

  @IsOptional()
  @IsEnum(Locale)
  locale?: Locale;

  @IsOptional()
  @IsString()
  currencyCode?: string;
}
