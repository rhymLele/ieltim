// speak_button.dart — IELTS Hub
//
// Nút loa đọc to một từ / câu tiếng Anh bằng flutter_tts.
//
//   SpeakButton(text: word.word, color: FxColors.background)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'fx_common.dart';

class SpeakButton extends StatelessWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color = FxColors.primary,
    this.size = 36,
    this.tooltip = 'Nghe phát âm',
  });

  final String text;

  /// Thay cho cách đọc mặc định (flutter_tts), ví dụ phát file âm thanh.
  final VoidCallback? onPressed;
  final Color color;
  final double size;
  final String tooltip;

  static Future<FlutterTts>? _ready;

  static Future<FlutterTts> _init() async {
    final tts = FlutterTts();
    await tts.setLanguage('en-GB');
    // Web dùng thang 1.0 = bình thường, iOS/Android dùng 0.5 = bình thường.
    await tts.setSpeechRate(kIsWeb ? 0.9 : 0.45);
    return tts;
  }

  /// Đọc [text] bằng giọng Anh-Anh, hơi chậm cho người học. Engine chỉ được
  /// tạo ở lần bấm đầu tiên; bấm lại khi đang đọc thì đọc lại từ đầu.
  static Future<void> speak(String text) async {
    try {
      final tts = await (_ready ??= _init());
      await tts.stop();
      await tts.speak(text);
    } catch (e) {
      _ready = null;
      debugPrint('SpeakButton: không phát âm được "$text": $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed ?? () => speak(text),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
        backgroundColor: color.withAlpha(36),
        foregroundColor: color,
      ),
      icon: Icon(Icons.volume_up_rounded, size: size * 0.56),
    );
  }
}
