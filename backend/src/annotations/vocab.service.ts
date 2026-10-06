import { Injectable } from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { isUUID } from 'class-validator';
import { DataSource, QueryFailedError, Repository } from 'typeorm';
import { normalizeWord } from '../weekly-docs/domain/doc-content';
import { VocabEntry } from '../weekly-docs/entities/vocab-entry.entity';
import { DEFAULT_VOCAB_DECK } from '../weekly-docs/weekly-docs.constants';
import { weeklyError } from '../weekly-docs/weekly-errors';
import { VOCAB_LIST_CAP } from './annotations.constants';
import { cleanText } from './domain/annotation-rules';
import {
  CreateVocabDto,
  UpdateVocabDto,
  VocabListQueryDto,
} from './dto/vocab.dto';

/** Tên sổ: bỏ khoảng trắng thừa, rỗng → 'Sổ chung'. */
export function deckName(deck: string | null | undefined): string {
  return cleanText(deck ?? '') || DEFAULT_VOCAB_DECK;
}

/** Khoá bỏ trùng: chữ thường, bỏ khoảng trắng thừa (như khi lưu từ tài liệu). */
export function vocabNorm(text: string): string {
  return normalizeWord(text).slice(0, 120);
}

/**
 * Sổ từ cá nhân (thêm tay từ màn đọc tài liệu, nhiều sổ). Dùng chung bảng `vocab_entries` với
 * "Lưu từ vựng của tài liệu" (weekly-docs), bỏ trùng theo (người dùng, từ đã chuẩn hoá, sổ).
 */
@Injectable()
export class VocabService {
  constructor(
    @InjectRepository(VocabEntry) private vocab: Repository<VocabEntry>,
    @InjectDataSource() private dataSource: DataSource,
  ) {}

  async create(userId: string, dto: CreateVocabDto) {
    const word = cleanText(dto.text);
    const wordNorm = vocabNorm(word);
    const deck = deckName(dto.deck);
    const res = await this.vocab
      .createQueryBuilder()
      .insert()
      .into(VocabEntry)
      .values({
        userId,
        word,
        wordNorm,
        deck,
        meaning: dto.meaning?.trim() ?? '',
        ipa: dto.ipa?.trim() || null,
        example: dto.example?.trim() || null,
        pos: dto.partOfSpeech?.trim() || null,
        sourceDocumentId: dto.sourceDocId || null,
        sourceBlockKey: dto.sourceBlockKey || null,
      })
      .orIgnore()
      .returning(['id'])
      .execute();
    const id = (res.raw as { id: string }[] | undefined)?.[0]?.id;
    if (!id) throw await this.exists409(userId, wordNorm, deck);
    return toVocabJson(await this.vocab.findOneByOrFail({ id }));
  }

  /** Mới nhất trước. `q`: chứa trong từ hoặc nghĩa, không phân biệt hoa / thường. */
  async list(userId: string, query: VocabListQueryDto) {
    const qb = this.vocab
      .createQueryBuilder('v')
      .where('v.userId = :userId', { userId });
    if (query.deck?.trim())
      qb.andWhere('v.deck = :deck', { deck: deckName(query.deck) });
    const q = cleanText(query.q ?? '');
    if (q)
      qb.andWhere(
        `(v.word ILIKE :q ESCAPE '\\' OR v.meaning ILIKE :q ESCAPE '\\')`,
        { q: `%${q.replace(/[\\%_]/g, '\\$&')}%` },
      );
    const rows = await qb
      .orderBy('v.createdAt', 'DESC')
      .addOrderBy('v.id', 'DESC')
      .limit(VOCAB_LIST_CAP)
      .getMany();
    return rows.map(toVocabJson);
  }

  /** Từ đã có trong bất kỳ sổ nào của tôi. */
  async exists(userId: string, text: string | undefined): Promise<boolean> {
    const wordNorm = vocabNorm(text ?? '');
    if (!wordNorm) return false;
    return this.vocab.exists({ where: { userId, wordNorm } });
  }

  /** Các sổ của tôi, dùng gần nhất trước; luôn có 'Sổ chung' (cuối danh sách nếu chưa dùng). */
  async decks(userId: string): Promise<string[]> {
    const rows = await this.vocab
      .createQueryBuilder('v')
      .select('v.deck', 'deck')
      .addSelect('MAX(v.createdAt)', 'last_used')
      .where('v.userId = :userId', { userId })
      .groupBy('v.deck')
      .orderBy('last_used', 'DESC')
      .addOrderBy('v.deck', 'ASC')
      .getRawMany<{ deck: string }>();
    const names = rows.map((r) => r.deck);
    if (!names.includes(DEFAULT_VOCAB_DECK)) names.push(DEFAULT_VOCAB_DECK);
    return names;
  }

  async update(userId: string, id: string, dto: UpdateVocabDto) {
    if (!isUUID(id)) throw notFound();
    // Từ / sổ đích, dùng khi ràng buộc unique chặn ở bước ghi.
    const target: { wordNorm?: string; deck?: string } = {};
    try {
      return await this.dataSource.transaction(async (m) => {
        const entry = await m.findOne(VocabEntry, {
          where: { id, userId },
          lock: { mode: 'pessimistic_write' },
        });
        if (!entry) throw notFound();
        const word = dto.text != null ? cleanText(dto.text) : entry.word;
        const wordNorm = vocabNorm(word);
        const deck = dto.deck != null ? deckName(dto.deck) : entry.deck;
        Object.assign(target, { wordNorm, deck });
        if (wordNorm !== entry.wordNorm || deck !== entry.deck) {
          const other = await m.findOne(VocabEntry, {
            where: { userId, wordNorm, deck },
          });
          if (other && other.id !== entry.id)
            throw vocabExists(other.word, deck, other);
        }
        await m.update(
          VocabEntry,
          { id },
          {
            word,
            wordNorm,
            deck,
            meaning: dto.meaning != null ? dto.meaning.trim() : entry.meaning,
            example:
              dto.example !== undefined
                ? dto.example?.trim() || null
                : entry.example,
            pos:
              dto.partOfSpeech !== undefined
                ? dto.partOfSpeech?.trim() || null
                : entry.pos,
          },
        );
        return toVocabJson(await m.findOneByOrFail(VocabEntry, { id }));
      });
    } catch (e) {
      // Hai lần sửa song song cùng đổi về một từ: ràng buộc unique chặn lần sau.
      if (isUniqueViolation(e) && target.wordNorm && target.deck)
        throw await this.exists409(userId, target.wordNorm, target.deck);
      throw e;
    }
  }

  async remove(userId: string, id: string) {
    if (!isUUID(id)) throw notFound();
    const res = await this.vocab.delete({ id, userId });
    if (!res.affected) throw notFound();
  }

  private async exists409(userId: string, wordNorm: string, deck: string) {
    const existing = await this.vocab.findOneBy({ userId, wordNorm, deck });
    return vocabExists(existing?.word ?? wordNorm, deck, existing);
  }
}

export function toVocabJson(v: VocabEntry) {
  return {
    id: v.id,
    text: v.word,
    meaning: v.meaning,
    ipa: v.ipa,
    example: v.example,
    partOfSpeech: v.pos,
    deck: v.deck,
    sourceDocId: v.sourceDocumentId,
    sourceBlockKey: v.sourceBlockKey,
    createdAt: v.createdAt,
  };
}

function notFound() {
  return weeklyError(404, 'VOCAB_NOT_FOUND', 'Không tìm thấy từ này.');
}

function vocabExists(word: string, deck: string, entry: VocabEntry | null) {
  return weeklyError(
    409,
    'VOCAB_EXISTS',
    `"${word}" đã có trong ${deck}.`,
    entry ? toVocabJson(entry) : null,
  );
}

function isUniqueViolation(e: unknown): boolean {
  return (
    e instanceof QueryFailedError &&
    (e.driverError as { code?: string } | undefined)?.code === '23505'
  );
}
