// word_of_day_card.dart — IELTS Hub
//
// Card "Từ của ngày": mặt trước là từ + phiên âm, chạm để lật 3D sang mặt sau
// (nghĩa, câu ví dụ, từ đồng nghĩa, nút Lưu vào Sổ từ).
//
//   WordOfDayCard(
//     word: WordOfDayData.forDate(DateTime.now()),   // hoặc lấy từ API / Sổ từ
//     isSaved: savedIds.contains(word.word),
//     onSaveChanged: (saved) => repo.toggleSave(word, saved),
//   )
//
// Card cần chiều cao giới hạn (đặt trong Expanded hoặc SizedBox).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fx_common.dart';

class WordOfDay {
  const WordOfDay({
    required this.word,
    required this.ipa,
    required this.partOfSpeech,
    required this.meaningVi,
    required this.example,
    this.synonyms = const [],
  });

  final String word;
  final String ipa;
  final String partOfSpeech;
  final String meaningVi;
  final String example;
  final List<String> synonyms;
}

/// Bộ từ mẫu; mỗi ngày tự đổi một từ. Thay bằng dữ liệu thật của bạn.
class WordOfDayData {
  static const samples = <WordOfDay>[
    WordOfDay(
      word: 'Ubiquitous',
      ipa: '/juːˈbɪkwɪtəs/',
      partOfSpeech: 'adjective',
      meaningVi: 'có mặt ở khắp nơi, phổ biến',
      example: 'Smartphones have become ubiquitous in modern life.',
      synonyms: ['widespread', 'pervasive', 'omnipresent'],
    ),
    WordOfDay(
      word: 'Mitigate',
      ipa: '/ˈmɪtɪɡeɪt/',
      partOfSpeech: 'verb',
      meaningVi: 'giảm nhẹ, làm dịu bớt (tác hại, rủi ro)',
      example:
          'Governments should take steps to mitigate the effects of climate change.',
      synonyms: ['alleviate', 'reduce', 'lessen'],
    ),
    WordOfDay(
      word: 'Detrimental',
      ipa: '/ˌdetrɪˈmentl/',
      partOfSpeech: 'adjective',
      meaningVi: 'có hại, gây tổn hại',
      example: 'Excessive screen time can be detrimental to children’s sleep.',
      synonyms: ['harmful', 'damaging', 'adverse'],
    ),
    WordOfDay(
      word: 'Meticulous',
      ipa: '/məˈtɪkjələs/',
      partOfSpeech: 'adjective',
      meaningVi: 'tỉ mỉ, cẩn thận từng chi tiết',
      example: 'She kept meticulous notes of every new word she learned.',
      synonyms: ['thorough', 'careful', 'precise'],
    ),
    WordOfDay(
      word: 'Proliferation',
      ipa: '/prəˌlɪfəˈreɪʃn/',
      partOfSpeech: 'noun',
      meaningVi: 'sự gia tăng nhanh chóng, sự lan rộng',
      example:
          'The proliferation of online courses has made education more accessible.',
      synonyms: ['spread', 'expansion', 'increase'],
    ),
    WordOfDay(
      word: 'Resilient',
      ipa: '/rɪˈzɪliənt/',
      partOfSpeech: 'adjective',
      meaningVi: 'kiên cường, nhanh phục hồi sau khó khăn',
      example: 'Resilient learners treat mistakes as part of the process.',
      synonyms: ['tough', 'adaptable', 'hardy'],
    ),
    WordOfDay(
      word: 'Inevitable',
      ipa: '/ɪnˈevɪtəbl/',
      partOfSpeech: 'adjective',
      meaningVi: 'không thể tránh khỏi',
      example: 'Some degree of change is inevitable as cities grow.',
      synonyms: ['unavoidable', 'certain', 'inescapable'],
    ),
  ];

  static WordOfDay forDate(DateTime date) {
    final day = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(2024)).inDays;
    return samples[day % samples.length];
  }
}

class WordOfDayCard extends StatefulWidget {
  const WordOfDayCard({
    super.key,
    required this.word,
    this.isSaved = false,
    this.onSaveChanged,
    this.primary = FxColors.primary,
    this.background = FxColors.background,
  });

  final WordOfDay word;
  final bool isSaved;
  final ValueChanged<bool>? onSaveChanged;
  final Color primary;
  final Color background;

  @override
  State<WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends State<WordOfDayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  late bool _saved;

  static const _border = Color(0xFFEFDCCB);
  static const _muted = Color(0xFF6B4A4F);
  static const _soft = Color(0xFFF3D9C4);

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _flip.duration = reduce ? Duration.zero : const Duration(milliseconds: 600);
  }

  @override
  void didUpdateWidget(covariant WordOfDayCard old) {
    super.didUpdateWidget(old);
    if (old.isSaved != widget.isSaved) _saved = widget.isSaved;
    if (old.word.word != widget.word.word && _flip.value > 0) _flip.reverse();
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_flip.status == AnimationStatus.completed ||
        _flip.status == AnimationStatus.forward) {
      _flip.reverse();
    } else {
      _flip.forward();
    }
  }

  void _toggleSave() {
    setState(() => _saved = !_saved);
    widget.onSaveChanged?.call(_saved);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_flip.value);
        final angle = t * math.pi;
        final showBack = angle > math.pi / 2;
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(angle);
        return Transform(
          alignment: Alignment.center,
          transform: m,
          child: showBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _back(),
                )
              : _front(),
        );
      },
    );
  }

  Widget _front() {
    final w = widget.word;
    return Material(
      color: widget.primary,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _toggleFlip,
        child: Semantics(
          button: true,
          label: 'Từ của ngày: ${w.word}. Chạm để xem nghĩa',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TỪ CỦA NGÀY',
                  style: TextStyle(
                    color: _soft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.9,
                  ),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    w.word,
                    style: TextStyle(
                      color: widget.background,
                      fontSize: 38,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${w.ipa} · ${w.partOfSpeech}',
                  style: const TextStyle(color: _soft, fontSize: 15),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chạm để xem nghĩa',
                        style: TextStyle(
                          color: widget.background,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.flip_rounded,
                      size: 16,
                      color: widget.background,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _back() {
    final w = widget.word;
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              w.word.toUpperCase(),
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.9,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              w.meaningVi,
              style: TextStyle(
                color: widget.primary,
                fontSize: 22,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                '“${w.example}”',
                overflow: TextOverflow.fade,
                style: const TextStyle(
                  color: Color(0xFF2A1418),
                  fontSize: 14,
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (w.synonyms.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Đồng nghĩa: ${w.synonyms.join(', ')}',
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: FilledButton(
                      key: ValueKey(_saved),
                      onPressed: _toggleSave,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: _saved ? _border : widget.primary,
                        foregroundColor: _saved
                            ? widget.primary
                            : widget.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(
                        _saved ? 'Đã lưu vào Sổ từ' : 'Lưu vào Sổ từ',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _toggleFlip,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: widget.primary,
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Lật lại'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
