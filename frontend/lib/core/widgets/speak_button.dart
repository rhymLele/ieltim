// speak_button.dart — IELTS Hub
//
// Nút loa đọc to một từ / câu tiếng Anh bằng flutter_tts.
//
//   SpeakButton(text: word.word, color: FxColors.background)

import 'package:flutter/material.dart';

import '../di/service_locator.dart';
import '../services/tts_service.dart';
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

  /// Đọc [text] bằng giọng tiếng Anh tốt nhất của máy (xem [TtsService]); bấm lại khi đang đọc thì đọc lại từ đầu.
  static Future<void> speak(String text) => getSingleton<TtsService>().speak(text);

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
