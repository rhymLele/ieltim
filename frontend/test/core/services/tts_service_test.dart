import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/core/services/logger_service.dart';
import 'package:frontend/core/services/tts_service.dart';
import 'package:logger/logger.dart';

/// FlutterTts giả: ghi lại lệnh, trả danh sách giọng theo từng lần hỏi.
class _FakeTts extends FlutterTts {
  _FakeTts(this.voiceBatches);

  /// Lần hỏi thứ i trả voiceBatches[i] (hết thì trả phần tử cuối).
  final List<List<Map<String, String>>> voiceBatches;
  final calls = <String>[];
  int _asked = 0;

  @override
  Future<dynamic> get getVoices async => voiceBatches[(_asked++).clamp(0, voiceBatches.length - 1)];

  @override
  Future<dynamic> setLanguage(String language) async => calls.add('lang:$language');

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async => calls.add('voice:${voice['name']}');

  @override
  Future<dynamic> setSpeechRate(double rate) async => calls.add('rate');

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async => calls.add('speak:$text');

  @override
  Future<dynamic> stop() async => calls.add('stop');
}

List<TtsVoice> _voices(List<(String, String)> list) => [for (final (name, locale) in list) TtsVoice(name: name, locale: locale)];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final quietLogger = LoggerService(Logger(level: Level.off));

  group('pickEnglishVoice', () {
    test('Chrome trên macOS: chọn Daniel, bỏ giọng Eloquence (Eddy, Grandma…)', () {
      final voices = _voices([
        ('Eddy (English (United Kingdom))', 'en-GB'),
        ('Grandma (English (United Kingdom))', 'en-GB'),
        ('Daniel', 'en-GB'),
        ('Samantha', 'en-US'),
        ('Linh', 'vi-VN'),
      ]);
      expect(pickEnglishVoice(voices)?.name, 'Daniel');
    });

    test('máy không có giọng Anh-Anh: dùng giọng tiếng Anh khác, không bao giờ dùng giọng tiếng Việt', () {
      final voices = _voices([('Linh', 'vi-VN'), ('Microsoft An - Vietnamese (Vietnam)', 'vi-VN'), ('Samantha', 'en-US')]);
      expect(pickEnglishVoice(voices)?.name, 'Samantha');
      expect(pickEnglishVoice(_voices([('Linh', 'vi-VN')])), isNull);
    });

    test('ưu tiên giọng chất lượng tốt cùng ngôn ngữ (Google, Microsoft Natural)', () {
      final voices = _voices([
        ('Some Generic Voice', 'en-GB'),
        ('Microsoft Sonia Online (Natural) - English (United Kingdom)', 'en-GB'),
      ]);
      expect(pickEnglishVoice(voices)?.name, contains('Sonia'));
    });

    test('đọc được locale kiểu Android (en_GB)', () {
      final voice = TtsVoice.fromMap({'name': 'en-gb-x-gba-local', 'locale': 'en_GB'});
      expect(voice?.locale, 'en-GB');
      expect(pickEnglishVoice([voice!])?.name, 'en-gb-x-gba-local');
    });
  });

  group('TtsService', () {
    test('web: đợi danh sách giọng nạp xong rồi gán đúng giọng đã chọn trước khi đọc', () async {
      final tts = _FakeTts([
        [],
        [],
        [
          {'name': 'Eddy (English (United Kingdom))', 'locale': 'en-GB'},
          {'name': 'Daniel', 'locale': 'en-GB'},
        ],
      ]);
      await TtsService(tts: tts, logger: quietLogger).speak('  Resilient ');
      expect(tts.calls, ['rate', 'lang:en-GB', 'voice:Daniel', 'speak:Resilient']);
    });

    test('chưa có giọng tiếng Anh: vẫn đọc, lần sau chọn lại giọng', () async {
      final tts = _FakeTts([
        [{'name': 'Linh', 'locale': 'vi-VN'}],
        [{'name': 'Daniel', 'locale': 'en-GB'}],
      ]);
      final service = TtsService(tts: tts, logger: quietLogger);
      await service.speak('Mitigate');
      expect(tts.calls, ['rate', 'lang:en-GB', 'speak:Mitigate']);
      tts.calls.clear();
      await service.speak('Mitigate');
      expect(tts.calls, ['rate', 'lang:en-GB', 'voice:Daniel', 'speak:Mitigate']);
    });

    test('chỉ chọn giọng một lần khi đã thành công', () async {
      final tts = _FakeTts([
        [{'name': 'Daniel', 'locale': 'en-GB'}],
      ]);
      final service = TtsService(tts: tts, logger: quietLogger);
      await service.speak('Ubiquitous');
      tts.calls.clear();
      await service.speak('Meticulous');
      expect(tts.calls, ['speak:Meticulous']);
    });
  });
}
