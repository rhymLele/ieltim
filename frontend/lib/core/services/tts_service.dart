import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../di/service_locator.dart';
import 'logger_service.dart';

/// Một giọng đọc của máy (flutter_tts trả `{name, locale}` trên mọi nền tảng).
class TtsVoice {
  const TtsVoice({required this.name, required this.locale});

  final String name;

  /// Dạng `en-GB` (Android có thể trả `en_GB`, đã chuẩn hoá khi đọc).
  final String locale;

  static TtsVoice? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final locale = raw['locale'];
    if (name is! String || locale is! String) return null;
    return TtsVoice(name: name, locale: locale.replaceAll('_', '-'));
  }

  @override
  String toString() => '$name ($locale)';
}

/// Giọng "vui" / giọng tổng hợp đời cũ của Apple (Eloquence, MacinTalk): đọc sai nhiều từ, không dùng để học phát âm.
const _lowQualityVoices = {
  'eddy', 'flo', 'grandma', 'grandpa', 'reed', 'rocko', 'sandy', 'shelley', //
  'albert', 'bad news', 'bahh', 'bells', 'boing', 'bubbles', 'cellos', 'good news', 'jester', 'organ', //
  'superstar', 'trinoids', 'whisper', 'wobble', 'zarvox', 'junior', 'ralph', 'fred', 'kathy',
};

/// Giọng tiếng Anh chất lượng tốt thường gặp: Google (Chrome), Microsoft Natural / Online (Edge), Apple, Windows.
const _goodVoiceHints = [
  'google', 'natural', 'online', 'premium', 'enhanced', //
  'daniel', 'serena', 'kate', 'oliver', 'arthur', 'martha', 'hazel', 'george', 'susan', 'libby', 'sonia', 'ryan',
];

/// Chọn giọng đọc tiếng Anh tốt nhất trong [voices]; ưu tiên [preferredLocale] (Anh-Anh).
///
/// Không bao giờ chọn giọng không phải tiếng Anh: đọc từ tiếng Anh bằng giọng tiếng Việt là nguyên nhân
/// phát âm sai. Trả null khi máy không có giọng tiếng Anh nào dùng được.
TtsVoice? pickEnglishVoice(Iterable<TtsVoice> voices, {String preferredLocale = 'en-GB'}) {
  TtsVoice? best;
  var bestScore = -1;
  for (final voice in voices) {
    final locale = voice.locale.toLowerCase();
    if (!locale.startsWith('en')) continue;
    final name = voice.name.toLowerCase();
    if (_lowQualityVoices.contains(name.split('(').first.trim())) continue;
    var score = locale == preferredLocale.toLowerCase() ? 100 : 50;
    if (_goodVoiceHints.any(name.contains)) score += 20;
    // Giữ thứ tự của máy khi bằng điểm (giọng đứng trước thường là giọng mặc định của ngôn ngữ đó).
    if (score > bestScore) {
      best = voice;
      bestScore = score;
    }
  }
  return best;
}

/// Đọc to từ / câu tiếng Anh bằng giọng có sẵn của máy (flutter_tts) — Android, iOS, web, macOS, Windows.
///
/// Tự chọn giọng tiếng Anh tốt nhất thay vì để máy dùng giọng mặc định (có thể là tiếng Việt).
/// Trên web, danh sách giọng chỉ có sau lần hỏi đầu tiên nên phải đợi; chưa chọn được thì lần sau thử lại.
class TtsService {
  TtsService({FlutterTts? tts, LoggerService? logger, this.preferredLocale = 'en-GB'})
      : _injectedTts = tts,
        _logger = logger ?? getSingleton<LoggerService>();

  final FlutterTts? _injectedTts;

  /// Tạo khi đọc lần đầu: FlutterTts mở kênh nền tảng ngay khi khởi tạo, mà service được đăng ký
  /// trong `main()` trước `runApp` (binding chưa sẵn sàng → app trắng màn).
  late final FlutterTts _tts = _injectedTts ?? FlutterTts();
  final LoggerService _logger;
  final String preferredLocale;

  Future<bool>? _setup;
  bool _speaking = false;

  /// Đọc [text]; đang đọc thì dừng và đọc lại từ đầu. Lỗi (máy không có TTS…) chỉ ghi log.
  Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    try {
      final ready = await (_setup ??= _configure());
      if (!ready) _setup = null;
      if (_speaking) {
        await _tts.stop();
        // Web: trình duyệt báo đã dừng ở lượt sự kiện sau; gọi đọc ngay thì flutter_tts bỏ qua.
        for (var i = 0; i < 10 && _speaking; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }
      }
      await _tts.speak(clean);
    } catch (e, stackTrace) {
      _setup = null;
      _speaking = false;
      _logger.warning('TtsService: không đọc được "$clean"', e, stackTrace);
    }
  }

  /// Chọn giọng + tốc độ. Trả false khi chưa có giọng tiếng Anh (lần đọc sau thử lại).
  Future<bool> _configure() async {
    _tts
      ..setStartHandler(() => _speaking = true)
      ..setCompletionHandler(() => _speaking = false)
      ..setCancelHandler(() => _speaking = false)
      ..setErrorHandler((_) => _speaking = false);
    // Web dùng thang 1.0 = bình thường, iOS / Android dùng 0.5 = bình thường; đọc hơi chậm cho người học.
    await _tts.setSpeechRate(kIsWeb ? 0.9 : 0.45);
    final voice = pickEnglishVoice(await _loadVoices(), preferredLocale: preferredLocale);
    if (voice == null) {
      await _tts.setLanguage(preferredLocale);
      _logger.warning('TtsService: máy không có giọng tiếng Anh, dùng giọng mặc định');
      return false;
    }
    // setLanguage trước: trên web nó tự gán giọng đầu tiên của ngôn ngữ, setVoice sau mới giữ đúng giọng đã chọn.
    await _tts.setLanguage(voice.locale);
    await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
    _logger.info('TtsService: dùng giọng $voice');
    return true;
  }

  /// Web (Chrome): lần hỏi đầu trả danh sách rỗng, giọng nạp ngầm sau đó.
  Future<List<TtsVoice>> _loadVoices() async {
    for (var attempt = 0; attempt < 15; attempt++) {
      final raw = await _tts.getVoices;
      final voices = raw is List ? raw.map(TtsVoice.fromMap).whereType<TtsVoice>().toList() : const <TtsVoice>[];
      if (voices.isNotEmpty) return voices;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return const [];
  }
}
