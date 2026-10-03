import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_tokens.dart';
import '../../cubits/doc_creator_cubit.dart';

/// Thanh dưới màn soạn: "← Quay lại" · gợi ý của bước · "Tiếp tục →" / "Xuất bản".
class CreatorFooter extends StatelessWidget {
  const CreatorFooter({super.key, required this.state, required this.onForward});

  final DocCreatorState state;
  final VoidCallback onForward;

  String get _hint => switch (state.step) {
        1 => 'Template chỉ là khung: mọi section và khối đều sửa, thêm, xoá được ở bước sau.',
        2 => state.isHtmlDoc
            ? 'Bấm "Đổi file" để thay nội dung; khung "Hiển thị thử" chạy nguyên file.'
            : (state.jsonMode ? 'Dán JSON rồi bấm "Kiểm tra & áp dụng".' : 'Chọn khối bên trái để sửa; khung xem trước tô vàng khối đang sửa.'),
        _ => state.validation.isValid ? 'Kiểm tra xong, có thể xuất bản.' : 'Sửa các lỗi đỏ trước khi xuất bản.',
      };

  String get _forwardLabel {
    if (state.step != 3) return 'Tiếp tục →';
    if (state.isPublishedDoc) return 'Cập nhật bản phát hành';
    return state.scheduleMode ? 'Hẹn giờ xuất bản' : 'Xuất bản';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
      decoration: const BoxDecoration(color: AppColors.cardSurface, border: Border(top: BorderSide(color: AppColors.borderLight))),
      child: Row(
        children: [
          Visibility(
            visible: state.step > 1 && !state.published,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: OutlinedButton(
              key: const Key('weekly_docs_creator_back_button'),
              onPressed: context.read<DocCreatorCubit>().back,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textInk),
              child: const Text('← Quay lại'),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(_hint, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 13))),
          const SizedBox(width: AppSpace.md),
          if (!state.published)
            FilledButton(
              key: const Key('weekly_docs_creator_forward_button'),
              onPressed: state.canForward ? onForward : null,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22)),
              child: state.isPublishing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                  : Text(_forwardLabel),
            ),
        ],
      ),
    );
  }
}
