import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  async getDashboardStats() {
    const totalUsers = await this.prisma.user.count();

    const aggregations = await this.prisma.transaction.aggregate({
      _sum: { amount: true },
    });
    const totalTransactionVolume = aggregations._sum.amount ? Number(aggregations._sum.amount) : 0;

    const newUsersPerDay = [];
    for (let i = 6; i >= 0; i--) {
      const gte = new Date();
      gte.setDate(gte.getDate() - i);
      gte.setHours(0, 0, 0, 0);

      const lt = new Date(gte);
      lt.setDate(lt.getDate() + 1);

      const count = await this.prisma.user.count({
        where: { createdAt: { gte, lt } },
      });
      newUsersPerDay.push(count);
    }

    const categoriesByVolume = await this.prisma.transaction.groupBy({
      by: ['categoryId'],
      where: { type: 'expense', categoryId: { not: null } },
      _sum: { amount: true },
      orderBy: { _sum: { amount: 'desc' } },
      take: 5,
    });

    const popularCategoriesObj: Record<string, number> = {};
    for (const cat of categoriesByVolume) {
      if (cat.categoryId) {
        const c = await this.prisma.category.findUnique({ where: { id: cat.categoryId } });
        popularCategoriesObj[c?.name || 'Unknown'] = Number(cat._sum.amount || 0);
      }
    }
    
    // Format required by Flutter AdminStats model
    const popularCategories = Object.entries(popularCategoriesObj).map(([key, value]) => ({ key, value }));

    return {
      totalUsers,
      totalTransactionVolume,
      newUsersPerDay,
      popularCategories,
    };
  }

  async getUsers() {
    return this.prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        role: true,
        isBlocked: true,
        createdAt: true,
        group: {
          select: { name: true }
        }
      },
    });
  }

  async updateUserRole(id: string, role: string) {
    return this.prisma.user.update({
      where: { id },
      data: { role },
    });
  }

  async toggleUserBlock(id: string, isBlocked: boolean) {
    return this.prisma.user.update({
      where: { id },
      data: { isBlocked },
    });
  }

  async addGlobalCategory(data: any) {
    return this.prisma.category.create({
      data: {
        name: data.name,
        colorValue: data.colorValue,
        iconCode: data.iconCode,
        isDefault: data.isDefault,
        userId: null,
      },
    });
  }

  async getGlobalCategories() {
    return this.prisma.category.findMany({
      where: { userId: null },
      orderBy: { createdAt: 'desc' },
    });
  }

  async sendNotification(title: string, body: string) {
    return this.prisma.notification.create({
      data: {
        title,
        body,
        target: 'all',
      },
    });
  }
}
