// selection_actions_card.dart — Hộp thoại khi bôi đen: Sổ từ · Dịch nghĩa · Nghe · Sao chép · Highlight 4 màu.
// Chỉ là UI: mọi hành động đi qua callback. Dùng chung cho tài liệu JSON và HTML.
import 'package:flutter/material.dart';

import '../annotate_theme.dart';
import '../models.dart';

class SelectionActionsCard extends StatefulWidget {
  const SelectionActionsCard({
    super.key,
    required this.text,
    required this.onAddVocab,
    required this.onTranslate,
    required this.onHighlight,
    this.onRemoveHighlight,
    this.onSpeak,
    this.onCopy,
    this.currentHighlight,
    this.alreadyInVocab = false,
    this.maxWords = 8,
  });

  /// Chữ đang được bôi đen.
  final String text;
  final VoidCallback onAddVocab;
  final Future<TranslationResult> Function() onTranslate;
  final ValueChanged<HighlightColor> onHighlight;
  final VoidCallback? onRemoveHighlight;
  final VoidCallback? onSpeak;
  final VoidCallback? onCopy;

  /// Màu đang highlight (khi người dùng chạm vào đoạn đã tô).
  final HighlightColor? currentHighlight;
  final bool alreadyInVocab;
  final int maxWords;

  @override
  State<SelectionActionsCard> createState() => _SelectionActionsCardState();
}

class _SelectionActionsCardState extends State<SelectionActionsCard> {
  Future<TranslationResult>? _translation;

  int get _words => widget.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  bool get _tooLong => _words > widget.maxWords;

  @override
  Widget build(BuildContext context) {
    final shown = widget.text.length > 60 ? '${widget.text.substring(0, 57)}…' : widget.text;
    return Material(
      color: AnnColors.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: _translation == null ? 300 : 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AnnColors.border),
          boxShadow: const [BoxShadow(color: Color(0x2E2A1418), blurRadius: 36, offset: Offset(0, 14))],
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.topCenter,
          child: _translation == null ? _menu(shown) : _translate(),
        ),
      ),
    );
  }

  Widget _menu(String shown) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Text('“$shown”', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AnnColors.primary)),
        ),
        const Divider(height: 1, color: Color(0xFFF4E8DC)),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              _Action(
                icon: widget.alreadyInVocab ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                label: widget.alreadyInVocab ? 'Đã có trong sổ' : 'Sổ từ',
                onTap: _tooLong || widget.alreadyInVocab ? null : widget.onAddVocab,
              ),
              _Action(icon: Icons.translate, label: 'Dịch nghĩa', onTap: () => setState(() => _translation = widget.onTranslate())),
              if (widget.onSpeak != null) _Action(icon: Icons.volume_up_outlined, label: 'Nghe', onTap: widget.onSpeak),
              if (widget.onCopy != null) _Action(icon: Icons.copy_rounded, label: 'Sao chép', onTap: widget.onCopy),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF4E8DC)),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
          child: Row(
            children: [
              const Expanded(child: Text('Highlight', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AnnColors.textMuted))),
              for (final c in HighlightColor.values)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Semantics(
                    button: true,
                    selected: widget.currentHighlight == c,
                    label: 'Highlight ${c.label}',
                    child: GestureDetector(
                      onTap: () => widget.onHighlight(c),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: c.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.currentHighlight == c ? AnnColors.primary : Colors.white, width: 2),
                          boxShadow: const [BoxShadow(color: Color(0x1F2A1418), blurRadius: 2)],
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.currentHighlight != null && widget.onRemoveHighlight != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: InkResponse(
                    onTap: widget.onRemoveHighlight,
                    radius: 18,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AnnColors.borderStrong)),
                      child: const Icon(Icons.close, size: 14, color: AnnColors.textMuted, semanticLabel: 'Bỏ highlight'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_tooLong)
          Container(
            color: const Color(0xFFFDF1DE),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Sổ từ nhận tối đa ${widget.maxWords} từ. Vẫn dịch và highlight được.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A5A12))),
          ),
      ],
    );
  }

  Widget _translate() {
    return FutureBuilder<TranslationResult>(
      future: _translation,
      builder: (context, snap) {
        final r = snap.data;
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: widget.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AnnColors.text)),
                  if (r?.ipa != null || r?.partOfSpeech != null)
                    TextSpan(
                      text: '  ${[r?.ipa, r?.partOfSpeech].whereType<String>().join(' · ')}',
                      style: const TextStyle(fontSize: 12, color: AnnColors.textMuted),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              if (snap.connectionState != ConnectionState.done)
                const Row(children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AnnColors.primary)),
                  SizedBox(width: 8),
                  Text('Đang dịch…', style: TextStyle(fontSize: 13, color: AnnColors.textMuted)),
                ])
              else if (snap.hasError || r == null)
                const Text('Chưa dịch được. Kiểm tra mạng rồi thử lại.', style: TextStyle(fontSize: 13, color: AnnColors.primary))
              else ...[
                Text(r.meaning, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AnnColors.primary)),
                if (r.sentenceTranslation != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: AnnColors.soft, borderRadius: BorderRadius.circular(10)),
                    child: Text.rich(TextSpan(children: [
                      const TextSpan(text: 'Trong bài: ', style: TextStyle(fontWeight: FontWeight.w800, color: AnnColors.text)),
                      TextSpan(text: r.sentenceTranslation),
                    ]), style: const TextStyle(fontSize: 12.5, height: 1.5, color: AnnColors.textMuted)),
                  ),
                ],
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _translation = null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AnnColors.text,
                      side: const BorderSide(color: AnnColors.borderStrong),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('‹ Quay lại'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _tooLong || widget.alreadyInVocab ? null : widget.onAddVocab,
                      style: FilledButton.styleFrom(backgroundColor: AnnColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                      label: Text(widget.alreadyInVocab ? 'Đã có trong sổ' : 'Thêm vào sổ từ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.45 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: AnnColors.text),
                  const SizedBox(height: 4),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AnnColors.text)),
                ],
              ),
            ),
          ),
        ),
      );
}
