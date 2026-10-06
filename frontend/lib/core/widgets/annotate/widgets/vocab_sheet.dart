// vocab_sheet.dart — Bottom sheet "Thêm vào sổ từ của tôi".
import 'package:flutter/material.dart';

import '../annotate_theme.dart';
import '../models.dart';

/// Trả về VocabDraft khi bấm Lưu, null khi huỷ. Việc gọi API do bên gọi xử lý.
Future<VocabDraft?> showVocabSheet(
  BuildContext context, {
  required String text,
  String? ipa,
  String? suggestedMeaning,
  String? example,
  List<String> decks = const ['Sổ chung'],
  String? initialDeck,
  String? sourceDocId,
}) {
  return showModalBottomSheet<VocabDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AnnColors.surface,
    barrierColor: AnnColors.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _VocabSheet(
      text: text,
      ipa: ipa,
      suggestedMeaning: suggestedMeaning,
      example: example,
      decks: decks,
      initialDeck: initialDeck ?? decks.first,
      sourceDocId: sourceDocId,
    ),
  );
}

class _VocabSheet extends StatefulWidget {
  const _VocabSheet({
    required this.text,
    this.ipa,
    this.suggestedMeaning,
    this.example,
    required this.decks,
    required this.initialDeck,
    this.sourceDocId,
  });

  final String text;
  final String? ipa;
  final String? suggestedMeaning;
  final String? example;
  final List<String> decks;
  final String initialDeck;
  final String? sourceDocId;

  @override
  State<_VocabSheet> createState() => _VocabSheetState();
}

class _VocabSheetState extends State<_VocabSheet> {
  late final _meaning = TextEditingController(text: widget.suggestedMeaning ?? '');
  late String _deck = widget.initialDeck;

  @override
  void dispose() {
    _meaning.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(VocabDraft(
      text: widget.text.trim(),
      meaning: _meaning.text.trim(),
      ipa: widget.ipa,
      example: widget.example,
      deck: _deck,
      sourceDocId: widget.sourceDocId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AnnColors.borderStrong, borderRadius: BorderRadius.circular(99))),
              ),
              const SizedBox(height: 14),
              const Text('THÊM VÀO SỔ TỪ CỦA TÔI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: AnnColors.textMuted)),
              const SizedBox(height: 6),
              Text.rich(TextSpan(children: [
                TextSpan(text: widget.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AnnColors.text)),
                if (widget.ipa != null) TextSpan(text: '  ${widget.ipa}', style: const TextStyle(fontSize: 13, color: AnnColors.textMuted)),
              ])),
              const SizedBox(height: 14),
              const Text('Nghĩa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(
                controller: _meaning,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  hintText: 'Nghĩa tiếng Việt',
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AnnColors.borderStrong)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AnnColors.primary, width: 1.5)),
                ),
              ),
              if (widget.example != null) ...[
                const SizedBox(height: 14),
                const Text('Câu ví dụ (lấy từ bài)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AnnColors.soft, borderRadius: BorderRadius.circular(10)),
                  child: Text(widget.example!, style: const TextStyle(fontSize: 13, height: 1.5, fontStyle: FontStyle.italic, color: AnnColors.text)),
                ),
              ],
              const SizedBox(height: 14),
              const Text('Lưu vào', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final d in widget.decks)
                    ChoiceChip(
                      label: Text(d),
                      selected: _deck == d,
                      onSelected: (_) => setState(() => _deck = d),
                      selectedColor: AnnColors.primary,
                      labelStyle: TextStyle(fontWeight: FontWeight.w700, color: _deck == d ? AnnColors.onPrimary : AnnColors.text),
                      showCheckmark: false,
                      side: BorderSide(color: _deck == d ? AnnColors.primary : AnnColors.borderStrong),
                      backgroundColor: AnnColors.surface,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AnnColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _save,
                  child: const Text('Lưu vào sổ từ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
