import { Controller, Get, Post, Delete, Param, Body, Query, UseGuards, Request } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('categories')
@UseGuards(JwtAuthGuard)
export class CategoriesController {
  constructor(private categoriesService: CategoriesService) {}

  @Get()
  async findAll(
    @Request() req,
    @Query('includeDefault') includeDefault?: string,
  ) {
    return this.categoriesService.findAll(
      req.user.userId,
      includeDefault !== 'false',
    );
  }

  @Post()
  async create(@Request() req, @Body() dto: CreateCategoryDto) {
    return this.categoriesService.create(req.user.userId, dto);
  }

  @Delete(':id')
  async delete(@Request() req, @Param('id') id: string) {
    return this.categoriesService.delete(req.user.userId, id);
  }
}
