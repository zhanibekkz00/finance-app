import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateSettingsDto } from './dto/update-settings.dto';

@Injectable()
export class SettingsService {
  constructor(private prisma: PrismaService) {}

  async getSettings(userId: string) {
    const settings = await this.prisma.userSettings.findUnique({
      where: { userId },
    });

    if (!settings) {
      throw new NotFoundException('Settings not found');
    }

    return {
      themeMode: settings.themeMode,
      locale: settings.locale,
      currencyCode: settings.currencyCode,
    };
  }

  async updateSettings(userId: string, dto: UpdateSettingsDto) {
    const settings = await this.prisma.userSettings.update({
      where: { userId },
      data: dto,
    });

    return {
      themeMode: settings.themeMode,
      locale: settings.locale,
      currencyCode: settings.currencyCode,
    };
  }
}
