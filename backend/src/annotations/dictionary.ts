import { Injectable } from '@nestjs/common';
import { DICTIONARY_URL } from './annotations.constants';
import { type DictionaryInfo, pickDictionaryInfo } from './domain/translation';

/** Tra phiên âm (IPA) / từ loại tiếng Anh. Test thay bằng bản giả, không gọi mạng. */
export abstract class DictionaryLookup {
  /** null khi không có (404, lỗi mạng…): dịch nghĩa vẫn trả kết quả, chỉ thiếu IPA. */
  abstract lookup(
    term: string,
    signal: AbortSignal,
  ): Promise<DictionaryInfo | null>;
}

/** Từ điển miễn phí api.dictionaryapi.dev. */
@Injectable()
export class FreeDictionaryLookup extends DictionaryLookup {
  async lookup(
    term: string,
    signal: AbortSignal,
  ): Promise<DictionaryInfo | null> {
    const res = await fetch(
      DICTIONARY_URL + encodeURIComponent(term.trim().toLowerCase()),
      { signal, headers: { accept: 'application/json' } },
    );
    if (!res.ok) return null;
    return pickDictionaryInfo(await res.json());
  }
}
