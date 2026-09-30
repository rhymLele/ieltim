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
import { WebResourcesService } from './web-resources.service';
import { LinkPreviewService } from './link-preview.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('web-resources')
@UseGuards(JwtAuthGuard, RolesGuard)
export class WebResourcesController {
  constructor(
    private resService: WebResourcesService,
    private linkPreviewService: LinkPreviewService,
  ) {}

  @Get()
  findAll(
    @Query('page') page?: number,
    @Query('pageSize') pageSize?: number,
    @CurrentUser() user?: { id: string; role: string },
  ) {
    return this.resService.findAll(user?.role, page, pageSize);
  }

  @Get('link-preview')
  async linkPreview(@Query('url') url: string) {
    if (!url) return { title: '', description: null, imageUrl: null, faviconUrl: null, domain: '' };
    return this.linkPreviewService.fetchPreview(url);
  }

  @Post()
  @Roles('ADMIN')
  create(@Body() body: Partial<any>, @CurrentUser() user: { id: string }) {
    return this.resService.create(body, user.id);
  }

  @Patch(':id')
  @Roles('ADMIN')
  update(@Param('id') id: string, @Body() body: Partial<any>) {
    return this.resService.update(id, body);
  }

  @Delete(':id')
  @Roles('ADMIN')
  remove(@Param('id') id: string) {
    return this.resService.remove(id);
  }
}
