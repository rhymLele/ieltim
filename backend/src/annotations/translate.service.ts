import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { weeklyError } from '../weekly-docs/weekly-errors';
import {
  DEFAULT_TRANSLATE_DEADLINE_MS,
  DEFAULT_TRANSLATE_RATE_LIMIT,
  DICTIONARY_TIMEOUT_MS,
  TRANSLATE_RATE_WINDOW_MS,
} from './annotations.constants';
import { DictionaryLookup } from './dictionary';
import { cleanText } from './domain/annotation-rules';
import { SlidingWindowLimiter } from './domain/rate-limiter';
import {
  type DictionaryInfo,
  type ModelTranslation,
  type TranslationPayload,
  parseModelTranslation,
  translationKey,
  vietnamesePos,
  wordCount,
} from './domain/translation';
import { TranslateDto } from './dto/translate.dto';
import { TranslationCache } from './entities/translation-cache.entity';
import {
  type LlmTranslateInput,
  LlmFailedError,
  LlmTimeoutError,
  TranslatorLlm,
} from './translator-llm';

/**
 * Dịch nghĩa từ / cụm trong ngữ cảnh câu (Anh → Việt): cache dùng chung → giới hạn lượt / giờ →
 * (song song) IPA từ từ điển miễn phí + nghĩa từ Gemini, hạn chung 6 giây.
 * Không ghi nội dung người dùng tra vào log, chỉ ghi loại lỗi.
 */
@Injectable()
export class TranslateService {
  private readonly logger = new Logger(TranslateService.name);
  private readonly limiter: SlidingWindowLimiter;
  private readonly deadlineMs: number;

  constructor(
    @InjectRepository(TranslationCache)
    private cache: Repository<TranslationCache>,
    private llm: TranslatorLlm,
    private dictionary: DictionaryLookup,
    config: ConfigService,
  ) {
    this.limiter = new SlidingWindowLimiter(
      positiveInt(
        config.get<string>('TRANSLATE_RATE_LIMIT_PER_HOUR'),
        DEFAULT_TRANSLATE_RATE_LIMIT,
      ),
      TRANSLATE_RATE_WINDOW_MS,
    );
    this.deadlineMs = positiveInt(
      config.get<string>('TRANSLATE_DEADLINE_MS'),
      DEFAULT_TRANSLATE_DEADLINE_MS,
    );
  }

  async translate(
    userId: string,
    dto: TranslateDto,
    startedAt = Date.now(),
  ): Promise<TranslationPayload> {
    const deadline = startedAt + this.deadlineMs;
    const text = cleanText(dto.text);
    const sentence = dto.sentence?.trim() ? cleanText(dto.sentence) : null;
    const key = translationKey(dto.text, dto.sentence);

    const hit = await this.cache.findOneBy({ key });
    if (hit) return { ...hit.payload, text };

    if (!this.llm.available())
      throw weeklyError(
        503,
        'TRANSLATE_UNAVAILABLE',
        'Chưa cấu hình dịch nghĩa.',
      );
    if (!this.limiter.take(userId))
      throw weeklyError(
        429,
        'TRANSLATE_RATE_LIMIT',
        'Bạn tra nghĩa quá nhiều trong một giờ, thử lại sau ít phút.',
      );

    const ctrl = new AbortController();
    const timer = setTimeout(
      () => ctrl.abort(),
      Math.max(0, deadline - Date.now()),
    );
    try {
      const words = wordCount(text);
      const dict =
        words <= 3
          ? this.lookupDictionary(text, ctrl.signal)
          : Promise.resolve(null);
      const model = await this.askModel(
        { text, sentence, singleWord: words === 1 },
        deadline,
        ctrl.signal,
      );
      const info = await dict;
      const payload: TranslationPayload = {
        text,
        meaning: model.meaning,
        ipa: info?.ipa ?? null,
        partOfSpeech: model.partOfSpeech ?? vietnamesePos(info?.partOfSpeech),
        sentenceTranslation: sentence ? model.sentenceTranslation : null,
      };
      await this.cache.upsert({ key, payload }, ['key']);
      return payload;
    } finally {
      clearTimeout(timer);
      // Model lỗi thì huỷ luôn lượt tra từ điển còn dở.
      ctrl.abort();
    }
  }

  /** Gọi model, JSON sai schema thì gọi lại đúng một lần (vẫn trong hạn chung). */
  private async askModel(
    input: LlmTranslateInput,
    deadline: number,
    signal: AbortSignal,
  ): Promise<ModelTranslation> {
    try {
      for (let attempt = 1; attempt <= 2; attempt++) {
        const remaining = deadline - Date.now();
        if (remaining <= 0 || signal.aborted) throw new LlmTimeoutError();
        const reply = await untilAborted(
          this.llm.complete(input, { timeoutMs: remaining, signal }),
          signal,
        );
        if (reply.kind === 'refusal') throw new LlmFailedError('refusal');
        const parsed = parseModelTranslation(reply.text);
        if (parsed) return parsed;
        this.logger.warn(`translate: invalid_output (attempt ${attempt})`);
      }
      throw new LlmFailedError('invalid_output');
    } catch (e) {
      if (e instanceof LlmTimeoutError || signal.aborted) {
        this.logger.warn('translate: timeout');
        throw weeklyError(
          504,
          'TRANSLATE_TIMEOUT',
          'Dịch nghĩa quá lâu, thử lại sau.',
        );
      }
      const category =
        e instanceof LlmFailedError
          ? e.category
          : `unexpected_${(e as Error)?.name ?? 'unknown'}`;
      this.logger.warn(`translate: failed (${category})`);
      throw weeklyError(
        502,
        'TRANSLATE_FAILED',
        'Không dịch được lúc này, thử lại sau.',
      );
    }
  }

  /** IPA là phần phụ: lỗi / quá 3 giây thì bỏ qua. */
  private async lookupDictionary(
    text: string,
    signal: AbortSignal,
  ): Promise<DictionaryInfo | null> {
    const capped = AbortSignal.any([
      signal,
      AbortSignal.timeout(DICTIONARY_TIMEOUT_MS),
    ]);
    try {
      return await untilAborted(this.dictionary.lookup(text, capped), capped);
    } catch {
      this.logger.debug('translate: dictionary_unavailable');
      return null;
    }
  }
}

/** Chờ `p` nhưng dừng ngay khi `signal` bị huỷ (kể cả khi bên gọi không tôn trọng signal). */
function untilAborted<T>(p: Promise<T>, signal: AbortSignal): Promise<T> {
  if (signal.aborted) return Promise.reject(new LlmTimeoutError());
  return new Promise<T>((resolve, reject) => {
    const onAbort = () => reject(new LlmTimeoutError());
    signal.addEventListener('abort', onAbort, { once: true });
    p.then(resolve, reject).finally(() =>
      signal.removeEventListener('abort', onAbort),
    );
  });
}

function positiveInt(raw: string | undefined, fallback: number): number {
  const n = Number(raw);
  return raw && Number.isInteger(n) && n > 0 ? n : fallback;
}
