import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_tokens.dart';
import '../../cubits/doc_creator_cubit.dart';
import 'creator_preview.dart';

const creatorStepLabels = ['Chọn template', 'Soạn nội dung', 'Xuất bản'];

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// Thanh trên màn soạn: đóng · tiêu đề · thanh bước · xem trước (màn hẹp) · trạng thái lưu · tên file.
class CreatorHeader extends StatelessWidget {
  const CreatorHeader({super.key, required this.state, required this.wide, required this.isEditRoute, required this.onClose});

  final DocCreatorState state;
  final bool wide;

  /// Mở bằng route sửa (tiêu đề "Sửa tài liệu").
  final bool isEditRoute;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
      decoration: const BoxDecoration(color: AppColors.cardSurface, border: Border(bottom: BorderSide(color: AppColors.borderLight))),
      child: Row(
        children: [
          IconButton(key: const Key('weekly_docs_creator_close_button'), tooltip: 'Đóng', icon: const Icon(Icons.close_rounded), onPressed: onClose),
          const SizedBox(width: 4),
          SizedBox(
            width: wide ? 230 : 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin › Theo tuần', style: AppText.caption),
                Text(
                  isEditRoute ? 'Sửa ${state.category.label.toLowerCase()}' : 'Tạo ${state.category.label.toLowerCase()} mới',
                  style: AppText.heading,
                ),
              ],
            ),
          ),
          Expanded(
            child: wide ? CreatorStepper(state: state) : Center(child: Text('Bước ${state.step}/3 · ${creatorStepLabels[state.step - 1]}', style: AppText.label)),
          ),
          if (!wide) const _PreviewSheetButton(),
          _SaveStatus(state: state),
          if (wide)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.borderLight)),
              child: Text(state.fileName, style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// Màn hẹp: mở khung xem trước trong bottom sheet (dựng lại theo cubit).
class _PreviewSheetButton extends StatelessWidget {
  const _PreviewSheetButton();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const Key('weekly_docs_creator_preview_button'),
      onPressed: () {
        final cubit = context.read<DocCreatorCubit>();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.previewBg,
          builder: (_) => BlocProvider.value(value: cubit, child: const FractionallySizedBox(heightFactor: 0.9, child: CreatorPreview())),
        );
      },
      icon: const Icon(Icons.visibility_outlined),
      label: const Text('Xem trước'),
    );
  }
}

/// "Đang lưu…" / "Đã lưu nháp · 10:42" / "Chưa lưu được [Thử lại]" / "Có thay đổi chưa phát hành".
class _SaveStatus extends StatelessWidget {
  const _SaveStatus({required this.state});

  final DocCreatorState state;

  @override
  Widget build(BuildContext context) {
    final savedAt = state.savedAt;
    final text = switch (state.saveState) {
      SaveState.saving => 'Đang lưu…',
      SaveState.saved => savedAt == null ? 'Đã lưu nháp' : 'Đã lưu nháp · ${_twoDigits(savedAt.hour)}:${_twoDigits(savedAt.minute)}',
      SaveState.error => 'Chưa lưu được',
      SaveState.idle => state.dirtyRelease ? 'Có thay đổi chưa phát hành' : '',
    };
    if (text.isEmpty) return const SizedBox.shrink();
    final isError = state.saveState == SaveState.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: AppText.caption.copyWith(color: isError ? AppColors.primary : AppColors.textMuted)),
        if (isError)
          TextButton(key: const Key('weekly_docs_creator_retry_save_button'), onPressed: context.read<DocCreatorCubit>().saveNow, child: const Text('Thử lại')),
        const SizedBox(width: AppSpace.md),
      ],
    );
  }
}

/// Thanh 3 bước; khi đang sửa (chưa xuất bản) bấm được để nhảy bước.
class CreatorStepper extends StatelessWidget {
  const CreatorStepper({super.key, required this.state});

  final DocCreatorState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          _StepDot(number: i + 1, state: state),
          if (i < 2)
            Container(
              width: 48,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: i + 1 < state.step ? AppColors.primary : AppColors.borderStrong,
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, required this.state});

  final int number;
  final DocCreatorState state;

  @override
  Widget build(BuildContext context) {
    final n = number;
    final done = n < state.step || (n == 3 && state.published);
    final active = n == state.step && !done;
    final canTap = state.isEdit && !state.published && n != state.step;
    return InkWell(
      key: Key('weekly_docs_creator_step_${n}_button'),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: canTap ? () => context.read<DocCreatorCubit>().goToStep(n) : null,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primary : AppColors.cardSurface,
                border: Border.all(color: done || active ? AppColors.primary : AppColors.borderStrong, width: 1.5),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary)
                  : Text('$n', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: active ? AppColors.primary : AppColors.textDisabled)),
            ),
            const SizedBox(width: 10),
            Text(
              creatorStepLabels[n - 1],
              style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: active || done ? AppColors.textInk : AppColors.textDisabled),
            ),
          ],
        ),
      ),
    );
  }
}
