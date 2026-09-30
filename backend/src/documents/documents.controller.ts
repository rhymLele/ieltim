import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { DocumentsService } from './documents.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { DocumentType } from '../common/enums/document-type.enum';
import { Status } from '../common/enums/status.enum';

@Controller('documents')
@UseGuards(JwtAuthGuard, RolesGuard)
export class DocumentsController {
  constructor(private documentsService: DocumentsService) {}

  @Get()
  findAll(
    @Query('type') type?: DocumentType,
    @Query('week') week?: number,
    @Query('status') status?: Status,
    @Query('page') page?: number,
    @Query('pageSize') pageSize?: number,
    @CurrentUser() user?: { id: string; role: string },
  ) {
    return this.documentsService.findAll({
      type,
      week,
      status,
      role: user?.role,
      page,
      pageSize,
    });
  }

  @Get(':id')
  findOne(@Param('id') id: string, @CurrentUser() user: { id: string; role: string }) {
    return this.documentsService.findById(id, user.role);
  }

  @Post()
  @Roles('ADMIN')
  create(@Body() body: Partial<any>, @CurrentUser() user: { id: string }) {
    return this.documentsService.create(body, user.id);
  }

  @Patch(':id')
  @Roles('ADMIN')
  update(@Param('id') id: string, @Body() body: Partial<any>) {
    return this.documentsService.update(id, body);
  }

  @Delete(':id')
  @Roles('ADMIN')
  remove(@Param('id') id: string) {
    return this.documentsService.remove(id);
  }

  @Post(':id/publish')
  @Roles('ADMIN')
  publish(@Param('id') id: string) {
    return this.documentsService.publish(id);
  }

  @Post(':id/archive')
  @Roles('ADMIN')
  archive(@Param('id') id: string) {
    return this.documentsService.archive(id);
  }
}
