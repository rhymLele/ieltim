import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like } from 'typeorm';
import { Document } from '../documents/entities/document.entity';
import { LessonVocabulary } from './entities/lesson-vocabulary.entity';
import { LessonSentencePattern } from './entities/lesson-sentence-pattern.entity';
import { TheoryBlock } from './entities/theory-block.entity';
import { Practice } from './entities/practice.entity';
import { Vocabulary } from '../vocabularies/entities/vocabulary.entity';
import { Collocation } from '../vocabularies/entities/collocation.entity';
import { SentencePattern } from '../sentence-patterns/entities/sentence-pattern.entity';
import { Tag } from '../tags/entities/tag.entity';
import { IeltsContext } from '../ielts-contexts/entities/ielts-context.entity';
import { Status } from '../common/enums/status.enum';
import { DocumentType } from '../common/enums/document-type.enum';

@Injectable()
export class LessonsService {
  constructor(
    @InjectRepository(Document) private docRepo: Repository<Document>,
    @InjectRepository(LessonVocabulary) private lvRepo: Repository<LessonVocabulary>,
    @InjectRepository(LessonSentencePattern) private lspRepo: Repository<LessonSentencePattern>,
    @InjectRepository(TheoryBlock) private theoryRepo: Repository<TheoryBlock>,
    @InjectRepository(Practice) private practiceRepo: Repository<Practice>,
    @InjectRepository(Vocabulary) private vocabRepo: Repository<Vocabulary>,
    @InjectRepository(Collocation) private collatRepo: Repository<Collocation>,
    @InjectRepository(SentencePattern) private patternRepo: Repository<SentencePattern>,
    @InjectRepository(Tag) private tagRepo: Repository<Tag>,
    @InjectRepository(IeltsContext) private contextRepo: Repository<IeltsContext>,
  ) {}

  async findAll(
    role: string | undefined,
    week?: number,
    level?: string,
    page = 1,
    pageSize = 20,
  ) {
    const qb = this.docRepo.createQueryBuilder('d');
    if (role === 'USER') {
      qb.andWhere('d.status = :status', { status: Status.PUBLISHED });
    }
    if (week) qb.andWhere('d.weekNumber = :week', { week });
    if (level) qb.andWhere('d.level = :level', { level });
    qb.orderBy('d.studyDate', 'ASC');
    qb.skip((page - 1) * pageSize).take(pageSize);
    const [data, total] = await qb.getManyAndCount();
    return { data, pagination: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) } };
  }

  async findOne(id: string, role: string | undefined) {
    const lesson = await this.docRepo.findOne({ where: { id } });
    if (!lesson) throw new HttpException('Lesson not found', HttpStatus.NOT_FOUND);
    if (role === 'USER' && lesson.status !== Status.PUBLISHED) {
      throw new HttpException('Lesson not available', HttpStatus.FORBIDDEN);
    }
    return this.buildLessonDetail(lesson);
  }

  private async buildLessonDetail(lesson: Document) {
    const [lvList, lspList, theoryList, practiceList] = await Promise.all([
      this.lvRepo.find({
        where: { lessonId: lesson.id },
        order: { position: 'ASC' },
        relations: { vocabulary: { collocations: true } },
      }),
      this.lspRepo.find({
        where: { lessonId: lesson.id },
        order: { position: 'ASC' },
        relations: { sentencePattern: true },
      }),
      this.theoryRepo.find({ where: { lessonId: lesson.id }, order: { position: 'ASC' } }),
      this.practiceRepo.find({ where: { lessonId: lesson.id }, order: { position: 'ASC' } }),
    ]);

    const vocabulary = lvList.map((lv) => ({
      ...lv.vocabulary,
      collocations: lv.vocabulary.collocations,
    }));
    const sentencePatterns = lspList.map((lsp) => lsp.sentencePattern);

    return {
      ...lesson,
      vocabulary,
      sentencePatterns,
      theory: theoryList,
      practice: practiceList,
      summary: {
        vocabularyCount: vocabulary.length,
        patternCount: sentencePatterns.length,
        theoryCount: theoryList.length,
        practiceCount: practiceList.length,
      },
    };
  }

  async create(data: any, userId: string) {
    const lesson = this.docRepo.create({ ...data, type: DocumentType.LESSON, createdBy: userId, status: Status.DRAFT });
    return this.docRepo.save(lesson);
  }

  async update(id: string, data: Partial<Document>) {
    const lesson = await this.docRepo.findOne({ where: { id } });
    if (!lesson) throw new HttpException('Lesson not found', HttpStatus.NOT_FOUND);
    Object.assign(lesson, data);
    return this.docRepo.save(lesson);
  }

  async remove(id: string) {
    await this.lvRepo.delete({ lessonId: id });
    await this.lspRepo.delete({ lessonId: id });
    await this.theoryRepo.delete({ lessonId: id });
    await this.practiceRepo.delete({ lessonId: id });
    return this.docRepo.delete(id);
  }

  async publish(id: string) {
    const lesson = await this.docRepo.findOne({ where: { id } });
    if (!lesson) throw new HttpException('Lesson not found', HttpStatus.NOT_FOUND);
    lesson.status = Status.PUBLISHED;
    lesson.publishedAt = new Date();
    return this.docRepo.save(lesson);
  }

  async duplicate(id: string, userId: string) {
    const original = await this.docRepo.findOne({ where: { id } });
    if (!original) throw new HttpException('Lesson not found', HttpStatus.NOT_FOUND);

    const newLesson = this.docRepo.create({
      title: `${original.title} (Copy)`,
      description: original.description,
      studyDate: original.studyDate,
      weekNumber: original.weekNumber,
      level: original.level,
      type: DocumentType.LESSON,
      status: Status.DRAFT,
      createdBy: userId,
    });
    const saved = await this.docRepo.save(newLesson);

    const lvList = await this.lvRepo.find({ where: { lessonId: id } });
    for (const lv of lvList) {
      await this.lvRepo.save(this.lvRepo.create({ lessonId: saved.id, vocabularyId: lv.vocabularyId, position: lv.position }));
    }

    const lspList = await this.lspRepo.find({ where: { lessonId: id } });
    for (const lsp of lspList) {
      await this.lspRepo.save(this.lspRepo.create({ lessonId: saved.id, sentencePatternId: lsp.sentencePatternId, position: lsp.position }));
    }

    const theoryList = await this.theoryRepo.find({ where: { lessonId: id } });
    for (const tb of theoryList) {
      await this.theoryRepo.save(this.theoryRepo.create({ lessonId: saved.id, type: tb.type, content: tb.content, position: tb.position }));
    }

    const practiceList = await this.practiceRepo.find({ where: { lessonId: id } });
    for (const p of practiceList) {
      await this.practiceRepo.save(this.practiceRepo.create({ lessonId: saved.id, type: p.type, question: p.question, suggestedAnswer: p.suggestedAnswer, position: p.position }));
    }

    return saved;
  }

  // Vocabulary mapping
  async addVocabularyToLesson(lessonId: string, vocabularyId: string, position?: number) {
    const existing = await this.lvRepo.findOne({ where: { lessonId, vocabularyId } });
    if (existing) {
      throw new HttpException('Vocabulary already in this lesson', HttpStatus.CONFLICT);
    }
    const maxPos = await this.lvRepo
      .createQueryBuilder('lv')
      .select('MAX(lv.position)', 'maxPos')
      .where('lv.lesson_id = :lessonId', { lessonId })
      .getRawOne();
    const pos = position ?? (maxPos?.maxPos ?? -1) + 1;
    const lv = this.lvRepo.create({ lessonId, vocabularyId, position: pos });
    return this.lvRepo.save(lv);
  }

  async removeVocabularyFromLesson(lessonId: string, vocabularyId: string) {
    return this.lvRepo.delete({ lessonId, vocabularyId });
  }

  async reorderVocabularies(lessonId: string, orderedIds: string[]) {
    for (let i = 0; i < orderedIds.length; i++) {
      await this.lvRepo.update({ lessonId, vocabularyId: orderedIds[i] }, { position: i });
    }
    return { success: true };
  }

  // Sentence pattern mapping
  async addPatternToLesson(lessonId: string, patternId: string, position?: number) {
    const existing = await this.lspRepo.findOne({ where: { lessonId, sentencePatternId: patternId } });
    if (existing) {
      throw new HttpException('Pattern already in this lesson', HttpStatus.CONFLICT);
    }
    const maxPos = await this.lspRepo
      .createQueryBuilder('lsp')
      .select('MAX(lsp.position)', 'maxPos')
      .where('lsp.lesson_id = :lessonId', { lessonId })
      .getRawOne();
    const pos = position ?? (maxPos?.maxPos ?? -1) + 1;
    const lsp = this.lspRepo.create({ lessonId, sentencePatternId: patternId, position: pos });
    return this.lspRepo.save(lsp);
  }

  async removePatternFromLesson(lessonId: string, patternId: string) {
    return this.lspRepo.delete({ lessonId, sentencePatternId: patternId });
  }

  async reorderPatterns(lessonId: string, orderedIds: string[]) {
    for (let i = 0; i < orderedIds.length; i++) {
      await this.lspRepo.update({ lessonId, sentencePatternId: orderedIds[i] }, { position: i });
    }
    return { success: true };
  }

  // Theory blocks
  async addTheoryBlock(lessonId: string, data: { type: string; content: string; position?: number }) {
    const maxPos = await this.theoryRepo
      .createQueryBuilder('tb')
      .select('MAX(tb.position)', 'maxPos')
      .where('tb.lesson_id = :lessonId', { lessonId })
      .getRawOne();
    const block = this.theoryRepo.create({
      lessonId,
      type: data.type,
      content: data.content,
      position: data.position ?? (maxPos?.maxPos ?? -1) + 1,
    });
    return this.theoryRepo.save(block);
  }

  async updateTheoryBlock(id: string, data: Partial<TheoryBlock>) {
    const block = await this.theoryRepo.findOne({ where: { id } });
    if (!block) throw new HttpException('Block not found', HttpStatus.NOT_FOUND);
    Object.assign(block, data);
    return this.theoryRepo.save(block);
  }

  async removeTheoryBlock(id: string) {
    return this.theoryRepo.delete(id);
  }

  async reorderTheory(lessonId: string, orderedIds: string[]) {
    for (let i = 0; i < orderedIds.length; i++) {
      await this.theoryRepo.update({ id: orderedIds[i] }, { position: i });
    }
    return { success: true };
  }

  // Practice
  async addPractice(lessonId: string, data: { type: string; question: string; suggestedAnswer?: string; position?: number }) {
    const maxPos = await this.practiceRepo
      .createQueryBuilder('p')
      .select('MAX(p.position)', 'maxPos')
      .where('p.lesson_id = :lessonId', { lessonId })
      .getRawOne();
    const item = this.practiceRepo.create({
      lessonId,
      type: data.type,
      question: data.question,
      suggestedAnswer: data.suggestedAnswer ?? null,
      position: data.position ?? (maxPos?.maxPos ?? -1) + 1,
    });
    return this.practiceRepo.save(item);
  }

  async updatePractice(id: string, data: Partial<Practice>) {
    const item = await this.practiceRepo.findOne({ where: { id } });
    if (!item) throw new HttpException('Practice not found', HttpStatus.NOT_FOUND);
    Object.assign(item, data);
    return this.practiceRepo.save(item);
  }

  async removePractice(id: string) {
    return this.practiceRepo.delete(id);
  }

  async reorderPractice(lessonId: string, orderedIds: string[]) {
    for (let i = 0; i < orderedIds.length; i++) {
      await this.practiceRepo.update({ id: orderedIds[i] }, { position: i });
    }
    return { success: true };
  }

  // Search
  async search(query: string, role: string | undefined) {
    const like = `%${query}%`;
    const statusVal = role === 'USER' ? Status.PUBLISHED : undefined;

    const lessonQb = this.docRepo.createQueryBuilder('d')
      .where('(d.title LIKE :q OR d.description LIKE :q)', { q: like })
      .andWhere('d.type = :type', { type: DocumentType.LESSON });
    if (statusVal) lessonQb.andWhere('d.status = :st', { st: statusVal });
    const lessons = await lessonQb.take(10).getMany();

    const vocabQb = this.vocabRepo.createQueryBuilder('v')
      .where('(v.term LIKE :q OR v.definition LIKE :q)', { q: like });
    if (statusVal) vocabQb.andWhere('v.status = :st', { st: statusVal });
    const vocabularies = await vocabQb.take(10).getMany();

    const patternQb = this.patternRepo.createQueryBuilder('p')
      .where('(p.pattern LIKE :q OR p.meaning LIKE :q)', { q: like });
    if (statusVal) patternQb.andWhere('p.status = :st', { st: statusVal });
    const patterns = await patternQb.take(10).getMany();

    return {
      lessons: lessons.map((l) => ({ id: l.id, title: l.title })),
      vocabulary: vocabularies.map((v) => ({ id: v.id, term: v.term, matchedField: v.term.toLowerCase().includes(query.toLowerCase()) ? 'term' : 'definition' })),
      sentencePatterns: patterns.map((p) => ({ id: p.id, pattern: p.pattern })),
      total: lessons.length + vocabularies.length + patterns.length,
    };
  }
}
