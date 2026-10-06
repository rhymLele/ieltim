// annotation_toolbar.dart — Thanh công cụ: Xem · Bút · Dạ quang · Khoanh · Chữ · Ghi chú · màu · Hoàn tác · Xoá hết.
import 'package:flutter/material.dart';

import '../annotate_theme.dart';
import '../annotation_controller.dart';
import '../models.dart';

class AnnotationToolbar extends StatelessWidget {
  const AnnotationToolbar({super.key, required this.controller, this.compact = false, this.onClearConfirmed});

  final AnnotationController controller;

  /// true trên điện thoại: chỉ hiện icon.
  final bool compact;

  /// Gọi sau khi người dùng xác nhận "Xoá hết" (mặc định: controller.clear()).
  final VoidCallback? onClearConfirmed;

  static const _tools = [
    (AnnotationTool.view, Icons.pan_tool_alt_outlined, 'Xem'),
    (AnnotationTool.pen, Icons.edit_outlined, 'Bút'),
    (AnnotationTool.marker, Icons.border_color_outlined, 'Dạ quang'),
    (AnnotationTool.circle, Icons.circle_outlined, 'Khoanh'),
    (AnnotationTool.text, Icons.text_fields, 'Chữ'),
    (AnnotationTool.comment, Icons.mode_comment_outlined, 'Ghi chú'),
  ];

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá hết ghi chú trên slide này?'),
        content: const Text('Bấm Hoàn tác ngay sau đó để lấy lại.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AnnColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá hết'),
          ),
        ],
      ),
    );
    if (ok == true) (onClearConfirmed ?? controller.clear)();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final showColors = c.tool != AnnotationTool.view && c.tool != AnnotationTool.comment;
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AnnColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x142A1418), blurRadius: 14, offset: Offset(0, 4))],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (tool, icon, label) in _tools)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Tooltip(
                      message: label,
                      child: Material(
                        color: c.tool == tool ? AnnColors.toolOn : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => c.tool = tool,
                          child: Container(
                            height: 40,
                            constraints: const BoxConstraints(minWidth: 40),
                            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 19, color: c.tool == tool ? AnnColors.primary : AnnColors.text, semanticLabel: label),
                                if (!compact && tool != AnnotationTool.view) ...[
                                  const SizedBox(width: 6),
                                  Text(label,
                                      style: TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w800, color: c.tool == tool ? AnnColors.primary : AnnColors.text)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showColors) ...[
                  const _Divider(),
                  for (var i = 0; i < kPenColors.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Semantics(
                        button: true,
                        selected: c.colorIndex == i,
                        label: 'Màu ${kPenColorNames[i]}',
                        child: GestureDetector(
                          onTap: () => c.colorIndex = i,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: kPenColors[i],
                              shape: BoxShape.circle,
                              border: Border.all(color: c.colorIndex == i ? AnnColors.text : Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                const _Divider(),
                IconButton(
                  tooltip: 'Hoàn tác',
                  onPressed: c.canUndo ? c.undo : null,
                  icon: const Icon(Icons.undo_rounded),
                  color: AnnColors.text,
                ),
                TextButton(
                  onPressed: c.data.isEmpty ? null : () => _confirmClear(context),
                  style: TextButton.styleFrom(foregroundColor: AnnColors.textMuted),
                  child: const Text('Xoá hết', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 26, margin: const EdgeInsets.symmetric(horizontal: 6), color: AnnColors.border);
}
