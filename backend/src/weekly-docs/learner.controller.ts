import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import {
  ProgressDto,
  QuizAnswerDto,
  VocabFromDocumentDto,
} from './dto/learner.dto';
import { LearnerService } from './learner.service';
import type { Actor } from './weekly-errors';

/** API người dùng (file 2 mục 3, phần "Người dùng"). */
@Controller('weekly')
@UseGuards(JwtAuthGuard)
export class LearnerController {
  constructor(private learner: LearnerService) {}

  @Get('weeks')
  weeks(@CurrentUser() user: Actor) {
    return this.learner.weekList(user.id);
  }

  @Get('weeks/:number/documents')
  weekDocuments(
    @Param('number', ParseIntPipe) number: number,
    @CurrentUser() user: Actor,
  ) {
    return this.learner.weekDocuments(user.id, number);
  }

  /** Hỗ trợ `If-None-Match` → 304 để FE cache offline. */
  @Get('documents/:id')
  async document(
    @Param('id') id: string,
    @CurrentUser() user: Actor,
    @Headers('if-none-match') ifNoneMatch: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { etag, body } = await this.learner.document(user.id, id);
    res.setHeader('ETag', etag);
    res.setHeader('Cache-Control', 'private, no-cache');
    if (ifNoneMatch && ifNoneMatch.split(',').some((t) => t.trim() === etag)) {
      res.status(304);
      return undefined;
    }
    return body;
  }

  @Put('documents/:id/progress')
  progress(
    @Param('id') id: string,
    @Body() dto: ProgressDto,
    @CurrentUser() user: Actor,
  ) {
    return this.learner.saveProgress(user.id, id, dto);
  }

  @Post('documents/:id/quiz-answers')
  quizAnswer(
    @Param('id') id: string,
    @Body() dto: QuizAnswerDto,
    @CurrentUser() user: Actor,
  ) {
    return this.learner.answerQuiz(user.id, id, dto);
  }

  @Post('documents/:id/complete')
  complete(@Param('id') id: string, @CurrentUser() user: Actor) {
    return this.learner.complete(user.id, id);
  }

  @Post('vocab/from-document')
  vocabFromDocument(
    @Body() dto: VocabFromDocumentDto,
    @CurrentUser() user: Actor,
  ) {
    return this.learner.vocabFromDocument(user.id, dto);
  }

  @Get('me/summary')
  summary(@CurrentUser() user: Actor) {
    return this.learner.summary(user.id);
  }
}
