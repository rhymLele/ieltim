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
import { LessonsService } from './lessons.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('lessons')
@UseGuards(JwtAuthGuard, RolesGuard)
export class LessonsController {
  constructor(private lessonsService: LessonsService) {}

  @Get()
  findAll(
    @Query('week') week?: number,
    @Query('level') level?: string,
    @Query('page') page?: number,
    @Query('pageSize') pageSize?: number,
    @CurrentUser() user?: { id: string; role: string },
  ) {
    return this.lessonsService.findAll(user?.role, week, level, page, pageSize);
  }

  @Get('search')
  search(@Query('q') q: string, @CurrentUser() user?: { id: string; role: string }) {
    return this.lessonsService.search(q, user?.role);
  }

  @Get(':id')
  findOne(@Param('id') id: string, @CurrentUser() user?: { id: string; role: string }) {
    return this.lessonsService.findOne(id, user?.role);
  }

  @Post()
  @Roles('ADMIN')
  create(@Body() body: any, @CurrentUser() user: { id: string }) {
    return this.lessonsService.create(body, user.id);
  }

  @Patch(':id')
  @Roles('ADMIN')
  update(@Param('id') id: string, @Body() body: any) {
    return this.lessonsService.update(id, body);
  }

  @Delete(':id')
  @Roles('ADMIN')
  remove(@Param('id') id: string) {
    return this.lessonsService.remove(id);
  }

  @Post(':id/publish')
  @Roles('ADMIN')
  publish(@Param('id') id: string) {
    return this.lessonsService.publish(id);
  }

  @Post(':id/duplicate')
  @Roles('ADMIN')
  duplicate(@Param('id') id: string, @CurrentUser() user: { id: string }) {
    return this.lessonsService.duplicate(id, user.id);
  }

  // Vocabulary mapping
  @Post(':id/vocabularies')
  @Roles('ADMIN')
  addVocabulary(@Param('id') id: string, @Body() body: { vocabularyId: string; position?: number }) {
    return this.lessonsService.addVocabularyToLesson(id, body.vocabularyId, body.position);
  }

  @Delete(':id/vocabularies/:vocabularyId')
  @Roles('ADMIN')
  removeVocabulary(@Param('id') id: string, @Param('vocabularyId') vocabularyId: string) {
    return this.lessonsService.removeVocabularyFromLesson(id, vocabularyId);
  }

  @Patch(':id/vocabularies/reorder')
  @Roles('ADMIN')
  reorderVocabularies(@Param('id') id: string, @Body() body: { orderedIds: string[] }) {
    return this.lessonsService.reorderVocabularies(id, body.orderedIds);
  }

  // Sentence pattern mapping
  @Post(':id/sentence-patterns')
  @Roles('ADMIN')
  addPattern(@Param('id') id: string, @Body() body: { patternId: string; position?: number }) {
    return this.lessonsService.addPatternToLesson(id, body.patternId, body.position);
  }

  @Delete(':id/sentence-patterns/:patternId')
  @Roles('ADMIN')
  removePattern(@Param('id') id: string, @Param('patternId') patternId: string) {
    return this.lessonsService.removePatternFromLesson(id, patternId);
  }

  @Patch(':id/sentence-patterns/reorder')
  @Roles('ADMIN')
  reorderPatterns(@Param('id') id: string, @Body() body: { orderedIds: string[] }) {
    return this.lessonsService.reorderPatterns(id, body.orderedIds);
  }

  // Theory blocks
  @Post(':id/theory')
  @Roles('ADMIN')
  addTheory(@Param('id') id: string, @Body() body: { type: string; content: string; position?: number }) {
    return this.lessonsService.addTheoryBlock(id, body);
  }

  @Patch(':id/theory/:blockId')
  @Roles('ADMIN')
  updateTheory(@Param('id') id: string, @Param('blockId') blockId: string, @Body() body: any) {
    return this.lessonsService.updateTheoryBlock(blockId, body);
  }

  @Delete(':id/theory/:blockId')
  @Roles('ADMIN')
  removeTheory(@Param('id') id: string, @Param('blockId') blockId: string) {
    return this.lessonsService.removeTheoryBlock(blockId);
  }

  @Patch(':id/theory/reorder')
  @Roles('ADMIN')
  reorderTheory(@Param('id') id: string, @Body() body: { orderedIds: string[] }) {
    return this.lessonsService.reorderTheory(id, body.orderedIds);
  }

  // Practice
  @Post(':id/practice')
  @Roles('ADMIN')
  addPractice(@Param('id') id: string, @Body() body: { type: string; question: string; suggestedAnswer?: string; position?: number }) {
    return this.lessonsService.addPractice(id, body);
  }

  @Patch(':id/practice/:practiceId')
  @Roles('ADMIN')
  updatePractice(@Param('id') id: string, @Param('practiceId') practiceId: string, @Body() body: any) {
    return this.lessonsService.updatePractice(practiceId, body);
  }

  @Delete(':id/practice/:practiceId')
  @Roles('ADMIN')
  removePractice(@Param('id') id: string, @Param('practiceId') practiceId: string) {
    return this.lessonsService.removePractice(practiceId);
  }

  @Patch(':id/practice/reorder')
  @Roles('ADMIN')
  reorderPractice(@Param('id') id: string, @Body() body: { orderedIds: string[] }) {
    return this.lessonsService.reorderPractice(id, body.orderedIds);
  }
}
