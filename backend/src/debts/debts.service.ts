import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { TransactionsService } from '../transactions/transactions.service';
import { CreateDebtDto } from './dto/create-debt.dto';
import { PayDebtDto } from './dto/pay-debt.dto';

@Injectable()
export class DebtsService {
  constructor(
    private prisma: PrismaService,
    private transactionsService: TransactionsService,
  ) {}

  async findAll(userId: string) {
    return this.prisma.debt.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(userId: string, dto: CreateDebtDto) {
    const debt = await this.prisma.debt.create({
      data: {
        userId,
        type: dto.type,
        creditorName: dto.creditorName,
        totalAmount: dto.amount,
        remainingAmount: dto.amount,
      },
    });

    const user = await this.prisma.user.findUnique({ where: { id: userId } });

    await this.prisma.transaction.create({
      data: {
        userId,
        groupId: user?.groupId,
        type: 'income',
        amount: dto.amount,
        date: new Date(),
        currency: 'USD',
        isRecurring: false,
        recurrenceInterval: 'none',
        isPinned: false,
        note: `Долг / кредит от: ${dto.creditorName} (${dto.type})`,
      }
    });

    return debt;
  }

  async pay(userId: string, id: string, dto: PayDebtDto) {
    const debt = await this.prisma.debt.findFirst({
      where: { id, userId },
    });

    if (!debt) {
      throw new NotFoundException('Debt not found');
    }

    if (Number(debt.remainingAmount) < dto.amount) {
      throw new BadRequestException('Payment amount exceeds remaining debt');
    }

    const updatedRemaining = Number(debt.remainingAmount) - dto.amount;

    const updatedDebt = await this.prisma.debt.update({
      where: { id },
      data: {
        remainingAmount: updatedRemaining,
      },
    });

    const user = await this.prisma.user.findUnique({ where: { id: userId } });

    await this.prisma.transaction.create({
      data: {
        userId,
        groupId: user?.groupId,
        type: 'expense',
        amount: dto.amount,
        date: new Date(),
        currency: 'USD',
        isRecurring: false,
        recurrenceInterval: 'none',
        isPinned: false,
        note: `Погашение долга: ${debt.creditorName}`,
      }
    });

    return updatedDebt;
  }

  async delete(userId: string, id: string) {
    const debt = await this.prisma.debt.findFirst({
      where: { id, userId },
    });

    if (!debt) {
      throw new NotFoundException('Debt not found');
    }

    return this.prisma.debt.delete({
      where: { id },
    });
  }
}
