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
import { VocabulariesService } from './vocabularies.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Level } from '../common/enums/level.enum';
import { Status } from '../common/enums/status.enum';

@Controller('vocabularies')
@UseGuards(JwtAuthGuard, RolesGuard)
export class VocabulariesController {
  constructor(private vocabService: VocabulariesService) {}

  @Get()
  findAll(
    @Query('level') level?: Level,
    @Query('status') status?: Status,
    @Query('page') page?: number,
    @Query('pageSize') pageSize?: number,
    @CurrentUser() user?: { id: string; role: string },
  ) {
    return this.vocabService.findAll({ level, status, role: user?.role, page, pageSize });
  }

  @Get(':id')
  findOne(@Param('id') id: string, @CurrentUser() user: { id: string; role: string }) {
    return this.vocabService.findById(id, user.role);
  }

  @Post()
  @Roles('ADMIN')
  create(@Body() body: Partial<any>, @CurrentUser() user: { id: string }) {
    return this.vocabService.create(body, user.id);
  }

  @Patch(':id')
  @Roles('ADMIN')
  update(@Param('id') id: string, @Body() body: Partial<any>) {
    return this.vocabService.update(id, body);
  }

  @Delete(':id')
  @Roles('ADMIN')
  remove(@Param('id') id: string) {
    return this.vocabService.remove(id);
  }

  @Post(':id/publish')
  @Roles('ADMIN')
  publish(@Param('id') id: string) {
    return this.vocabService.publish(id);
  }
}
