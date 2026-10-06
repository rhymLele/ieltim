// notes_panel.dart — Danh sách ghi chú (ghim) của slide hiện tại, sửa nội dung trực tiếp.
// Desktop: đặt ở cột phải. Điện thoại: mở bằng showModalBottomSheet.
import 'package:flutter/material.dart';

import '../annotate_theme.dart';
import '../annotation_controller.dart';

class NotesPanel extends StatelessWidget {
  const NotesPanel({super.key, required this.controller, this.title = 'GHI CHÚ CỦA TÔI'});

  final AnnotationController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pins = controller.data.pins;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: AnnColors.textMuted)),
            const SizedBox(height: 12),
            if (pins.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AnnColors.soft, borderRadius: BorderRadius.circular(12)),
                child: const Text('Chọn "Ghi chú" rồi chạm lên slide để ghim ghi chú.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AnnColors.textMuted)),
              ),
            for (var i = 0; i < pins.length; i++)
              _NoteCard(
                key: ValueKey(pins[i].id),
                number: i + 1,
                text: pins[i].text,
                createdAt: pins[i].createdAt,
                active: controller.activePin == i,
                onTap: () => controller.activePin = i,
                onChanged: (v) => controller.updatePinText(i, v),
                onDelete: () => controller.removePin(i),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AnnColors.borderStrong),
              ),
              child: const Text(
                'Nét vẽ, chữ và ghi chú là của riêng bạn, không thay đổi tài liệu gốc. Mở trên máy khác vẫn thấy.',
                style: TextStyle(fontSize: 12, height: 1.55, color: AnnColors.textMuted),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NoteCard extends StatefulWidget {
  const _NoteCard({
    super.key,
    required this.number,
    required this.text,
    required this.createdAt,
    required this.active,
    required this.onTap,
    required this.onChanged,
    required this.onDelete,
  });

  final int number;
  final String text;
  final DateTime createdAt;
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  late final _ctl = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  String _when(DateTime t) {
    final now = DateTime.now();
    final hm = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final sameDay = now.year == t.year && now.month == t.month && now.day == t.day;
    return sameDay ? 'Hôm nay $hm' : '${t.day}/${t.month} $hm';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.active ? const Color(0xFFFFF7F8) : AnnColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.active ? AnnColors.primary : AnnColors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: widget.active ? AnnColors.primary : AnnColors.pinInactive,
                  child: Text('${widget.number}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_when(widget.createdAt), style: const TextStyle(fontSize: 11, color: AnnColors.textMuted))),
                IconButton(
                  tooltip: 'Xoá ghi chú',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.close, size: 18, color: AnnColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _ctl,
              minLines: 2,
              maxLines: 5,
              onChanged: widget.onChanged,
              onTap: widget.onTap,
              decoration: InputDecoration(
                hintText: 'Viết ghi chú…',
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AnnColors.borderStrong)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AnnColors.borderStrong)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AnnColors.primary, width: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
