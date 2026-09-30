import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { CommentsService } from './comments.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('documents/:documentId/comments')
@UseGuards(JwtAuthGuard)
export class CommentsController {
  constructor(private commentsService: CommentsService) {}

  @Get()
  findByDocument(@Param('documentId') documentId: string) {
    return this.commentsService.findByDocumentId(documentId);
  }

  @Post()
  create(
    @Param('documentId') documentId: string,
    @Body() body: { parentId?: string; content: string },
    @CurrentUser() user: { id: string; role: string },
  ) {
    return this.commentsService.create({
      documentId,
      userId: user.id,
      parentId: body.parentId,
      content: body.content,
    });
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() body: { content: string },
    @CurrentUser() user: { id: string; role: string },
  ) {
    return this.commentsService.update(id, user.id, user.role, body.content);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @CurrentUser() user: { id: string; role: string }) {
    return this.commentsService.remove(id, user.id, user.role);
  }
}
