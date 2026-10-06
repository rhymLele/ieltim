import { createHash } from 'crypto';
import {
  parseModelTranslation,
  pickDictionaryInfo,
  translationKey,
  translationSystemPrompt,
  translationUserMessage,
  vietnamesePos,
  wordCount,
} from './translation';

describe('translation', () => {
  it('khoá cache: sha1(lower(trim(text)) | lower(trim(sentence)))', () => {
    const expected = createHash('sha1')
      .update('take part|we take part in it.')
      .digest('hex');
    expect(translationKey('  Take Part ', ' We take part in it. ')).toBe(
      expected,
    );
    expect(translationKey('word', undefined)).toBe(
      createHash('sha1').update('word|').digest('hex'),
    );
  });

  it('JSON đúng schema; chuỗi rỗng thành null', () => {
    expect(
      parseModelTranslation(
        '{"meaning":" bền bỉ ","partOfSpeech":"","sentenceTranslation":""}',
      ),
    ).toEqual({
      meaning: 'bền bỉ',
      partOfSpeech: null,
      sentenceTranslation: null,
    });
  });

  it('JSON sai schema → null', () => {
    for (const raw of [
      null,
      '',
      'không phải json',
      '[]',
      '"chuỗi"',
      '{"meaning":"a","partOfSpeech":"b"}',
      '{"meaning":"a","partOfSpeech":"b","sentenceTranslation":"c","x":1}',
      '{"meaning":1,"partOfSpeech":"b","sentenceTranslation":"c"}',
      '{"meaning":"  ","partOfSpeech":"b","sentenceTranslation":"c"}',
    ])
      expect(parseModelTranslation(raw)).toBeNull();
  });

  it('phiên âm: ưu tiên audio -uk, không có thì lấy phiên âm đầu tiên', () => {
    const body = [
      {
        phonetic: '/x/',
        phonetics: [
          { text: '', audio: 'a-uk.mp3' },
          { text: '/rɪˈzɪl.jənt/', audio: 'resilient-us.mp3' },
          { text: '/rɪˈzɪlɪənt/', audio: 'resilient-uk.mp3' },
        ],
        meanings: [{ partOfSpeech: 'adjective' }],
      },
    ];
    expect(pickDictionaryInfo(body)).toEqual({
      ipa: '/rɪˈzɪlɪənt/',
      partOfSpeech: 'adjective',
    });
    body[0].phonetics.pop();
    expect(pickDictionaryInfo(body)?.ipa).toBe('/rɪˈzɪl.jənt/');
    body[0].phonetics = [];
    expect(pickDictionaryInfo(body)?.ipa).toBe('/x/');
    expect(pickDictionaryInfo({ title: 'No Definitions Found' })).toBeNull();
  });

  it('từ loại tiếng Anh → nhãn tiếng Việt', () => {
    expect(vietnamesePos('Noun')).toBe('danh từ');
    expect(vietnamesePos('abbreviation')).toBeNull();
    expect(vietnamesePos(null)).toBeNull();
  });

  it('prompt: TỪ cho một từ, CỤM cho cụm; chữ người dùng chỉ nằm ở tin nhắn user', () => {
    expect(translationSystemPrompt(true)).toContain('của TỪ cần dịch');
    expect(translationSystemPrompt(false)).toContain('của CỤM cần dịch');
    expect(translationUserMessage('take part', null, false)).toBe(
      'Cụm cần dịch: take part\nCâu chứa cụm: (không có)',
    );
    expect(wordCount('  take   part in ')).toBe(3);
  });
});
