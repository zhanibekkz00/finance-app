import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';

@Injectable()
export class CategoriesService {
  constructor(private prisma: PrismaService) {}

  async findAll(userId: string, includeDefault: boolean = true) {
    const where: any = {};

    if (includeDefault) {
      where.OR = [
        { userId },
        { isDefault: true },
      ];
    } else {
      where.userId = userId;
    }

    return this.prisma.category.findMany({
      where,
      orderBy: [{ isDefault: 'desc' }, { name: 'asc' }],
    });
  }

  async create(userId: string, dto: CreateCategoryDto) {
    return this.prisma.category.create({
      data: {
        ...dto,
        userId,
        isDefault: false,
      },
    });
  }

  async delete(userId: string, id: string) {
    // Check if category belongs to user
    const category = await this.prisma.category.findFirst({
      where: { id, userId },
    });

    if (!category) {
      throw new Error('Category not found or not owned by user');
    }

    return this.prisma.category.delete({
      where: { id },
    });
  }
}
