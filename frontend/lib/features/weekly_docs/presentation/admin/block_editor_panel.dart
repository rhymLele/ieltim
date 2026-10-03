// block_editor_panel.dart — Khung soạn khối đang chọn (A2 bước 2, tab Form). Bố cục: file 6 mục A2.2.
//
// Panel sửa TRỰC TIẾP vào Map JSON của khối rồi gọi onChanged() để màn cha setState + tự lưu.

import 'package:flutter/material.dart';

import '../../core/app_tokens.dart';
import '../../domain/doc_templates.dart';
import '../../domain/weekly_doc.dart';
import '../widgets/common_widgets.dart';

class BlockEditorPanel extends StatelessWidget {
  const BlockEditorPanel({
    super.key,
    required this.section,
    required this.block,
    required this.fieldKeyPrefix,
    required this.onChanged,
    required this.onAddBlock,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  final Map<String, dynamic> section;
  final Map<String, dynamic>? block;

  /// Đổi khi chọn khối khác hoặc nội dung bị thay từ ngoài → các ô nhập dựng lại với giá trị mới.
  final String fieldKeyPrefix;
  final VoidCallback onChanged;
  final ValueChanged<String> onAddBlock;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final b = block;
    final type = b?['type'] as String? ?? '';
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        _field(
          label: 'TÊN SECTION',
          eyebrow: true,
          value: section['title'] as String? ?? '',
          keyName: 'sec-title',
          onChanged: (v) {
            section['title'] = v;
            onChanged();
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: Text('Khối: ${blockTypeLabels[type] ?? type}', style: AppText.heading.copyWith(fontSize: 15))),
            _iconBtn(Icons.arrow_upward_rounded, 'Đưa khối lên', onMoveUp),
            const SizedBox(width: 6),
            _iconBtn(Icons.arrow_downward_rounded, 'Đưa khối xuống', onMoveDown),
            const SizedBox(width: 6),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  side: const BorderSide(color: AppColors.errorBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                child: const Text('Xoá khối'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (b != null) ..._fieldsFor(b, type),
        const SizedBox(height: AppSpace.lg),
        const Divider(height: 1),
        const SizedBox(height: AppSpace.lg),
        const Eyebrow('Thêm khối vào section này'),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in addableBlockTypes)
              ActionChip(
                label: Text('+ ${blockTypeLabels[t]}'),
                onPressed: () => onAddBlock(t),
                backgroundColor: AppColors.background,
                side: const BorderSide(color: AppColors.borderStrong),
                shape: const StadiumBorder(),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _fieldsFor(Map<String, dynamic> b, String type) {
    void set(String k, Object? v) {
      b[k] = v;
      onChanged();
    }

    List<String> lines(String v) => v.split('\n');

    switch (type) {
      case 'heading':
      case 'paragraph':
      case 'callout':
        return [
          _field(label: 'Nội dung', hint: 'Dùng **chữ đậm** để nhấn mạnh', value: b['text'] as String? ?? '', keyName: 'text', maxLines: 5, onChanged: (v) => set('text', v)),
          if (type == 'callout') ...[
            const SizedBox(height: 12),
            _ToneSelector(value: b['tone'] as String? ?? 'tip', onChanged: (v) => set('tone', v)),
          ],
        ];
      case 'steps':
        return [
          _field(label: 'Các bước', hint: 'Mỗi dòng là một bước', value: _joinList(b['items']), keyName: 'items', maxLines: 6, onChanged: (v) => set('items', lines(v))),
        ];
      case 'passage':
        return [
          _field(label: 'Nhãn', value: b['label'] as String? ?? '', keyName: 'label', onChanged: (v) => set('label', v)),
          const SizedBox(height: 12),
          _field(label: 'Đoạn văn đề thi', value: b['text'] as String? ?? '', keyName: 'text', maxLines: 7, onChanged: (v) => set('text', v)),
        ];
      case 'quiz':
        final options = (b['options'] as List?)?.length ?? 0;
        return [
          _field(label: 'Câu hỏi', value: b['question'] as String? ?? '', keyName: 'question', onChanged: (v) => set('question', v)),
          const SizedBox(height: 12),
          _field(
            label: 'Các đáp án',
            hint: 'Mỗi dòng một đáp án (2–6)',
            value: _joinList(b['options']),
            keyName: 'options',
            maxLines: 4,
            onChanged: (v) {
              final opts = lines(v);
              b['options'] = opts;
              final a = b['answer'];
              if (a is! int || a >= opts.length) b['answer'] = 0;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          const Text('Đáp án đúng', style: AppText.label),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < options && i < romanKeys.length; i++)
                _AnswerButton(label: romanKeys[i], selected: b['answer'] == i, onTap: () => set('answer', i)),
            ],
          ),
          const SizedBox(height: 12),
          _field(label: 'Giải thích', value: b['explain'] as String? ?? '', keyName: 'explain', maxLines: 3, onChanged: (v) => set('explain', v)),
        ];
      case 'vocab':
        return [
          _field(
            label: 'Danh sách từ',
            hint: 'Mỗi dòng: từ | loại từ | phiên âm | nghĩa',
            value: _vocabLines(b['items']),
            keyName: 'items',
            maxLines: 6,
            mono: true,
            onChanged: (v) => set('items', [
              for (final l in lines(v))
                if (l.trim().isNotEmpty) _parseVocabLine(l),
            ]),
          ),
        ];
      case 'pattern':
        return [
          _field(label: 'Cấu trúc', value: b['structure'] as String? ?? '', keyName: 'structure', onChanged: (v) => set('structure', v)),
          const SizedBox(height: 12),
          _field(label: 'Câu ví dụ', value: b['example'] as String? ?? '', keyName: 'example', onChanged: (v) => set('example', v)),
        ];
      case 'image':
        return [
          _field(label: 'Link ảnh (https)', hint: 'Upload ảnh qua API rồi dán link vào đây', value: b['url'] as String? ?? '', keyName: 'url', onChanged: (v) => set('url', v)),
          const SizedBox(height: 12),
          _field(label: 'Chú thích', value: b['caption'] as String? ?? '', keyName: 'caption', onChanged: (v) => set('caption', v)),
          const SizedBox(height: 12),
          _field(label: 'Mô tả cho trợ năng (alt)', value: b['alt'] as String? ?? '', keyName: 'alt', onChanged: (v) => set('alt', v)),
        ];
      case 'slideBreak':
        return const [Text('Khối này tách section thành slide mới khi xem dạng Slide. Ở dạng Doc không hiển thị.', style: AppText.caption)];
      default:
        return const [Text('Loại khối chưa được hỗ trợ trong form. Sửa trong tab "Nhập JSON".', style: AppText.caption)];
    }
  }

  static String _joinList(Object? v) => v is List ? v.map((e) => '$e').join('\n') : '';

  static String _vocabLines(Object? v) => v is List
      ? v.map((e) {
          final m = asJsonMap(e);
          return [m['word'], m['pos'], m['ipa'], m['meaning']].map((x) => x ?? '').join(' | ');
        }).join('\n')
      : '';

  static Map<String, dynamic> _parseVocabLine(String l) {
    final p = l.split('|').map((x) => x.trim()).toList();
    String at(int i) => i < p.length ? p[i] : '';
    return {
      'word': at(0),
      if (at(1).isNotEmpty) 'pos': at(1),
      if (at(2).isNotEmpty) 'ipa': at(2),
      'meaning': at(3),
    };
  }

  Widget _field({
    required String label,
    required String value,
    required String keyName,
    required ValueChanged<String> onChanged,
    String? hint,
    int maxLines = 1,
    bool mono = false,
    bool eyebrow = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: label, style: eyebrow ? AppText.eyebrow : AppText.label),
          if (hint != null) TextSpan(text: '  $hint', style: AppText.caption),
        ])),
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey('$fieldKeyPrefix-$keyName'),
          initialValue: value,
          minLines: maxLines > 1 ? (maxLines > 3 ? 3 : maxLines) : 1,
          maxLines: maxLines,
          style: mono ? const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.text) : const TextStyle(fontSize: 14, color: AppColors.text),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback? onTap) => SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          padding: EdgeInsets.zero,
          iconSize: 18,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textMuted,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
          icon: Icon(icon),
        ),
      );
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        label: 'Đáp án $label${selected ? ', đang chọn là đáp án đúng' : ''}',
        excludeSemantics: true,
        child: Material(
          color: selected ? AppColors.primary : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: selected ? AppColors.primary : AppColors.borderStrong, width: 1.5)),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 40,
              child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: selected ? AppColors.onPrimary : AppColors.text))),
            ),
          ),
        ),
      );
}

class _ToneSelector extends StatelessWidget {
  const _ToneSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const tones = {'tip': 'Mẹo', 'warning': 'Lưu ý', 'note': 'Ghi chú'};
    return Wrap(
      spacing: 6,
      children: [
        for (final e in tones.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: value == e.key,
            onSelected: (_) => onChanged(e.key),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: value == e.key ? AppColors.onPrimary : AppColors.text),
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.borderStrong),
            showCheckmark: false,
          ),
      ],
    );
  }
}
