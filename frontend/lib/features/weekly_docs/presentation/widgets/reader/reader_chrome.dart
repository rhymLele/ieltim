import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../common_widgets.dart';

/// Màn đang tải: khung xương thay cho nội dung.
class ReaderLoadingView extends StatelessWidget {
  const ReaderLoadingView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Padding(
          padding: EdgeInsets.all(AppSpace.lg),
          child: Column(
            children: [
              SkeletonBox(height: 28, width: 220, radius: AppRadius.sm),
              SizedBox(height: AppSpace.lg),
              Expanded(child: SkeletonBox(height: double.infinity, radius: AppRadius.slide)),
            ],
          ),
        ),
      );
}

/// Dải vàng trên cùng khi admin xem trước.
class PreviewBanner extends StatelessWidget {
  const PreviewBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: AppColors.tipBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Text('Bản xem trước · Không ghi tiến độ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warnText)),
      );
}

/// "Tuần 12 · Tài liệu 1" + tên tài liệu.
class ReaderTitleBlock extends StatelessWidget {
  const ReaderTitleBlock({super.key, required this.doc, required this.desktop});

  final WeeklyDoc doc;
  final bool desktop;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            desktop ? 'Theo tuần › Tuần ${doc.week} › Tài liệu ${doc.order}' : 'Tuần ${doc.week} · Tài liệu ${doc.order}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          Text(
            doc.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: desktop ? 18 : 14, fontWeight: FontWeight.w800, color: AppColors.textInk),
          ),
        ],
      );
}

/// Thanh trên màn đọc: quay lại · tên · công tắc Slide / Doc + thanh tiến độ.
class ReaderHeader extends StatelessWidget {
  const ReaderHeader({
    super.key,
    required this.doc,
    required this.desktop,
    required this.view,
    required this.readFraction,
    required this.onBack,
    required this.onViewChanged,
  });

  final WeeklyDoc doc;
  final bool desktop;
  final DocViewMode view;
  final double readFraction;
  final VoidCallback onBack;
  final ValueChanged<DocViewMode> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          SizedBox(
            height: desktop ? 64 : 56,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: desktop ? 24 : 8),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('weekly_docs_reader_back_button'),
                    tooltip: 'Quay lại',
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: ReaderTitleBlock(doc: doc, desktop: desktop)),
                  if (doc.meta.canSwitch)
                    ViewModeToggle(
                      value: view,
                      onChanged: onViewChanged,
                      iconOnly: !desktop,
                      order: desktop ? const [DocViewMode.doc, DocViewMode.slide] : const [DocViewMode.slide, DocViewMode.doc],
                    ),
                  SizedBox(width: desktop ? 0 : 8),
                ],
              ),
            ),
          ),
          PillProgress(value: readFraction, height: 3, track: AppColors.sidebar),
        ],
      ),
    );
  }
}

/// Nút "Hoàn thành" (hoặc "Đóng xem trước"), có vòng xoay khi đang gửi.
class CompleteButton extends StatelessWidget {
  const CompleteButton({super.key, required this.isPreview, required this.isCompleting, required this.onPressed, this.label, this.showArrow = false});

  final bool isPreview;
  final bool isCompleting;
  final VoidCallback onPressed;

  /// Nhãn khi không phải xem trước; mặc định "Hoàn thành".
  final String? label;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final text = isPreview ? 'Đóng xem trước' : (label ?? 'Hoàn thành');
    const spinner = SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary));
    return FilledButton(
      key: const Key('weekly_docs_reader_complete_button'),
      onPressed: isCompleting ? null : onPressed,
      style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: EdgeInsets.only(left: showArrow ? 20 : 18, right: showArrow ? 14 : 18)),
      child: showArrow
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text(text), const SizedBox(width: 6), if (isCompleting) spinner else const Icon(Icons.chevron_right_rounded, size: 20)],
            )
          : (isCompleting ? spinner : Text(text)),
    );
  }
}
