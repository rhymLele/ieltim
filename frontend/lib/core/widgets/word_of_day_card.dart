// word_of_day_card.dart — IELTS Hub
//
// Card "Từ của ngày"
// Mặt trước: con dấu ngày, chủ đề, từ + nút loa (SpeakButton) + phiên âm,
//            nhãn (Band 7+, Writing…), họa tiết sóng seigaiha + cá chép vàng
//            bơi, chấm tiến độ tuần.
// Mặt sau:   nút loa ở góc phải, nghĩa, câu ví dụ (tô sáng từ), collocations, họ từ,
//            đồng nghĩa, nút Lưu vào Sổ từ. Chạm vào thẻ để lật lại.
//
//   WordOfDayCard(
//     word: WordOfDayData.forDate(DateTime.now()),
//     learnedThisWeek: 4,                       // null = ẩn dãy chấm
//     isSaved: saved,
//     onSaveChanged: (v) => repo.toggleSave(word, v),
//     onSpeak: () => player.play(word.audio),   // null = đọc bằng flutter_tts
//   )
//
// Card cần chiều cao giới hạn (đặt trong Expanded hoặc SizedBox, khuyên ≥ 380 px).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fx_common.dart';
import 'speak_button.dart';

class WordOfDay {
  const WordOfDay({
    required this.word,
    required this.ipa,
    required this.partOfSpeech,
    required this.meaningVi,
    required this.example,
    this.synonyms = const [],
    this.topic,
    this.tags = const [],
    this.collocations = const [],
    this.wordFamily = const [],
  });

  final String word;
  final String ipa;
  final String partOfSpeech;
  final String meaningVi;
  final String example;
  final List<String> synonyms;

  /// Ví dụ: 'Technology'.
  final String? topic;

  /// Nhãn nhỏ ở mặt trước, ví dụ ['Band 7+', 'Writing Task 2', 'Học thuật'].
  final List<String> tags;
  final List<String> collocations;

  /// Ví dụ ['ubiquity (n.)', 'ubiquitously (adv.)'].
  final List<String> wordFamily;
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
      synonyms: ['widespread', 'pervasive'],
      topic: 'Technology',
      tags: ['Band 7+', 'Writing Task 2', 'Học thuật'],
      collocations: [
        'become ubiquitous',
        'ubiquitous technology',
        'virtually ubiquitous',
      ],
      wordFamily: ['ubiquity (n.)', 'ubiquitously (adv.)'],
    ),
    WordOfDay(
      word: 'Mitigate',
      ipa: '/ˈmɪtɪɡeɪt/',
      partOfSpeech: 'verb',
      meaningVi: 'giảm nhẹ, làm dịu bớt (tác hại, rủi ro)',
      example:
          'Governments should take steps to mitigate the effects of climate change.',
      synonyms: ['alleviate', 'lessen'],
      topic: 'Environment',
      tags: ['Band 7+', 'Writing Task 2', 'Học thuật'],
      collocations: [
        'mitigate the effects',
        'mitigate the risk',
        'help mitigate',
      ],
      wordFamily: ['mitigation (n.)', 'mitigating (adj.)'],
    ),
    WordOfDay(
      word: 'Detrimental',
      ipa: '/ˌdetrɪˈmentl/',
      partOfSpeech: 'adjective',
      meaningVi: 'có hại, gây tổn hại',
      example: 'Excessive screen time can be detrimental to children’s sleep.',
      synonyms: ['harmful', 'damaging'],
      topic: 'Health',
      tags: ['Band 7+', 'Writing Task 2'],
      collocations: [
        'detrimental to',
        'detrimental effect',
        'potentially detrimental',
      ],
      wordFamily: ['detriment (n.)', 'detrimentally (adv.)'],
    ),
    WordOfDay(
      word: 'Meticulous',
      ipa: '/məˈtɪkjələs/',
      partOfSpeech: 'adjective',
      meaningVi: 'tỉ mỉ, cẩn thận từng chi tiết',
      example: 'She kept meticulous notes of every new word she learned.',
      synonyms: ['thorough', 'precise'],
      topic: 'Work & Study',
      tags: ['Band 7+', 'Speaking'],
      collocations: [
        'meticulous attention',
        'meticulous planning',
        'meticulous records',
      ],
      wordFamily: ['meticulously (adv.)', 'meticulousness (n.)'],
    ),
    WordOfDay(
      word: 'Proliferation',
      ipa: '/prəˌlɪfəˈreɪʃn/',
      partOfSpeech: 'noun',
      meaningVi: 'sự gia tăng nhanh chóng, sự lan rộng',
      example:
          'The proliferation of online courses has made education more accessible.',
      synonyms: ['spread', 'expansion'],
      topic: 'Education',
      tags: ['Band 8', 'Writing Task 2', 'Học thuật'],
      collocations: [
        'rapid proliferation',
        'the proliferation of',
        'nuclear proliferation',
      ],
      wordFamily: ['proliferate (v.)', 'proliferating (adj.)'],
    ),
    WordOfDay(
      word: 'Resilient',
      ipa: '/rɪˈzɪliənt/',
      partOfSpeech: 'adjective',
      meaningVi: 'kiên cường, nhanh phục hồi sau khó khăn',
      example: 'Resilient learners treat mistakes as part of the process.',
      synonyms: ['tough', 'adaptable'],
      topic: 'Personality',
      tags: ['Band 7+', 'Speaking'],
      collocations: [
        'remarkably resilient',
        'resilient economy',
        'resilient to',
      ],
      wordFamily: ['resilience (n.)', 'resiliently (adv.)'],
    ),
    WordOfDay(
      word: 'Inevitable',
      ipa: '/ɪnˈevɪtəbl/',
      partOfSpeech: 'adjective',
      meaningVi: 'không thể tránh khỏi',
      example: 'Some degree of change is inevitable as cities grow.',
      synonyms: ['unavoidable', 'inescapable'],
      topic: 'Society',
      tags: ['Band 7+', 'Writing Task 2'],
      collocations: [
        'almost inevitable',
        'inevitable consequence',
        'seem inevitable',
      ],
      wordFamily: ['inevitably (adv.)', 'inevitability (n.)'],
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
    this.onSpeak,
    this.learnedThisWeek,
    this.weekTotal = 7,
    this.date,
    this.primary = FxColors.primary,
    this.background = FxColors.background,
  });

  final WordOfDay word;
  final bool isSaved;
  final ValueChanged<bool>? onSaveChanged;

  /// Bấm nút loa (cả hai mặt). null = đọc từ bằng flutter_tts.
  final VoidCallback? onSpeak;

  /// Số từ đã học trong tuần (hiện dãy chấm). null = ẩn.
  final int? learnedThisWeek;
  final int weekTotal;

  /// Ngày in trên con dấu (mặc định hôm nay).
  final DateTime? date;
  final Color primary;
  final Color background;

  @override
  State<WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends State<WordOfDayCard>
    with TickerProviderStateMixin {
  late final AnimationController _flip;
  late final AnimationController _swim;
  late bool _saved;
  bool _reduceMotion = false;

  static const _border = Color(0xFFEFDCCB);
  static const _muted = Color(0xFF6B4A4F);
  static const _ink = Color(0xFF2A1418);
  static const _soft = Color(0xFFF3D9C4);
  static const _highlight = Color(0xFFF7D9A8);

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((_) => _syncSwim());
    _swim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _flip.duration = _reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 600);
    _syncSwim();
  }

  /// Cá chỉ bơi khi mặt trước đang hiện hẳn: lúc lật hoặc xem mặt sau thì
  /// dừng để không phải vẽ lại mỗi khung hình.
  void _syncSwim() {
    if (_reduceMotion || !_flip.isDismissed) {
      _swim.stop();
    } else if (!_swim.isAnimating) {
      _swim.repeat();
    }
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
    _swim.dispose();
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
    // Hai mặt được dựng một lần mỗi lần build (không phải mỗi khung hình lật)
    // và nằm sau RepaintBoundary, nên khi lật chỉ có ma trận xoay thay đổi.
    final front = RepaintBoundary(child: _front());
    final back = Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
      child: RepaintBoundary(child: _back()),
    );
    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final angle = Curves.easeInOutCubic.transform(_flip.value) * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: IndexedStack(
            index: angle > math.pi / 2 ? 1 : 0,
            sizing: StackFit.expand,
            children: [front, back],
          ),
        );
      },
    );
  }

  // ───────────────────────────── Mặt trước ─────────────────────────────

  Widget _front() {
    final w = widget.word;
    final date = widget.date ?? DateTime.now();
    const pad = EdgeInsets.symmetric(horizontal: 20);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: pad,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
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
                          if (w.topic != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Chủ đề: ${w.topic}',
                              style: const TextStyle(
                                color: Color(0xFFE9BFB0),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _DateSeal(date: date),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: pad,
                child: Row(
                  children: [
                    Flexible(
                      child: FittedBox(
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
                    ),
                    const SizedBox(width: 10),
                    // Nút loa tự nhận chạm nên không làm thẻ lật.
                    SpeakButton(
                      text: w.word,
                      onPressed: widget.onSpeak,
                      color: widget.background,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: pad,
                child: Text(
                  '${w.ipa} · ${w.partOfSpeech}',
                  style: const TextStyle(color: _soft, fontSize: 15),
                ),
              ),
              if (w.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: pad,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < w.tags.length; i++)
                        _Chip(
                          text: w.tags[i],
                          fill: i == w.tags.length - 1 && w.tags.length > 2
                              ? FxColors.gold.withAlpha(56)
                              : widget.background.withAlpha(36),
                          color: i == w.tags.length - 1 && w.tags.length > 2
                              ? _highlight
                              : widget.background,
                        ),
                    ],
                  ),
                ),
              ],
              // Dải sóng seigaiha + cá chép vàng. Sóng tĩnh vẽ một lần rồi
              // cache; chỉ lớp cá vẽ lại theo từng khung hình.
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        isComplex: true,
                        painter: _SeigaihaPainter(
                          primary: widget.primary,
                          cream: widget.background,
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: _SwimmingKoiPainter(
                          swim: _swim,
                          cream: widget.background,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.learnedThisWeek != null)
                Padding(
                  padding: pad,
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.weekTotal; i++) ...[
                        _WeekDot(
                          filled: i < widget.learnedThisWeek!,
                          today: i == widget.learnedThisWeek! - 1,
                          ring: widget.primary,
                        ),
                        const SizedBox(width: 5),
                      ],
                      const Spacer(),
                      Text(
                        '${widget.learnedThisWeek}/${widget.weekTotal} từ tuần này',
                        style: const TextStyle(color: _soft, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Padding(
                padding: pad,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Chạm để xem nghĩa',
                        overflow: TextOverflow.ellipsis,
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
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── Mặt sau ─────────────────────────────

  Widget _back() {
    final w = widget.word;
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      // Chạm vào bất kỳ đâu trên mặt sau để lật lại; nút Lưu / loa tự nhận
      // chạm của chúng nên không làm thẻ lật.
      child: InkWell(
        onTap: _toggleFlip,
        child: Stack(
          children: [
            const Positioned(
              right: -10,
              bottom: 56,
              width: 140,
              height: 90,
              child: IgnorePointer(
                child: CustomPaint(painter: _LotusPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${w.word.toUpperCase()} · ${_short(w.partOfSpeech)}',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.9,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SpeakButton(
                        text: w.word,
                        onPressed: widget.onSpeak,
                        color: widget.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.meaningVi,
                            style: TextStyle(
                              color: widget.primary,
                              fontSize: 21,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text.rich(
                            _highlightExample(w.example, w.word),
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 14,
                              height: 1.55,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (w.collocations.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'COLLOCATIONS',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final c in w.collocations)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.background,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: _border),
                                    ),
                                    child: Text(
                                      c,
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          if (w.wordFamily.isNotEmpty ||
                              w.synonyms.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text.rich(
                              TextSpan(
                                children: [
                                  if (w.wordFamily.isNotEmpty) ...[
                                    const TextSpan(
                                      text: 'Họ từ: ',
                                      style: TextStyle(
                                        color: _ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: w.wordFamily.join(' · ')),
                                  ],
                                  if (w.wordFamily.isNotEmpty &&
                                      w.synonyms.isNotEmpty)
                                    const TextSpan(text: '\n'),
                                  if (w.synonyms.isNotEmpty) ...[
                                    const TextSpan(
                                      text: 'Đồng nghĩa: ',
                                      style: TextStyle(
                                        color: _ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: w.synonyms.join(', ')),
                                  ],
                                ],
                              ),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
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
                    child: Text(_saved ? 'Đã lưu vào Sổ từ' : 'Lưu vào Sổ từ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _short(String pos) {
    switch (pos.toLowerCase()) {
      case 'adjective':
        return 'ADJ';
      case 'adverb':
        return 'ADV';
      case 'noun':
        return 'N';
      case 'verb':
        return 'V';
      default:
        return pos.toUpperCase();
    }
  }

  /// Câu ví dụ trong ngoặc kép, tô sáng chỗ xuất hiện đầu tiên của từ.
  TextSpan _highlightExample(String example, String word) {
    final i = example.toLowerCase().indexOf(word.toLowerCase());
    if (i < 0) return TextSpan(text: '“$example”');
    return TextSpan(
      children: [
        TextSpan(text: '“${example.substring(0, i)}'),
        TextSpan(
          text: example.substring(i, i + word.length),
          style: TextStyle(
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w800,
            color: widget.primary,
            background: Paint()..color = _highlight,
          ),
        ),
        TextSpan(text: '${example.substring(i + word.length)}”'),
      ],
    );
  }
}

// ───────────────────────────── Thành phần nhỏ ─────────────────────────────

class _DateSeal extends StatelessWidget {
  const _DateSeal({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -8 * math.pi / 180,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: FxColors.gold, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: FxColors.goldLight,
                fontSize: 16,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'TH${date.month}',
              style: const TextStyle(
                color: FxColors.goldLight,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.fill, required this.color});
  final String text;
  final Color fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WeekDot extends StatelessWidget {
  const _WeekDot({
    required this.filled,
    required this.today,
    required this.ring,
  });
  final bool filled;
  final bool today;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? FxColors.goldLight : null,
        border: filled
            ? null
            : Border.all(color: const Color(0x73FFF9F2), width: 1.5),
      ),
    );
    if (!today) return dot;
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: FxColors.goldLight, width: 1.5),
      ),
      child: dot,
    );
  }
}

/// Họa tiết sóng seigaiha mờ dần lên trên. Tĩnh: chỉ vẽ lại khi đổi màu.
class _SeigaihaPainter extends CustomPainter {
  const _SeigaihaPainter({required this.primary, required this.cream});
  final Color primary;
  final Color cream;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    canvas.saveLayer(rect, Paint());
    final fill = Paint()..color = primary;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = cream.withAlpha(41);
    var row = 0;
    for (var y = 0.0; y < size.height + 20; y += 10, row++) {
      final ox = row.isEven ? 0.0 : 20.0;
      for (var x = -40.0 + ox; x < size.width + 40; x += 40) {
        final c = Offset(x, y);
        canvas.drawCircle(c, 19, fill);
        canvas.drawCircle(c, 19, ring);
        canvas.drawCircle(c, 13, ring);
        canvas.drawCircle(c, 7, ring);
      }
    }
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
          stops: const [0.0, 0.7],
        ).createShader(rect),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SeigaihaPainter old) =>
      old.primary != primary || old.cream != cream;
}

/// Cá chép vàng bơi theo vòng lượn trên dải sóng.
class _SwimmingKoiPainter extends CustomPainter {
  _SwimmingKoiPainter({required this.swim, required this.cream})
    : super(repaint: swim);
  final Animation<double> swim;
  final Color cream;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final th = swim.value * 2 * math.pi;
    final cx = size.width * 0.5, cy = size.height * 0.5;
    final ax = size.width * 0.33, ay = size.height * 0.22;
    final pos = Offset(
      cx + ax * math.cos(th),
      cy + ay * math.sin(th) + 6 * math.sin(3 * th),
    );
    final vel = Offset(
      -ax * math.sin(th),
      ay * math.cos(th) + 18 * math.cos(3 * th),
    );
    final heading = math.atan2(vel.dy, vel.dx);
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(heading);
    canvas.scale(0.6);
    paintKoi(
      canvas,
      fins: false,
      spots: [KoiSpot(const Offset(18, -1), 18, 10, cream)],
      tailAngle: math.sin(th * 30) * 0.38,
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SwimmingKoiPainter old) =>
      old.cream != cream || old.swim != swim;
}

/// Sóng nước + bông sen nhạt ở góc mặt sau.
class _LotusPainter extends CustomPainter {
  const _LotusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 140, size.height / 90);
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x80EFDCCB);
    canvas.drawPath(
      Path()
        ..moveTo(0, 70)
        ..cubicTo(20, 60, 40, 80, 60, 70)
        ..cubicTo(80, 60, 100, 80, 120, 70)
        ..cubicTo(130, 65, 135, 67, 140, 70)
        ..moveTo(10, 84)
        ..cubicTo(30, 74, 50, 94, 70, 84)
        ..cubicTo(90, 74, 110, 94, 130, 84),
      wave,
    );
    canvas.drawPath(
      Path()
        ..moveTo(92, 50)
        ..cubicTo(86, 38, 90, 26, 100, 20)
        ..cubicTo(110, 26, 114, 38, 108, 50)
        ..close(),
      Paint()..color = const Color(0x80F4C7CF),
    );
    canvas.drawPath(
      Path()
        ..moveTo(100, 52)
        ..cubicTo(92, 46, 82, 44, 76, 46)
        ..cubicTo(80, 54, 90, 56, 100, 52)
        ..close()
        ..moveTo(100, 52)
        ..cubicTo(108, 46, 118, 44, 124, 46)
        ..cubicTo(120, 54, 110, 56, 100, 52)
        ..close(),
      Paint()..color = const Color(0x80F9DDE2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LotusPainter old) => false;
}
