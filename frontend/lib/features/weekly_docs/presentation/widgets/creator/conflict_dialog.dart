import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';

/// Lưu bị 409: người khác vừa sửa. Trả `true` = tải bản mới, `false` = ghi đè bằng bản của mình.
class ConflictDialog extends StatelessWidget {
  const ConflictDialog({super.key, required this.message});

  final String message;

  static Future<bool> show(BuildContext context, String message) async {
    final reload = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => ConflictDialog(message: message));
    return reload ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardSurface,
      title: const Text('Tài liệu vừa được sửa', style: AppText.heading),
      content: Text(message, style: AppText.body),
      actions: [
        TextButton(key: const Key('weekly_docs_creator_conflict_overwrite_button'), onPressed: () => Navigator.pop(context, false), child: const Text('Ghi đè bằng bản của tôi')),
        FilledButton(key: const Key('weekly_docs_creator_conflict_reload_button'), onPressed: () => Navigator.pop(context, true), child: const Text('Tải bản mới')),
      ],
    );
  }
}
