import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/rules/doc_templates.dart';
import '../../cubits/doc_creator_cubit.dart';
import '../admin_list/admin_dialogs.dart';
import 'html_upload_dialog.dart';

// Các luồng có hộp thoại dùng chung giữa bước 1 (thẻ template) và bước 2 ("Đổi file").

/// Chọn template; đang sửa mà đổi template thì hỏi trước vì nội dung sẽ bị thay.
Future<void> pickTemplate(BuildContext context, DocTemplate template) async {
  if (template.isHtml) return pickHtmlFile(context);
  final cubit = context.read<DocCreatorCubit>();
  if (cubit.needsConfirmFor(template)) {
    final ok = await ConfirmActionDialog.show(
      context,
      title: 'Đổi template?',
      body: 'Đổi template sẽ thay toàn bộ nội dung hiện tại bằng khung mới. Tiếp tục?',
      confirmLabel: 'Đổi template',
    );
    if (!ok) return;
  }
  cubit.applyTemplate(template);
}

/// Popup tải file HTML (file 9). Huỷ thì giữ nguyên template đang chọn.
Future<void> pickHtmlFile(BuildContext context) async {
  final cubit = context.read<DocCreatorCubit>();
  final file = await showHtmlUploadDialog(context);
  if (file == null || !context.mounted) return;
  if (cubit.needsConfirmFor(templateById('html'))) {
    final ok = await ConfirmActionDialog.show(
      context,
      title: 'Đổi template?',
      body: 'Đổi sang file HTML sẽ thay toàn bộ nội dung hiện tại. Tiếp tục?',
      confirmLabel: 'Đổi template',
    );
    if (!ok) return;
  }
  cubit.applyHtmlFile(file);
}

/// Chọn ngày + giờ hẹn xuất bản.
Future<void> pickScheduleTime(BuildContext context) async {
  final cubit = context.read<DocCreatorCubit>();
  final now = DateTime.now();
  final date = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 365)), initialDate: cubit.state.scheduleAt ?? now);
  if (date == null || !context.mounted) return;
  final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 6, minute: 0));
  if (time == null) return;
  cubit.setScheduleAt(DateTime(date.year, date.month, date.day, time.hour, time.minute));
}
