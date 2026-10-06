import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/annotate/annotate.dart';
import '../../../../annotate/presentation/cubits/doc_annotations_cubit.dart';
import '../../../core/app_tokens.dart';
import '../common_widgets.dart';

/// Một khối chữ của tài liệu theo thứ tự trong bài (để nhóm highlight).
class NoteBlock {
  const NoteBlock({required this.blockKey, required this.label, required this.text});

  final String blockKey;

  /// "Section 2 · Đoạn văn".
  final String label;
  final String text;
}

/// "Ghi chú của tôi": Highlight · Ghi chú slide · Từ đã lưu từ bài này.
class MyNotesPanel extends StatefulWidget {
  const MyNotesPanel({
    super.key,
    required this.blocks,
    required this.slideLabels,
    required this.onOpenBlock,
    required this.onOpenSlide,
    this.changedIds = const {},
  });

  final List<NoteBlock> blocks;

  /// Highlight không còn tìm thấy (tài liệu HTML: script trong file báo `highlightMissing`).
  final Set<String> changedIds;

  /// slideKey → "Slide 3" theo thứ tự trong bài.
  final Map<String, String> slideLabels;

  /// Chạm highlight: cuộn / nhảy tới khối đó.
  final ValueChanged<String> onOpenBlock;
  final ValueChanged<String> onOpenSlide;

  @override
  State<MyNotesPanel> createState() => _MyNotesPanelState();
}

class _MyNotesPanelState extends State<MyNotesPanel> {
  @override
  void initState() {
    super.initState();
    context.read<DocAnnotationsCubit>().loadSavedWords();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: [Tab(text: 'Highlight'), Tab(text: 'Ghi chú slide'), Tab(text: 'Từ đã lưu')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _HighlightsTab(blocks: widget.blocks, changedIds: widget.changedIds, onOpen: widget.onOpenBlock),
                _SlideNotesTab(slideLabels: widget.slideLabels, onOpen: widget.onOpenSlide),
                const _SavedWordsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightsTab extends StatelessWidget {
  const _HighlightsTab({required this.blocks, required this.changedIds, required this.onOpen});

  final List<NoteBlock> blocks;
  final Set<String> changedIds;
  final ValueChanged<String> onOpen;

  /// Khối JSON: tìm lại theo quote + prefix / suffix; tài liệu HTML (không có chữ ở app): theo tin của file.
  bool _changed(NoteBlock block, TextHighlight h) =>
      changedIds.contains(h.id) || (block.text.isNotEmpty && resolveHighlights(block.text, [h]).isEmpty);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DocAnnotationsCubit>().state;
    if (state.highlights.isEmpty) return const _Empty('Chưa có highlight. Bôi đen chữ trong bài rồi chọn một màu.');
    final known = {for (final b in blocks) b.blockKey};
    final lost = [for (final h in state.highlights) if (!known.contains(h.blockKey)) h];
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        for (final block in blocks)
          if (state.highlightsOf(block.blockKey) case final marks when marks.isNotEmpty) ...[
            Eyebrow(block.label),
            const SizedBox(height: 6),
            for (final h in marks)
              _HighlightRow(highlight: h, changed: _changed(block, h), onTap: () => onOpen(block.blockKey)),
            const SizedBox(height: AppSpace.md),
          ],
        if (lost.isNotEmpty) ...[
          const Eyebrow('Đoạn đã bị sửa'),
          const SizedBox(height: 6),
          for (final h in lost) _HighlightRow(highlight: h, changed: true),
        ],
      ],
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.highlight, required this.changed, this.onTap});

  final TextHighlight highlight;

  /// Admin đã sửa đoạn chữ: không còn tìm thấy trong bài.
  final bool changed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: changed ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: highlight.color.color, shape: BoxShape.circle, border: Border.all(color: AppColors.borderStrong)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(highlight.quote, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppText.body.copyWith(fontSize: 14)),
                  if (changed) Text('Đoạn này đã thay đổi', style: AppText.caption.copyWith(color: AppColors.warnText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideNotesTab extends StatelessWidget {
  const _SlideNotesTab({required this.slideLabels, required this.onOpen});

  final Map<String, String> slideLabels;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final slides = context.watch<DocAnnotationsCubit>().state.slides;
    final keys = [
      for (final key in slideLabels.keys) if (slides[key]?.pins.isNotEmpty ?? false) key,
      for (final key in slides.keys) if (!slideLabels.containsKey(key) && slides[key]!.pins.isNotEmpty) key,
    ];
    if (keys.isEmpty) return const _Empty('Chưa có ghi chú. Chọn "Ghi chú" trên thanh công cụ rồi chạm lên slide để ghim.');
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        for (final key in keys) ...[
          Eyebrow(slideLabels[key] ?? key),
          const SizedBox(height: 6),
          for (final (i, pin) in slides[key]!.pins.indexed)
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: () => onOpen(key),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primary,
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.onPrimary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pin.text.trim().isEmpty ? '(chưa viết)' : pin.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body.copyWith(fontSize: 14, color: pin.text.trim().isEmpty ? AppColors.textMuted : AppColors.textInk),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpace.md),
        ],
      ],
    );
  }
}

class _SavedWordsTab extends StatelessWidget {
  const _SavedWordsTab();

  @override
  Widget build(BuildContext context) {
    final words = context.watch<DocAnnotationsCubit>().state.savedWords;
    if (words.isEmpty) return const _Empty('Chưa lưu từ nào từ bài này. Bôi đen một từ rồi chọn "Sổ từ".');
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpace.lg),
      itemCount: words.length,
      separatorBuilder: (_, _) => const Divider(height: 16, color: AppColors.borderLight),
      itemBuilder: (_, i) {
        final w = words[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: w.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textInk)),
              if (w.ipa != null) TextSpan(text: '  ${w.ipa}', style: AppText.caption),
            ])),
            if (w.meaning.isNotEmpty) Text(w.meaning, style: AppText.body.copyWith(fontSize: 14)),
            Text(w.deck, style: AppText.caption),
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Text(message, textAlign: TextAlign.center, style: AppText.caption.copyWith(height: 1.5)),
      );
}
