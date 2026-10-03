// block_editor_panel.dart — Khung soạn khối đang chọn (A2 bước 2, tab Form). Bố cục: file 6 mục A2.2.
//
// Panel sửa TRỰC TIẾP vào Map JSON của khối rồi gọi onChanged() để màn soạn tính lại + tự lưu.

import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../../../domain/rules/doc_templates.dart';
import '../common_widgets.dart';

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
        _EditorField(
          keyPrefix: fieldKeyPrefix,
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
            _IconActionButton(icon: Icons.arrow_upward_rounded, tooltip: 'Đưa khối lên', onPressed: onMoveUp),
            const SizedBox(width: 6),
            _IconActionButton(icon: Icons.arrow_downward_rounded, tooltip: 'Đưa khối xuống', onPressed: onMoveDown),
            const SizedBox(width: 6),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                key: const Key('weekly_docs_creator_delete_block_button'),
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
        if (b != null) _BlockFields(block: b, type: type, keyPrefix: fieldKeyPrefix, onChanged: onChanged),
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
                key: Key('weekly_docs_creator_add_${t}_chip'),
                label: Text('+ ${blockTypeLabels[t]}'),
                onPressed: () => onAddBlock(t),
                backgroundColor: AppColors.background,
                side: const BorderSide(color: AppColors.borderStrong),
                shape: const StadiumBorder(),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textInk),
              ),
          ],
        ),
      ],
    );
  }
}

/// Các ô nhập theo loại khối; sửa thẳng vào [block] rồi gọi [onChanged].
class _BlockFields extends StatelessWidget {
  const _BlockFields({required this.block, required this.type, required this.keyPrefix, required this.onChanged});

  final Map<String, dynamic> block;
  final String type;
  final String keyPrefix;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final b = block;
    void set(String key, Object? value) {
      b[key] = value;
      onChanged();
    }

    List<String> lines(String text) => text.split('\n');

    _EditorField field({
      required String label,
      required String keyName,
      required String value,
      required ValueChanged<String> onChanged,
      String? hint,
      int maxLines = 1,
      bool mono = false,
    }) =>
        _EditorField(keyPrefix: keyPrefix, label: label, keyName: keyName, value: value, onChanged: onChanged, hint: hint, maxLines: maxLines, mono: mono);

    final optionCount = (b['options'] as List?)?.length ?? 0;
    final fields = switch (type) {
      'heading' || 'paragraph' || 'callout' => [
          field(label: 'Nội dung', hint: 'Dùng **chữ đậm** để nhấn mạnh', value: b['text'] as String? ?? '', keyName: 'text', maxLines: 5, onChanged: (v) => set('text', v)),
          if (type == 'callout') ...[
            const SizedBox(height: 12),
            _ToneSelector(value: b['tone'] as String? ?? 'tip', onChanged: (v) => set('tone', v)),
          ],
        ],
      'steps' => [
          field(label: 'Các bước', hint: 'Mỗi dòng là một bước', value: _joinList(b['items']), keyName: 'items', maxLines: 6, onChanged: (v) => set('items', lines(v))),
        ],
      'passage' => [
          field(label: 'Nhãn', value: b['label'] as String? ?? '', keyName: 'label', onChanged: (v) => set('label', v)),
          const SizedBox(height: 12),
          field(label: 'Đoạn văn đề thi', value: b['text'] as String? ?? '', keyName: 'text', maxLines: 7, onChanged: (v) => set('text', v)),
        ],
      'quiz' => [
          field(label: 'Câu hỏi', value: b['question'] as String? ?? '', keyName: 'question', onChanged: (v) => set('question', v)),
          const SizedBox(height: 12),
          field(
            label: 'Các đáp án',
            hint: 'Mỗi dòng một đáp án (2–6)',
            value: _joinList(b['options']),
            keyName: 'options',
            maxLines: 4,
            onChanged: (v) {
              final options = lines(v);
              b['options'] = options;
              final answer = b['answer'];
              if (answer is! int || answer >= options.length) b['answer'] = 0;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          const Text('Đáp án đúng', style: AppText.label),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < optionCount && i < romanKeys.length; i++)
                _AnswerButton(label: romanKeys[i], selected: b['answer'] == i, onTap: () => set('answer', i)),
            ],
          ),
          const SizedBox(height: 12),
          field(label: 'Giải thích', value: b['explain'] as String? ?? '', keyName: 'explain', maxLines: 3, onChanged: (v) => set('explain', v)),
        ],
      'vocab' => [
          field(
            label: 'Danh sách từ',
            hint: 'Mỗi dòng: từ | loại từ | phiên âm | nghĩa',
            value: _vocabLines(b['items']),
            keyName: 'items',
            maxLines: 6,
            mono: true,
            onChanged: (v) => set('items', [
              for (final line in lines(v))
                if (line.trim().isNotEmpty) _parseVocabLine(line),
            ]),
          ),
        ],
      'pattern' => [
          field(label: 'Cấu trúc', value: b['structure'] as String? ?? '', keyName: 'structure', onChanged: (v) => set('structure', v)),
          const SizedBox(height: 12),
          field(label: 'Câu ví dụ', value: b['example'] as String? ?? '', keyName: 'example', onChanged: (v) => set('example', v)),
        ],
      'image' => [
          field(label: 'Link ảnh (https)', hint: 'Dán link ảnh bắt đầu bằng https://', value: b['url'] as String? ?? '', keyName: 'url', onChanged: (v) => set('url', v)),
          const SizedBox(height: 12),
          field(label: 'Chú thích', value: b['caption'] as String? ?? '', keyName: 'caption', onChanged: (v) => set('caption', v)),
          const SizedBox(height: 12),
          field(label: 'Mô tả cho trợ năng (alt)', value: b['alt'] as String? ?? '', keyName: 'alt', onChanged: (v) => set('alt', v)),
        ],
      'slideBreak' => const <Widget>[Text('Khối này tách section thành slide mới khi xem dạng Slide. Ở dạng Doc không hiển thị.', style: AppText.caption)],
      _ => const <Widget>[Text('Loại khối chưa được hỗ trợ trong form. Sửa trong tab "Nhập JSON".', style: AppText.caption)],
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: fields);
  }

  static String _joinList(Object? value) => value is List ? value.map((e) => '$e').join('\n') : '';

  static String _vocabLines(Object? value) => value is List
      ? value.map((e) {
          final m = asJsonMap(e);
          return [m['word'], m['pos'], m['ipa'], m['meaning']].map((x) => x ?? '').join(' | ');
        }).join('\n')
      : '';

  static Map<String, dynamic> _parseVocabLine(String line) {
    final parts = line.split('|').map((x) => x.trim()).toList();
    String at(int i) => i < parts.length ? parts[i] : '';
    return {
      'word': at(0),
      if (at(1).isNotEmpty) 'pos': at(1),
      if (at(2).isNotEmpty) 'ipa': at(2),
      'meaning': at(3),
    };
  }
}

/// Ô nhập có nhãn; [keyPrefix] đổi thì ô dựng lại với giá trị mới.
class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.keyPrefix,
    required this.label,
    required this.value,
    required this.keyName,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.mono = false,
    this.eyebrow = false,
  });

  final String keyPrefix;
  final String label;
  final String value;
  final String keyName;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int maxLines;
  final bool mono;
  final bool eyebrow;

  @override
  Widget build(BuildContext context) {
    final hintText = hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: label, style: eyebrow ? AppText.eyebrow : AppText.label),
          if (hintText != null) TextSpan(text: '  $hintText', style: AppText.caption),
        ])),
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey('$keyPrefix-$keyName'),
          initialValue: value,
          minLines: maxLines > 1 ? (maxLines > 3 ? 3 : maxLines) : 1,
          maxLines: maxLines,
          style: mono ? const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.textInk) : const TextStyle(fontSize: 14, color: AppColors.textInk),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Nút icon vuông nhỏ (đưa khối lên / xuống).
class _IconActionButton extends StatelessWidget {
  const _IconActionButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: 18,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textMuted,
            side: const BorderSide(color: AppColors.borderLight),
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
          color: selected ? AppColors.primary : AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: selected ? AppColors.primary : AppColors.borderStrong, width: 1.5)),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 40,
              child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: selected ? AppColors.onPrimary : AppColors.textInk))),
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
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: value == e.key ? AppColors.onPrimary : AppColors.textInk),
            backgroundColor: AppColors.cardSurface,
            side: const BorderSide(color: AppColors.borderStrong),
            showCheckmark: false,
          ),
      ],
    );
  }
}
