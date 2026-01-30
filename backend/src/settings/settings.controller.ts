import { Controller, Get, Put, Body, UseGuards, Request } from '@nestjs/common';
import { SettingsService } from './settings.service';
import { UpdateSettingsDto } from './dto/update-settings.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('settings')
@UseGuards(JwtAuthGuard)
export class SettingsController {
  constructor(private settingsService: SettingsService) {}

  @Get()
  async getSettings(@Request() req) {
    return this.settingsService.getSettings(req.user.userId);
  }

  @Put()
  async updateSettings(@Request() req, @Body() dto: UpdateSettingsDto) {
    return this.settingsService.updateSettings(req.user.userId, dto);
  }
}
