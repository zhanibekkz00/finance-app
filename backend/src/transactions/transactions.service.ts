import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';

@Injectable()
export class TransactionsService {
  constructor(private prisma: PrismaService) {}

  async findAll(
    userId: string,
    filters?: {
      from?: string;
      to?: string;
      type?: string;
      categoryId?: string;
    },
  ) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const where: any = {
      OR: [
        { userId },
        ...(user?.groupId ? [{ groupId: user.groupId }] : []),
      ],
    };

    if (filters?.from) {
      where.date = { ...where.date, gte: new Date(filters.from) };
    }

    if (filters?.to) {
      where.date = { ...where.date, lte: new Date(filters.to) };
    }

    if (filters?.type) {
      where.type = filters.type;
    }

    if (filters?.categoryId) {
      where.categoryId = filters.categoryId;
    }

    const transactions = await this.prisma.transaction.findMany({
      where,
      include: {
        category: true,
      },
      orderBy: [
        { isPinned: 'desc' },
        { date: 'desc' },
      ],
    });

    return transactions;
  }

  async findOne(userId: string, id: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const transaction = await this.prisma.transaction.findFirst({
      where: {
        id,
        OR: [
          { userId },
          ...(user?.groupId ? [{ groupId: user.groupId }] : []),
        ],
      },
      include: { category: true },
    });

    if (!transaction) {
      throw new NotFoundException('Transaction not found');
    }

    return transaction;
  }

  async create(userId: string, dto: CreateTransactionDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { groupId: true } });
    return this.prisma.transaction.create({
      data: {
        ...dto,
        userId,
        groupId: dto.groupId || user?.groupId,
        categoryId: (dto.categoryId && dto.categoryId !== '') ? dto.categoryId : null,
        date: new Date(dto.date),
        nextOccurrence: dto.nextOccurrence ? new Date(dto.nextOccurrence) : null,
        note: dto.note || '',
        isRecurring: dto.isRecurring || false,
        recurrenceInterval: dto.recurrenceInterval || 'none',
        isPinned: dto.isPinned || false,
      },
      include: { category: true },
    });
  }

  async update(userId: string, id: string, dto: UpdateTransactionDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const existing = await this.prisma.transaction.findFirst({
      where: {
        id,
        OR: [
          { userId },
          ...(user?.groupId ? [{ groupId: user.groupId }] : []),
        ],
      },
    });

    if (!existing) {
      throw new NotFoundException('Transaction not found');
    }

    const updateData: any = { ...dto };
    if (dto.date) {
      updateData.date = new Date(dto.date);
    }
    if (dto.nextOccurrence) {
      updateData.nextOccurrence = new Date(dto.nextOccurrence);
    }

    return this.prisma.transaction.update({
      where: { id },
      data: updateData,
      include: { category: true },
    });
  }

  async delete(userId: string, id: string) {
    const transaction = await this.prisma.transaction.findFirst({
      where: { id, userId },
    });

    if (!transaction) {
      throw new NotFoundException('Transaction not found');
    }

    return this.prisma.transaction.delete({
      where: { id },
    });
  }

  async togglePin(userId: string, id: string) {
    const transaction = await this.prisma.transaction.findFirst({
      where: { id, userId },
    });

    if (!transaction) {
      throw new NotFoundException('Transaction not found');
    }

    return this.prisma.transaction.update({
      where: { id },
      data: { isPinned: !transaction.isPinned },
      include: { category: true },
    });
  }

  async getCategoryStats(userId: string, categoryId: string, from?: string, to?: string) {
    const where: any = {
      userId,
      categoryId,
    };

    if (from) {
      where.date = { ...where.date, gte: new Date(from) };
    }

    if (to) {
      where.date = { ...where.date, lte: new Date(to) };
    }

    const transactions = await this.prisma.transaction.findMany({
      where,
    });

    if (transactions.length === 0) {
      return {
        totalSpent: 0,
        totalEarned: 0,
        count: 0,
        average: 0,
      };
    }

    let totalSpent = 0;
    let totalEarned = 0;

    transactions.forEach((tx) => {
      if (tx.type === 'expense') {
        totalSpent += Number(tx.amount);
      } else {
        totalEarned += Number(tx.amount);
      }
    });

    return {
      totalSpent,
      totalEarned,
      count: transactions.length,
      average: (totalSpent + totalEarned) / transactions.length,
    };
  }
}
