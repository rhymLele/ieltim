import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/doc_status.dart';
import '../../../domain/entities/doc_summary.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../common_widgets.dart';
import 'admin_doc_action.dart';

/// Độ rộng cột; 0 = co giãn.
const _columnWidths = [56.0, 0.0, 110.0, 80.0, 200.0, 150.0, 48.0];

/// Bảng tài liệu: Tuần · Tiêu đề · Kỹ năng · Kiểu · Trạng thái · Cập nhật · ⋯
class AdminDocsTable extends StatelessWidget {
  const AdminDocsTable({super.key, required this.docs, required this.onOpen, required this.onAction});

  final List<DocSummary> docs;

  /// Bấm vào dòng (trừ tài liệu đã gỡ): mở màn soạn.
  final ValueChanged<DocSummary> onOpen;
  final void Function(DocSummary doc, AdminDocAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _HeaderRow(),
          for (final d in docs) _DocRow(doc: d, onOpen: onOpen, onAction: (a) => onAction(d, a)),
        ],
      ),
    );
  }
}

class _Cells extends StatelessWidget {
  const _Cells({required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            _columnWidths[i] == 0 ? Expanded(child: cells[i]) : SizedBox(width: _columnWidths[i], child: cells[i]),
        ],
      );
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
        child: const _Cells(cells: [
          Text('Tuần', style: AppText.eyebrow),
          Text('Tiêu đề', style: AppText.eyebrow),
          Text('Kỹ năng', style: AppText.eyebrow),
          Text('Kiểu', style: AppText.eyebrow),
          Text('Trạng thái', style: AppText.eyebrow),
          Text('Cập nhật', style: AppText.eyebrow),
          SizedBox.shrink(),
        ]),
      );
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');

class _DocRow extends StatelessWidget {
  const _DocRow({required this.doc, required this.onOpen, required this.onAction});

  final DocSummary doc;
  final ValueChanged<DocSummary> onOpen;
  final ValueChanged<AdminDocAction> onAction;

  @override
  Widget build(BuildContext context) {
    final d = doc;
    final at = d.publishAt?.toLocal();
    final updated = d.updatedAt?.toLocal();
    final suffix = d.status == DocStatus.scheduled && at != null ? '${at.day}/${at.month} ${_twoDigits(at.hour)}:${_twoDigits(at.minute)}' : null;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        key: Key('weekly_docs_admin_doc_${d.id}_row'),
        hoverColor: AppColors.hover,
        onTap: d.status == DocStatus.archived ? null : () => onOpen(d),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
          child: _Cells(cells: [
            Text('${d.week}·${d.order}', style: AppText.label.copyWith(color: AppColors.textMuted)),
            Row(
              children: [
                if (d.isHomework) ...[const HomeworkTag(), const SizedBox(width: 8)],
                Expanded(child: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(fontSize: 14))),
              ],
            ),
            Text(skillLabels[d.skill] ?? d.skill, style: AppText.caption),
            Text(d.isHtml ? 'HTML' : (d.defaultView == DocViewMode.slide ? 'Slide' : 'Doc'), style: AppText.caption),
            Align(alignment: Alignment.centerLeft, child: StatusBadge(status: d.status, suffix: suffix)),
            Text(updated == null ? d.updatedBy : '${_twoDigits(updated.hour)}:${_twoDigits(updated.minute)} · ${d.updatedBy}', style: AppText.caption),
            PopupMenuButton<AdminDocAction>(
              key: Key('weekly_docs_admin_doc_${d.id}_menu'),
              tooltip: 'Thao tác',
              icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
              color: AppColors.cardSurface,
              onSelected: onAction,
              itemBuilder: (_) => [
                for (final a in AdminDocAction.availableFor(d))
                  PopupMenuItem(
                    key: Key('weekly_docs_admin_action_${a.name}_item'),
                    value: a,
                    child: Text(a.label, style: TextStyle(color: a.isDestructive ? AppColors.primary : AppColors.textInk)),
                  ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
