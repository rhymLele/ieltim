// pronunciation.dart — IELTS Hub
//
// Phát âm từ vựng bằng giọng đọc có sẵn của máy (Android, iOS, web, macOS, Windows).
// Cần package flutter_tts:   flutter pub add flutter_tts
//
//   SpeakButton(text: 'ubiquitous')                     // giọng Anh-Anh
//   SpeakButton(text: 'ubiquitous', lang: 'en-US', label: 'US')
//   WordSpeaker.instance.speak('mitigate', slow: true)   // gọi trực tiếp
//
// Chạm: đọc bình thường. Nhấn giữ: đọc chậm. Chạm khi đang đọc: dừng.
//
// iOS: nếu muốn phát cả khi máy để chế độ im lặng, gọi thêm
//   FlutterTts().setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [...])
// Android 11+: thêm vào AndroidManifest.xml trong <queries>:
//   <intent><action android:name="android.intent.action.TTS_SERVICE" /></intent>

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'fx_common.dart';

class WordSpeaker {
  WordSpeaker._();
  static final WordSpeaker instance = WordSpeaker._();

  final FlutterTts _tts = FlutterTts();

  /// Khoá của lượt đang đọc ("lang|text"), null khi im lặng.
  final ValueNotifier<String?> speaking = ValueNotifier<String?>(null);
  bool _ready = false;

  static String keyOf(String text, String lang) => '$lang|$text';

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() => speaking.value = null);
    _tts.setCancelHandler(() => speaking.value = null);
    _tts.setErrorHandler((_) => speaking.value = null);
  }

  Future<void> speak(
    String text, {
    String lang = 'en-GB',
    bool slow = false,
  }) async {
    await _init();
    await _tts.stop();
    await _tts.setLanguage(lang);
    // flutter_tts: 0.5 ≈ tốc độ bình thường.
    await _tts.setSpeechRate(slow ? 0.28 : 0.45);
    speaking.value = keyOf(text, lang);
    final result = await _tts.speak(text);
    if (result != 1 && speaking.value == keyOf(text, lang)) {
      // Một số nền tảng không gọi completion; tự tắt trạng thái sau khi đọc xong.
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (speaking.value == keyOf(text, lang)) speaking.value = null;
      });
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    speaking.value = null;
  }
}

/// Nút loa tròn (hoặc viên thuốc khi có [label]); có vòng sóng lan ra khi đang đọc.
class SpeakButton extends StatefulWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.lang = 'en-GB',
    this.label,
    this.size = 36,
    this.color = FxColors.primary,
    this.fill = FxColors.background,
    this.borderColor = const Color(0xFFEFDCCB),
    this.onPressed,
  });

  final String text;
  final String lang;

  /// Ví dụ 'UK', 'US'. null = nút tròn chỉ có icon.
  final String? label;
  final double size;
  final Color color;
  final Color fill;
  final Color? borderColor;

  /// Ghi đè hành vi mặc định (ví dụ bạn tự phát file audio).
  final VoidCallback? onPressed;

  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final _speaker = WordSpeaker.instance;

  String get _key => WordSpeaker.keyOf(widget.text, widget.lang);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _speaker.speaking.addListener(_onSpeaking);
  }

  @override
  void dispose() {
    _speaker.speaking.removeListener(_onSpeaking);
    _pulse.dispose();
    super.dispose();
  }

  bool get _active => _speaker.speaking.value == _key;

  void _onSpeaking() {
    if (!mounted) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_active && !reduce) {
      _pulse.repeat();
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
    setState(() {});
  }

  void _tap({bool slow = false}) {
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }
    if (_active && !slow) {
      _speaker.stop();
    } else {
      _speaker.speak(widget.text, lang: widget.lang, slow: slow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final s = widget.size;
    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Icon(
        active ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
        key: ValueKey(active),
        size: s * 0.5,
        color: widget.color,
      ),
    );
    final hasLabel = widget.label != null;
    final shape = hasLabel
        ? StadiumBorder(side: _side())
        : CircleBorder(side: _side());

    final button = Material(
      color: active
          ? Color.alphaBlend(widget.color.withAlpha(24), widget.fill)
          : widget.fill,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: _tap,
        onLongPress: () => _tap(slow: true),
        child: SizedBox(
          height: s,
          width: hasLabel ? null : s,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hasLabel ? 10 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                if (hasLabel) ...[
                  const SizedBox(width: 4),
                  Text(
                    widget.label!,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: 'Nghe phát âm ${widget.label ?? ''}'.trim(),
      child: Tooltip(
        message:
            'Nghe phát âm${widget.label != null ? ' (${widget.label})' : ''} · nhấn giữ để nghe chậm',
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = _pulse.value;
            return CustomPaint(
              painter: active
                  ? _PulsePainter(t: t, color: widget.color, stadium: hasLabel)
                  : null,
              child: child,
            );
          },
          child: button,
        ),
      ),
    );
  }

  BorderSide _side() => widget.borderColor == null
      ? BorderSide.none
      : BorderSide(color: widget.borderColor!);
}

/// Hai vòng sóng lan ra quanh nút khi đang đọc.
class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.t, required this.color, required this.stadium});
  final double t;
  final Color color;
  final bool stadium;

  @override
  void paint(Canvas canvas, Size size) {
    for (final phase in const [0.0, 0.5]) {
      final k = (t + phase) % 1.0;
      final grow = 1 + k * 0.45;
      final alpha = ((1 - k) * 110).round();
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withAlpha(alpha);
      final r = Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width + (grow - 1) * size.height,
        height: size.height * grow,
      );
      if (stadium) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(r.height / 2)),
          paint,
        );
      } else {
        canvas.drawOval(r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) =>
      old.t != t || old.color != color;
}
