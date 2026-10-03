// block_view.dart — Hiển thị từng khối (dùng chung cho Doc, Slide, xem trước admin).

import 'package:flutter/material.dart';

import '../../core/app_tokens.dart';
import '../../domain/entities/weekly_doc.dart';

/// Cỡ chữ / khoảng cách theo ngữ cảnh hiển thị (bảng mục 6 file 5).
class BlockScale {
  const BlockScale({required this.heading, required this.body, required this.small, required this.eyebrow, required this.gap, this.compactVocab = true});

  final double heading;
  final double body;
  final double small;
  final double eyebrow;
  final double gap;

  /// true = mỗi từ vựng xếp 2 dòng (mobile); false = 3 cột (desktop).
  final bool compactVocab;

  static const docMobile = BlockScale(heading: 24, body: 15, small: 13, eyebrow: 11, gap: 14);
  static const docDesktop = BlockScale(heading: 26, body: 16, small: 14, eyebrow: 12, gap: 14, compactVocab: false);
  static const slideMobile = BlockScale(heading: 24, body: 15, small: 13, eyebrow: 11, gap: 14);
  static const slideWide = BlockScale(heading: 34, body: 18, small: 15, eyebrow: 13, gap: 16, compactVocab: false);
  static const previewSlide = BlockScale(heading: 19, body: 12.5, small: 11, eyebrow: 10, gap: 10);
  static const previewDoc = BlockScale(heading: 16, body: 12, small: 11, eyebrow: 10, gap: 10);
}

/// Trạng thái trắc nghiệm + callback, truyền xuống các khối quiz.
class QuizState {
  const QuizState({this.answers = const {}, this.onAnswer, this.revealAnswer = false});

  /// blockKey → đáp án đã chọn.
  final Map<String, int> answers;

  /// null = chỉ xem (không bấm được).
  final void Function(String key, int option)? onAnswer;

  /// Xem trước admin: tô sẵn đáp án đúng.
  final bool revealAnswer;
}

class BlockView extends StatelessWidget {
  const BlockView({super.key, required this.block, required this.blockKey, required this.scale, this.quiz = const QuizState(), this.highlighted = false, this.trailingForVocab});

  final DocBlock block;
  final String blockKey;
  final BlockScale scale;
  final QuizState quiz;

  /// Admin: tô viền vàng khối đang sửa.
  final bool highlighted;

  /// Gắn thêm widget cuối mỗi dòng từ vựng (ví dụ nút phát âm).
  final Widget Function(VocabItem item)? trailingForVocab;

  @override
  Widget build(BuildContext context) {
    final child = switch (block) {
      HeadingBlock b => Text(
        b.text,
        style: TextStyle(fontSize: scale.heading, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.02 * scale.heading, color: AppColors.textInk),
      ),
      ParagraphBlock b => RichTextLite(
        b.text,
        style: TextStyle(fontSize: scale.body, height: 1.6, color: AppColors.textInk),
      ),
      CalloutBlock b => _Callout(block: b, scale: scale),
      StepsBlock b => _Steps(block: b, scale: scale),
      PassageBlock b => _Passage(block: b, scale: scale),
      QuizBlock b => _Quiz(block: b, blockKey: blockKey, scale: scale, state: quiz),
      VocabBlock b => _Vocab(block: b, scale: scale, trailing: trailingForVocab),
      PatternBlock b => _Pattern(block: b, scale: scale),
      ImageBlock b => _Image(block: b, scale: scale),
      SlideBreakBlock _ => const SizedBox.shrink(),
      UnknownBlock _ => _Unknown(scale: scale),
    };
    if (!highlighted) return child;
    return AnimatedContainer(
      duration: motion(context, 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: const [
          BoxShadow(color: AppColors.highlightRing, spreadRadius: 2),
          BoxShadow(color: AppColors.highlightGlow, spreadRadius: 5),
        ],
      ),
      child: child,
    );
  }
}

// ───────────────────────────── Markdown rút gọn ─────────────────────────────

/// Hỗ trợ **đậm** (w800, màu primary), *nghiêng*, [chữ](https://…).
class RichTextLite extends StatelessWidget {
  const RichTextLite(this.text, {super.key, required this.style, this.boldColor = AppColors.primary});
  final String text;
  final TextStyle style;
  final Color boldColor;

  static final _re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|\[([^\]]+)\]\((https?://[^\s)]+)\)');

  static List<InlineSpan> parse(String text, TextStyle base, Color boldColor) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _re.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      if (m.group(1) != null) {
        spans.add(
          TextSpan(
            text: m.group(1),
            style: TextStyle(fontWeight: FontWeight.w800, color: boldColor),
          ),
        );
      } else if (m.group(2) != null) {
        spans.add(
          TextSpan(
            text: m.group(2),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else {
        // Link: hiển thị gạch chân. Mở link bằng url_launcher ở tầng app nếu cần.
        spans.add(
          TextSpan(
            text: m.group(3),
            style: TextStyle(color: boldColor, decoration: TextDecoration.underline),
          ),
        );
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(style: style, children: parse(text, style, boldColor)));
}

// ───────────────────────────── Các khối ─────────────────────────────

class _Callout extends StatelessWidget {
  const _Callout({required this.block, required this.scale});
  final CalloutBlock block;
  final BlockScale scale;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = switch (block.tone) {
      'warning' => (AppColors.errorBg, AppColors.primary, Icons.warning_amber_rounded, 'Lưu ý: '),
      'note' => (AppColors.sidebar, AppColors.textInk, Icons.info_outline_rounded, 'Ghi chú: '),
      _ => (AppColors.tipBg, AppColors.tipText, Icons.lightbulb_outline_rounded, 'Mẹo: '),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: scale.body, vertical: scale.body * 0.85),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: scale.body + 4, color: block.tone == 'tip' ? AppColors.tipIcon : fg),
          ),
          SizedBox(width: scale.body * 0.75),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: scale.body * 0.95, height: 1.55, color: fg),
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  ...RichTextLite.parse(block.text, const TextStyle(), fg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.block, required this.scale});
  final StepsBlock block;
  final BlockScale scale;

  @override
  Widget build(BuildContext context) {
    final box = scale.body * 1.75;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < block.items.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : scale.gap * 0.7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: box,
                  height: box,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.sidebar, borderRadius: BorderRadius.circular(box * 0.3)),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(color: AppColors.primary, fontSize: scale.body * 0.85, fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(width: scale.body * 0.7),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: RichTextLite(
                      block.items[i],
                      style: TextStyle(fontSize: scale.body, height: 1.5, color: AppColors.textInk),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Passage extends StatelessWidget {
  const _Passage({required this.block, required this.scale});
  final PassageBlock block;
  final BlockScale scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: scale.body * 1.1, vertical: scale.body),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.label != null) ...[
            Text(
              block.label!.toUpperCase(),
              style: TextStyle(color: AppColors.primary, fontSize: scale.eyebrow, fontWeight: FontWeight.w800, letterSpacing: scale.eyebrow * 0.12),
            ),
            SizedBox(height: scale.gap * 0.45),
          ],
          Text(
            block.text,
            style: TextStyle(fontFamily: AppText.serif, fontSize: scale.body, height: 1.65, color: AppColors.textInk),
          ),
        ],
      ),
    );
  }
}

class _Quiz extends StatelessWidget {
  const _Quiz({required this.block, required this.blockKey, required this.scale, required this.state});
  final QuizBlock block;
  final String blockKey;
  final BlockScale scale;
  final QuizState state;

  @override
  Widget build(BuildContext context) {
    final chosen = state.answers[blockKey];
    final answered = chosen != null;
    final right = answered && chosen == block.answer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          block.question,
          style: TextStyle(fontSize: scale.body, fontWeight: FontWeight.w800, color: AppColors.textInk),
        ),
        SizedBox(height: scale.gap * 0.6),
        for (var i = 0; i < block.options.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: scale.gap * 0.5),
            child: _QuizOption(block: block, blockKey: blockKey, index: i, chosen: chosen, scale: scale, state: state),
          ),
        if (answered && block.explain != null)
          AnimatedSwitcher(
            duration: motion(context, 200),
            child: Container(
              key: ValueKey(chosen),
              padding: EdgeInsets.symmetric(horizontal: scale.body * 0.85, vertical: scale.body * 0.7),
              decoration: BoxDecoration(color: right ? AppColors.successBg : AppColors.errorBg, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: scale.small, height: 1.55, color: AppColors.textInk),
                  children: [
                    TextSpan(
                      text: right ? 'Chính xác! ' : 'Chưa đúng. ',
                      style: TextStyle(fontWeight: FontWeight.w800, color: right ? AppColors.success : AppColors.primary),
                    ),
                    TextSpan(text: block.explain),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Một đáp án của câu trắc nghiệm: tô xanh đáp án đúng, đỏ lựa chọn sai.
class _QuizOption extends StatelessWidget {
  const _QuizOption({required this.block, required this.blockKey, required this.index, required this.chosen, required this.scale, required this.state});
  final QuizBlock block;
  final String blockKey;
  final int index;
  final int? chosen;
  final BlockScale scale;
  final QuizState state;

  @override
  Widget build(BuildContext context) {
    final i = index;
    final answered = chosen != null;
    final onAnswer = state.onAnswer;
    final isAnswer = i == block.answer;
    final good = (answered || state.revealAnswer) && isAnswer;
    final bad = answered && i == chosen && !isAnswer;
    final bg = good ? AppColors.successBg : (bad ? AppColors.errorBg : AppColors.cardSurface);
    final border = good ? AppColors.success : (bad ? AppColors.primary : AppColors.borderLight);
    final badgeBg = good ? AppColors.success : (bad ? AppColors.primary : AppColors.sidebar);
    final badgeFg = good || bad ? AppColors.white : AppColors.primary;
    final mark = answered ? (good ? 'Đáp án' : (bad ? 'Bạn chọn' : null)) : null;
    final badge = scale.body * 1.7;
    return Semantics(
      button: state.onAnswer != null,
      selected: i == chosen,
      label: '${romanKeys.length > i ? romanKeys[i] : i + 1}. ${block.options[i]}${good && answered ? ', đáp án đúng' : ''}${bad ? ', bạn chọn, chưa đúng' : ''}',
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onAnswer == null ? null : () => onAnswer(blockKey, i),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: scale.body >= 14 ? 48 : 30),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: scale.body * 0.8, vertical: scale.body * 0.45),
              child: Row(
                children: [
                  Container(
                    width: badge,
                    height: badge,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                    child: Text(
                      romanKeys.length > i ? romanKeys[i] : '${i + 1}',
                      style: TextStyle(color: badgeFg, fontSize: scale.body * 0.75, fontWeight: FontWeight.w800),
                    ),
                  ),
                  SizedBox(width: scale.body * 0.7),
                  Expanded(
                    child: Text(
                      block.options[i],
                      style: TextStyle(fontSize: scale.body * 0.95, color: AppColors.textInk),
                    ),
                  ),
                  if (mark != null)
                    Text(
                      mark,
                      style: TextStyle(fontSize: scale.small, fontWeight: FontWeight.w800, color: good ? AppColors.success : AppColors.primary),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Vocab extends StatelessWidget {
  const _Vocab({required this.block, required this.scale, this.trailing});
  final VocabBlock block;
  final BlockScale scale;
  final Widget Function(VocabItem item)? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < block.items.length; i++)
            Container(
              padding: EdgeInsets.symmetric(horizontal: scale.body, vertical: scale.body * 0.65),
              decoration: BoxDecoration(
                border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: scale.compactVocab ? _VocabItemStacked(item: block.items[i], scale: scale) : _VocabItemColumns(item: block.items[i], scale: scale),
                  ),
                  if (trailing != null) trailing!(block.items[i]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Từ vựng dạng xếp dọc (slide, màn hẹp).
class _VocabItemStacked extends StatelessWidget {
  const _VocabItemStacked({required this.item, required this.scale});
  final VocabItem item;
  final BlockScale scale;

  @override
  Widget build(BuildContext context) {
    final v = item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 8,
          children: [
            Text(
              v.word,
              style: TextStyle(fontSize: scale.body, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
            Text(
              [v.pos, v.ipa].whereType<String>().join(' '),
              style: TextStyle(fontSize: scale.small - 1, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          v.meaning,
          style: TextStyle(fontSize: scale.body * 0.93, color: AppColors.textInk),
        ),
      ],
    );
  }
}

/// Từ vựng dạng cột: từ · phiên âm · nghĩa (màn rộng).
class _VocabItemColumns extends StatelessWidget {
  const _VocabItemColumns({required this.item, required this.scale});
  final VocabItem item;
  final BlockScale scale;

  @override
  Widget build(BuildContext context) {
    final v = item;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 150,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: v.word,
                  style: TextStyle(fontSize: scale.body, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                if (v.pos != null)
                  TextSpan(
                    text: '  ${v.pos}',
                    style: TextStyle(fontSize: scale.small - 1, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 130,
          child: Text(
            v.ipa ?? '',
            style: TextStyle(fontSize: scale.small, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            v.meaning,
            style: TextStyle(fontSize: scale.body, color: AppColors.textInk),
          ),
        ),
      ],
    );
  }
}

class _Pattern extends StatelessWidget {
  const _Pattern({required this.block, required this.scale});
  final PatternBlock block;
  final BlockScale scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: scale.body, vertical: scale.body * 0.85),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MẪU CÂU',
            style: TextStyle(fontSize: scale.eyebrow - 1, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppColors.softOnPrimary),
          ),
          SizedBox(height: scale.gap * 0.3),
          Text(
            block.structure,
            style: TextStyle(fontSize: scale.body, fontWeight: FontWeight.w800, color: AppColors.onPrimary),
          ),
          if (block.example != null) ...[
            const SizedBox(height: 2),
            Text(
              block.example!,
              style: TextStyle(fontSize: scale.small, fontStyle: FontStyle.italic, color: AppColors.softOnPrimary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Image extends StatelessWidget {
  const _Image({required this.block, required this.scale});
  final ImageBlock block;
  final BlockScale scale;

  @override
  Widget build(BuildContext context) {
    final valid = Uri.tryParse(block.url)?.hasAuthority ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: valid
              ? GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => Dialog(
                      child: InteractiveViewer(child: Image.network(block.url, semanticLabel: block.alt)),
                    ),
                  ),
                  child: Image.network(
                    block.url,
                    semanticLabel: block.alt,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => _ImagePlaceholder(scale: scale),
                    loadingBuilder: (c, child, p) => p == null ? child : _ImagePlaceholder(scale: scale),
                  ),
                )
              : _ImagePlaceholder(scale: scale),
        ),
        if ((block.caption ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            block.caption!,
            style: TextStyle(fontSize: scale.small, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

/// Khung xám khi ảnh đang tải, lỗi hoặc chưa có link.
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.scale});
  final BlockScale scale;

  @override
  Widget build(BuildContext context) => Container(
    height: scale.body * 10,
    color: AppColors.sidebar,
    alignment: Alignment.center,
    child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
  );
}

class _Unknown extends StatelessWidget {
  const _Unknown({required this.scale});
  final BlockScale scale;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(color: AppColors.archivedBg, borderRadius: BorderRadius.circular(AppRadius.md)),
    child: Text(
      'Nội dung chưa hỗ trợ, hãy cập nhật app',
      style: TextStyle(fontSize: scale.small, color: AppColors.textMuted),
    ),
  );
}
