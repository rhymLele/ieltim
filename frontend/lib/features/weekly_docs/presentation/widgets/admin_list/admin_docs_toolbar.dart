import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/doc_status.dart';
import '../../../domain/entities/week_info.dart';

/// Hàng lọc: tuần · trạng thái · tìm theo tiêu đề.
class AdminDocsToolbar extends StatelessWidget {
  const AdminDocsToolbar({
    super.key,
    required this.weeks,
    required this.week,
    required this.statuses,
    required this.onWeekChanged,
    required this.onStatusToggled,
    required this.onQueryChanged,
  });

  final List<WeekInfo> weeks;
  final int? week;
  final Set<DocStatus> statuses;
  final ValueChanged<int?> onWeekChanged;
  final void Function(DocStatus status, bool selected) onStatusToggled;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _WeekDropdown(weeks: weeks, value: week, onChanged: onWeekChanged),
        for (final s in DocStatus.values) _StatusChip(status: s, selected: statuses.contains(s), onSelected: (v) => onStatusToggled(s, v)),
        SizedBox(
          width: 240,
          child: TextField(
            key: const Key('weekly_docs_admin_search_field'),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded, size: 20), hintText: 'Tìm theo tiêu đề'),
            onChanged: onQueryChanged,
          ),
        ),
      ],
    );
  }
}

class _WeekDropdown extends StatelessWidget {
  const _WeekDropdown({required this.weeks, required this.value, required this.onChanged});

  final List<WeekInfo> weeks;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Tuần đang lọc không còn trong danh sách (vd vừa đổi dữ liệu) thì hiện "Tất cả tuần".
    final selected = weeks.any((w) => w.number == value) ? value : null;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.borderStrong)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          key: const Key('weekly_docs_admin_week_dropdown'),
          value: selected,
          borderRadius: BorderRadius.circular(AppRadius.md),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Tất cả tuần')),
            for (final w in weeks) DropdownMenuItem<int?>(value: w.number, child: Text('Tuần ${w.number}')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.selected, required this.onSelected});

  final DocStatus status;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      key: Key('weekly_docs_admin_status_${status.name}_chip'),
      label: Text(status.label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.onPrimary,
      labelStyle: TextStyle(color: selected ? AppColors.onPrimary : AppColors.textInk, fontWeight: FontWeight.w700, fontSize: 13),
      backgroundColor: AppColors.cardSurface,
      side: const BorderSide(color: AppColors.borderStrong),
      shape: const StadiumBorder(),
    );
  }
}
