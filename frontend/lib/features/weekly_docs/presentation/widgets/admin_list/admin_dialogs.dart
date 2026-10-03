import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/week_info.dart';

/// Hộp xác nhận trước thao tác khó hoàn tác (gỡ, xoá). Trả `true` khi bấm [confirmLabel].
class ConfirmActionDialog extends StatelessWidget {
  const ConfirmActionDialog({super.key, required this.title, required this.body, required this.confirmLabel});

  final String title;
  final String body;
  final String confirmLabel;

  static Future<bool> show(BuildContext context, {required String title, required String body, required String confirmLabel}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmActionDialog(title: title, body: body, confirmLabel: confirmLabel),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.cardLg)),
      title: Text(title, style: AppText.heading),
      content: Text(body, style: AppText.body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
        FilledButton(key: const Key('weekly_docs_admin_confirm_button'), onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel)),
      ],
    );
  }
}

/// Chọn tuần đích khi nhân bản. Trả số tuần, hoặc null khi đóng hộp.
class WeekPickerDialog extends StatelessWidget {
  const WeekPickerDialog({super.key, required this.weeks});

  final List<WeekInfo> weeks;

  static Future<int?> show(BuildContext context, List<WeekInfo> weeks) =>
      showDialog<int>(context: context, builder: (_) => WeekPickerDialog(weeks: weeks));

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: AppColors.cardSurface,
      title: const Text('Nhân bản sang tuần', style: AppText.heading),
      children: [
        for (final w in weeks)
          SimpleDialogOption(
            key: Key('weekly_docs_admin_week_${w.number}_option'),
            onPressed: () => Navigator.pop(context, w.number),
            child: Text('Tuần ${w.number} · ${w.rangeLabel}', style: AppText.body),
          ),
      ],
    );
  }
}
