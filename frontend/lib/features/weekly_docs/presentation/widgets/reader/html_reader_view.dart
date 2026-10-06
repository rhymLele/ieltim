import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/annotate/annotate.dart';
import '../../../core/app_tokens.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../annotate/html_reader_annotations.dart';
import '../common_widgets.dart';
import '../html_frame.dart';
import 'reader_chrome.dart';

/// Tài liệu HTML (file 9): thanh trên (quay lại · tên · Hoàn thành) + nguyên file.
/// File tự có nút chuyển slide; không có thanh tiến độ hay công tắc Slide / Doc.
/// Có [annotations] (người học): bôi đen trong file → hộp thoại, highlight, vẽ / ghim ghi chú đè lên file.
class HtmlReaderView extends StatelessWidget {
  const HtmlReaderView({
    super.key,
    required this.doc,
    required this.isPreview,
    required this.isCompleting,
    required this.onBack,
    required this.onComplete,
    this.annotations,
    this.onOpenMyNotes,
  });

  final WeeklyDoc doc;
  final bool isPreview;
  final bool isCompleting;
  final VoidCallback onBack;
  final VoidCallback onComplete;
  final HtmlReaderAnnotations? annotations;
  final VoidCallback? onOpenMyNotes;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= AppBreakpoints.desktop;
    final html = doc.html ?? '';
    final ann = annotations;
    final page = Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (isPreview) const PreviewBanner(),
            Container(
              height: desktop ? 64 : 56,
              padding: EdgeInsets.symmetric(horizontal: desktop ? 24 : 8),
              decoration: const BoxDecoration(color: AppColors.background, border: Border(bottom: BorderSide(color: AppColors.borderLight))),
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
                  if (onOpenMyNotes case final open?)
                    IconButton(
                      key: const Key('weekly_docs_my_notes_button'),
                      tooltip: 'Ghi chú của tôi',
                      icon: const Icon(Icons.bookmarks_outlined),
                      onPressed: open,
                    ),
                  const SizedBox(width: AppSpace.sm),
                  CompleteButton(isPreview: isPreview, isCompleting: isCompleting, onPressed: onComplete),
                ],
              ),
            ),
            if (ann != null && html.isNotEmpty)
              HtmlAnnotationBar(
                annotations: ann,
                compact: width < 600,
                onOpenNotes: () {
                  final controller = ann.slideNotes.active;
                  if (controller == null) return;
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.cardSurface,
                    builder: (_) => FractionallySizedBox(heightFactor: 0.6, child: NotesPanel(controller: controller)),
                  );
                },
              ),
            Expanded(
              child: html.isEmpty
                  ? const EmptyState(message: 'Tài liệu chưa có nội dung')
                  : ColoredBox(
                      color: AppColors.cardSurface,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: HtmlFrame(
                              key: ann?.frameKey,
                              html: html,
                              autofocus: true,
                              onBridgeMessage: ann?.onMessage,
                              bridge: ann?.bridge,
                              onLoaded: ann?.onLoaded,
                            ),
                          ),
                          if (ann != null) Positioned.fill(child: HtmlAnnotationOverlay(annotations: ann)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
    return ann == null ? page : BlocProvider.value(value: ann.cubit, child: page);
  }
}
