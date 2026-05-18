import { Controller, Get, Patch, Post, Body, Param, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('admin')
export class AdminController {
  constructor(private adminService: AdminService) {}

  @Get('dashboard')
  async getDashboard() {
    return this.adminService.getDashboardStats();
  }

  @Get('users')
  async getUsers() {
    return this.adminService.getUsers();
  }

  @Patch('users/:id/role')
  async updateUserRole(@Param('id') id: string, @Body() body: { role: string }) {
    return this.adminService.updateUserRole(id, body.role);
  }

  @Patch('users/:id/block')
  async toggleUserBlock(@Param('id') id: string, @Body() body: { isBlocked: boolean }) {
    return this.adminService.toggleUserBlock(id, body.isBlocked);
  }

  @Get('categories')
  async getGlobalCategories() {
    return this.adminService.getGlobalCategories();
  }

  @Post('categories')
  async addGlobalCategory(@Body() body: any) {
    return this.adminService.addGlobalCategory(body);
  }

  @Post('notifications')
  async sendNotification(@Body() body: { title: string, body: string }) {
    await this.adminService.sendNotification(body.title, body.body);
    return { success: true };
  }
}
