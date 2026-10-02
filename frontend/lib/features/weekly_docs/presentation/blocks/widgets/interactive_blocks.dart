import 'package:flutter/material.dart';

import '../../../../../core/theme/brand_colors.dart';
import '../../../../../core/widgets/speak_button.dart';
import '../../../domain/models/weekly_doc.dart';
import '../block_context.dart';
import '../../doc_theme.dart';

const _roman = ['i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii', 'ix', 'x', 'xi', 'xii'];
String _optionLabel(int index) =>
    index < _roman.length ? _roman[index] : '${index + 1}';

/// Quiz: các nút đáp án (i, ii, iii…), chọn để hiện đúng/sai + giải thích,
/// chọn lại được. Đáp án nằm ở bloc (qua [BlockContext]) nên giữ khi đổi view.
class QuizBlockWidget extends StatelessWidget {
  const QuizBlockWidget({super.key, required this.block, required this.ctx});

  final QuizBlock block;
  final BlockContext ctx;

  @override
  Widget build(BuildContext context) {
    final selected = ctx.quizAnswerFor?.call(ctx.blockKey);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.question,
            style: DocFonts.body(size: 16, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < block.options.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _QuizOption(
              key: ValueKey('quiz_opt_${ctx.blockKey}_$i'),
              label: _optionLabel(i),
              text: block.options[i],
              state: _optionState(selected, i),
              onTap: () => ctx.onQuizAnswer?.call(ctx.blockKey, i),
            ),
          ],
          if (selected != null) ...[
            const SizedBox(height: 12),
            _QuizExplanation(
              text: block.explanation,
              correct: selected == block.correctIndex,
            ),
          ],
        ],
      ),
    );
  }

  _OptionState _optionState(int? selected, int index) {
    if (selected == null) return _OptionState.neutral;
    if (index == block.correctIndex) return _OptionState.correct;
    if (index == selected) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { neutral, correct, wrong, dimmed }

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    super.key,
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String label;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (state) {
      _OptionState.correct => (
          const Color(0xFFE8F3EC),
          Brand.success,
          Brand.success,
          const Icon(Icons.check_circle, size: 20)
        ),
      _OptionState.wrong => (
          Brand.primary.withAlpha(24),
          Brand.primary,
          Brand.primary,
          const Icon(Icons.cancel, size: 20)
        ),
      _OptionState.dimmed => (
          Brand.unknownBackground,
          Brand.border,
          Brand.disabled,
          null
        ),
      _OptionState.neutral => (
          Colors.white,
          Brand.border,
          Brand.textPrimary,
          null
        ),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: state == _OptionState.neutral ? 1 : 1.5),
        ),
        child: Row(
          children: [
            Text(
              '$label. ',
              style: DocFonts.body(
                  size: 15, weight: FontWeight.w700, color: fg),
            ),
            Expanded(
              child: Text(
                text,
                style: DocFonts.body(size: 15, color: fg),
              ),
            ),
            ?icon,
          ],
        ),
      ),
    );
  }
}

class _QuizExplanation extends StatelessWidget {
  const _QuizExplanation({required this.text, required this.correct});

  final String text;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final color = correct ? Brand.success : Brand.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle : Icons.close,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              correct
                  ? (text.trim().isNotEmpty ? text : 'Chính xác!')
                  : (text.trim().isNotEmpty ? text : 'Chưa đúng, thử lại nhé.'),
              style: DocFonts.body(size: 14, color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vocab: danh sách từ / loại từ / IPA / nghĩa; mỗi từ có [SpeakButton].
class VocabBlockWidget extends StatelessWidget {
  const VocabBlockWidget({super.key, required this.block, required this.ctx});

  final VocabBlock block;
  final BlockContext ctx;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < block.items.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Brand.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              block.items[i].word,
                              style: DocFonts.body(
                                  size: 16, weight: FontWeight.w700),
                            ),
                          ),
                          if (block.items[i].partOfSpeech.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                block.items[i].partOfSpeech,
                                style: DocFonts.body(
                                    size: 12,
                                    color: Brand.textSecondary,
                                    weight: FontWeight.w600),
                              ),
                            ),
                          if (block.items[i].ipa.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                block.items[i].ipa,
                                style: DocFonts.mono(size: 12, color: Brand.textSecondary),
                              ),
                            ),
                        ],
                      ),
                      if (block.items[i].meaning.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          block.items[i].meaning,
                          style: DocFonts.body(size: 14, color: Brand.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SpeakButton(
                  text: block.items[i].word,
                  color: Brand.primary,
                  size: 36,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
