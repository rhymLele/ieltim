import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/rules/doc_validator.dart';
import '../../cubits/doc_creator_cubit.dart';

/// Tab "Nhập JSON": dán / sửa JSON, "Kiểm tra & áp dụng", "Lấy lại từ template".
/// [controller] do trang giữ để nút "Tiếp tục" áp dụng được JSON chưa kiểm tra.
class JsonTab extends StatelessWidget {
  const JsonTab({super.key, required this.controller, required this.check});

  final TextEditingController controller;
  final ValidationResult? check;

  Future<void> _paste(BuildContext context) async {
    final cubit = context.read<DocCreatorCubit>();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null) return;
    controller.text = text;
    cubit.clearJsonCheck();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocCreatorCubit>();
    final result = check;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Tải file .json: dùng package file_picker ở tầng app rồi gán nội dung vào controller.
            OutlinedButton.icon(
              key: const Key('weekly_docs_creator_json_paste_button'),
              onPressed: () => _paste(context),
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: const Text('Dán từ clipboard'),
            ),
            FilledButton(
              key: const Key('weekly_docs_creator_json_apply_button'),
              onPressed: () => cubit.applyJsonText(controller.text),
              child: const Text('Kiểm tra & áp dụng'),
            ),
            OutlinedButton(
              key: const Key('weekly_docs_creator_json_reset_button'),
              onPressed: cubit.resetFromTemplate,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textMuted),
              child: const Text('Lấy lại từ template'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: AppColors.codeBg, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.codeBorder)),
            child: TextField(
              key: const Key('weekly_docs_creator_json_field'),
              controller: controller,
              expands: true,
              maxLines: null,
              minLines: null,
              autocorrect: false,
              enableSuggestions: false,
              style: AppText.mono,
              cursorColor: AppColors.goldLight,
              onChanged: (_) => cubit.clearJsonCheck(),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
                hintText: 'Dán nội dung JSON vào đây',
              ),
            ),
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 10),
          JsonCheckPanel(check: result),
        ],
      ],
    );
  }
}

/// Kết quả "Kiểm tra & áp dụng": hợp lệ (xanh) / chưa hợp lệ (đỏ), bấm lỗi để nhảy tới khối.
class JsonCheckPanel extends StatelessWidget {
  const JsonCheckPanel({super.key, required this.check});

  final ValidationResult check;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocCreatorCubit>();
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: check.isValid ? AppColors.successBg : AppColors.errorBg, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              check.isValid ? 'Hợp lệ, đã dựng tài liệu từ JSON${check.warnings.isEmpty ? '' : ' (có lưu ý)'}' : 'JSON chưa hợp lệ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: check.isValid ? AppColors.success : AppColors.primary),
            ),
            const SizedBox(height: 4),
            for (final issue in [...check.errors, ...check.warnings])
              InkWell(
                onTap: issue.location == null ? null : () => cubit.jumpToIssue(issue),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• $issue', style: const TextStyle(fontSize: 12.5, color: AppColors.textInk))),
              ),
          ],
        ),
      ),
    );
  }
}
