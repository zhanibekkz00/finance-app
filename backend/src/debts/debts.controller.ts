import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { DebtsService } from './debts.service';
import { CreateDebtDto } from './dto/create-debt.dto';
import { PayDebtDto } from './dto/pay-debt.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('debts')
@UseGuards(JwtAuthGuard)
export class DebtsController {
  constructor(private readonly debtsService: DebtsService) {}

  @Get()
  async findAll(@Request() req) {
    return this.debtsService.findAll(req.user.id);
  }

  @Post()
  async create(@Request() req, @Body() dto: CreateDebtDto) {
    return this.debtsService.create(req.user.id, dto);
  }

  @Patch(':id/pay')
  async pay(@Request() req, @Param('id') id: string, @Body() dto: PayDebtDto) {
    return this.debtsService.pay(req.user.id, id, dto);
  }

  @Delete(':id')
  async delete(@Request() req, @Param('id') id: string) {
    return this.debtsService.delete(req.user.id, id);
  }
}
