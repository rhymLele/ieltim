import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseArrayPipe,
  ParseIntPipe,
  Patch,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { RolesGuard } from '../common/guards/roles.guard';
import { AdminDocumentsService } from './admin-documents.service';
import { ReorderItemDto } from './dto/document.dto';
import { CreateWeekDto, UpdateWeekDto } from './dto/week.dto';
import { WeeksService } from './weeks.service';
import type { Actor } from './weekly-errors';

/** Quản lý tuần (file 7 mục 3) + sắp xếp tài liệu trong tuần (UC-D10). */
@Controller('admin/weekly/weeks')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
export class AdminWeeksController {
  constructor(
    private weeks: WeeksService,
    private docs: AdminDocumentsService,
  ) {}

  @Get()
  list() {
    return this.weeks.adminList();
  }

  @Post()
  create(@Body() dto: CreateWeekDto) {
    return this.weeks.create(dto);
  }

  @Patch(':number')
  update(
    @Param('number', ParseIntPipe) number: number,
    @Body() dto: UpdateWeekDto,
  ) {
    return this.weeks.update(number, dto);
  }

  @Delete(':number')
  remove(@Param('number', ParseIntPipe) number: number) {
    return this.weeks.remove(number);
  }

  /** Body: `[{ id, order }]`. Lưu một lần cho cả danh sách (atomic). */
  @Put(':number/documents/order')
  reorder(
    @Param('number', ParseIntPipe) number: number,
    @Body(new ParseArrayPipe({ items: ReorderItemDto, whitelist: true }))
    items: ReorderItemDto[],
    @CurrentUser() user: Actor,
  ) {
    return this.docs.reorder(number, items, user);
  }
}
