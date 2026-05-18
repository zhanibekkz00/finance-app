import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { TransactionsService } from './transactions.service';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('transactions')
@UseGuards(JwtAuthGuard)
export class TransactionsController {
  constructor(private transactionsService: TransactionsService) {}

  @Get()
  async findAll(
    @Request() req,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('type') type?: string,
    @Query('categoryId') categoryId?: string,
  ) {
    return this.transactionsService.findAll(req.user.id, {
      from,
      to,
      type,
      categoryId,
    });
  }

  @Get('stats/categories/:categoryId')
  async getCategoryStats(
    @Request() req,
    @Param('categoryId') categoryId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.transactionsService.getCategoryStats(
      req.user.id,
      categoryId,
      from,
      to,
    );
  }

  @Get(':id')
  async findOne(@Request() req, @Param('id') id: string) {
    return this.transactionsService.findOne(req.user.id, id);
  }

  @Post()
  async create(@Request() req, @Body() dto: CreateTransactionDto) {
    return this.transactionsService.create(req.user.id, dto);
  }

  @Put(':id')
  async update(
    @Request() req,
    @Param('id') id: string,
    @Body() dto: UpdateTransactionDto,
  ) {
    return this.transactionsService.update(req.user.id, id, dto);
  }

  @Delete(':id')
  async delete(@Request() req, @Param('id') id: string) {
    return this.transactionsService.delete(req.user.id, id);
  }

  @Put(':id/pin')
  async togglePin(@Request() req, @Param('id') id: string) {
    return this.transactionsService.togglePin(req.user.id, id);
  }
}
