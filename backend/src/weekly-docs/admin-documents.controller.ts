import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  Param,
  Post,
  Put,
  Query,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { RolesGuard } from '../common/guards/roles.guard';
import { AdminDocumentsService } from './admin-documents.service';
import type { UploadedJsonFile } from './admin-documents.service';
import {
  CreateDocumentDto,
  DuplicateDocumentDto,
  ExportQueryDto,
  ImportDocumentDto,
  ListDocumentsQueryDto,
  PublishDocumentDto,
  SaveDocumentDto,
  ScheduleDocumentDto,
  UnpublishDocumentDto,
  ValidateContentDto,
} from './dto/document.dto';
import { IMPORT_MAX_BYTES } from './weekly-docs.constants';
import type { Actor } from './weekly-errors';

/** API admin tài liệu theo tuần (file 2 mục 3, file 7 mục 8, file 9 mục 7). Body tới 8 MB (tài liệu HTML). */
@Controller('admin/weekly')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
export class AdminDocumentsController {
  constructor(private docs: AdminDocumentsService) {}

  @Get('templates')
  templates() {
    return this.docs.templates();
  }

  @Get('templates/:id')
  template(@Param('id') id: string) {
    return this.docs.template(id);
  }

  @Get('documents')
  list(@Query() q: ListDocumentsQueryDto) {
    return this.docs.list(q);
  }

  @Post('documents')
  create(@Body() dto: CreateDocumentDto, @CurrentUser() user: Actor) {
    return this.docs.create(dto, user);
  }

  /** Chạy thử kiểm tra một `content` bất kỳ (object hoặc chuỗi JSON), không lưu. */
  @Post('documents/validate')
  validate(@Body() dto: ValidateContentDto) {
    return this.docs.validate(dto.content);
  }

  /** multipart/form-data: `file` (.json ≤ 1 MB) + `week` (+ `order`). */
  @Post('documents/import')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: IMPORT_MAX_BYTES * 2 } }),
  )
  import(
    @UploadedFile() file: UploadedJsonFile | undefined,
    @Body() dto: ImportDocumentDto,
    @CurrentUser() user: Actor,
  ) {
    return this.docs.import(file, dto, user);
  }

  @Get('documents/:id')
  detail(@Param('id') id: string, @Query() q: ExportQueryDto) {
    return this.docs.detail(id, q.source === 'live' ? 'live' : 'working');
  }

  /** Lưu nháp. Body: `{ content, version, … }`. Sai version → 409 kèm bản hiện tại. */
  @Put('documents/:id')
  save(
    @Param('id') id: string,
    @Body() dto: SaveDocumentDto,
    @CurrentUser() user: Actor,
  ) {
    return this.docs.save(id, dto, user);
  }

  @Delete('documents/:id')
  remove(@Param('id') id: string, @CurrentUser() user: Actor) {
    return this.docs.remove(id, user);
  }

  @Post('documents/:id/undelete')
  undelete(@Param('id') id: string, @CurrentUser() user: Actor) {
    return this.docs.undelete(id, user);
  }

  @Get('documents/:id/export')
  @Header('Content-Type', 'application/json; charset=utf-8')
  async export(
    @Param('id') id: string,
    @Query() q: ExportQueryDto,
    @Res() res: Response,
  ) {
    const { fileName, body } = await this.docs.export(id, q.source ?? 'live');
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    res.send(body);
  }

  @Get('documents/:id/preview')
  preview(@Param('id') id: string) {
    return this.docs.preview(id);
  }

  @Post('documents/:id/publish')
  publish(
    @Param('id') id: string,
    @Body() dto: PublishDocumentDto,
    @CurrentUser() user: Actor,
  ) {
    return this.docs.publish(id, dto.publishAt, user);
  }

  @Post('documents/:id/schedule')
  schedule(
    @Param('id') id: string,
    @Body() dto: ScheduleDocumentDto,
    @CurrentUser() user: Actor,
  ) {
    return this.docs.schedule(id, dto.publishAt, user);
  }

  @Delete('documents/:id/schedule')
  unschedule(@Param('id') id: string, @CurrentUser() user: Actor) {
    return this.docs.unschedule(id, user);
  }

  @Post('documents/:id/unpublish')
  unpublish(
    @Param('id') id: string,
    @Body() dto: UnpublishDocumentDto,
    @CurrentUser() user: Actor,
  ) {
    return this.docs.unpublish(id, dto.reason, user);
  }

  @Post('documents/:id/restore')
  restore(@Param('id') id: string, @CurrentUser() user: Actor) {
    return this.docs.restore(id, user);
  }

  @Post('documents/:id/release')
  release(@Param('id') id: string, @CurrentUser() user: Actor) {
    return this.docs.release(id, user);
  }

  @Delete('documents/:id/revision-draft')
  discardRevisionDraft(@Param('id') id: string, @CurrentUser() user: Actor) {
    return this.docs.discardRevisionDraft(id, user);
  }

  @Post('documents/:id/duplicate')
  duplicate(
    @Param('id') id: string,
    @Body() dto: DuplicateDocumentDto,
    @CurrentUser() user: Actor,
  ) {
    return this.docs.duplicate(id, dto.targetWeek, user);
  }

  @Get('documents/:id/revisions')
  revisions(@Param('id') id: string) {
    return this.docs.revisionsOf(id);
  }

  @Post('documents/:id/revisions/:revisionId/restore')
  restoreRevision(
    @Param('id') id: string,
    @Param('revisionId') revisionId: string,
    @CurrentUser() user: Actor,
  ) {
    return this.docs.restoreRevision(id, revisionId, user);
  }

  @Get('documents/:id/audit')
  audit(@Param('id') id: string) {
    return this.docs.auditOf(id);
  }
}
