import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../common_widgets.dart';
import '../html_frame.dart';
import 'reader_chrome.dart';

/// Tài liệu HTML (file 9): thanh trên (quay lại · tên · Hoàn thành) + nguyên file.
/// File tự có nút chuyển slide; không có thanh tiến độ hay công tắc Slide / Doc.
class HtmlReaderView extends StatelessWidget {
  const HtmlReaderView({
    super.key,
    required this.doc,
    required this.isPreview,
    required this.isCompleting,
    required this.onBack,
    required this.onComplete,
  });

  final WeeklyDoc doc;
  final bool isPreview;
  final bool isCompleting;
  final VoidCallback onBack;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final html = doc.html ?? '';
    return Scaffold(
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
                  const SizedBox(width: AppSpace.sm),
                  CompleteButton(isPreview: isPreview, isCompleting: isCompleting, onPressed: onComplete),
                ],
              ),
            ),
            Expanded(
              child: html.isEmpty
                  ? const EmptyState(message: 'Tài liệu chưa có nội dung')
                  : ColoredBox(color: AppColors.cardSurface, child: HtmlFrame(html: html, autofocus: true)),
            ),
          ],
        ),
      ),
    );
  }
}
