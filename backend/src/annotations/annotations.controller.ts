import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Put,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { type Actor, weeklyError } from '../weekly-docs/weekly-errors';
import { ActiveUserGuard, VisibleDocGuard } from './access.guards';
import { AnnotationsService } from './annotations.service';
import { HighlightDto, SlideAnnotationDto } from './dto/annotations.dto';

const highlightId = new ParseUUIDPipe({
  exceptionFactory: () =>
    weeklyError(400, 'HIGHLIGHT_ID_INVALID', 'Mã highlight phải là UUID.'),
});

/** Ghi chú cá nhân trên một tài liệu: highlight và nét vẽ theo slide. */
@Controller('me/docs/:docId')
@UseGuards(JwtAuthGuard, ActiveUserGuard, VisibleDocGuard)
export class AnnotationsController {
  constructor(private annotations: AnnotationsService) {}

  @Get('annotations')
  list(@Param('docId') docId: string, @CurrentUser() user: Actor) {
    return this.annotations.list(user.id, docId);
  }

  @Put('highlights/:id')
  upsertHighlight(
    @Param('docId') docId: string,
    @Param('id', highlightId) id: string,
    @Body() dto: HighlightDto,
    @CurrentUser() user: Actor,
  ) {
    return this.annotations.upsertHighlight(user.id, docId, id, dto);
  }

  @Delete('highlights/:id')
  @HttpCode(204)
  async deleteHighlight(
    @Param('docId') docId: string,
    @Param('id', highlightId) id: string,
    @CurrentUser() user: Actor,
  ) {
    await this.annotations.deleteHighlight(user.id, docId, id);
  }

  @Put('slides/:slideKey/annotations')
  saveSlide(
    @Param('docId') docId: string,
    @Param('slideKey') slideKey: string,
    @Body() dto: SlideAnnotationDto,
    @CurrentUser() user: Actor,
  ) {
    return this.annotations.saveSlide(user.id, docId, slideKey, dto);
  }
}
