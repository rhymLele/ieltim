import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../block_view.dart';
import '../common_widgets.dart';
import '../doc_renderers.dart';

/// Kiểu Doc: các section nối liền thành trang cuộn dọc, cuối trang có "Đánh dấu đã học xong".
class DocBody extends StatelessWidget {
  const DocBody({
    super.key,
    required this.doc,
    required this.desktop,
    required this.scrollController,
    required this.sectionKeys,
    required this.quiz,
    required this.isPreview,
    required this.isCompleting,
    required this.onComplete,
  });

  final WeeklyDoc doc;
  final bool desktop;
  final ScrollController scrollController;

  /// Key của từng section để đo đã cuộn qua bao nhiêu section.
  final List<GlobalKey> sectionKeys;
  final QuizState quiz;
  final bool isPreview;
  final bool isCompleting;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: desktop
          ? const EdgeInsets.symmetric(vertical: 32, horizontal: 24)
          : EdgeInsets.fromLTRB(16, 16, 16, 28 + MediaQuery.paddingOf(context).bottom),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  radius: AppRadius.cardLg,
                  padding: EdgeInsets.all(desktop ? 40 : 20),
                  child: DocContent(doc: doc, scale: desktop ? BlockScale.docDesktop : BlockScale.docMobile, quiz: quiz, sectionKeys: sectionKeys),
                ),
                const SizedBox(height: AppSpace.lg),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    key: const Key('weekly_docs_reader_mark_done_button'),
                    onPressed: isCompleting ? null : onComplete,
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card))),
                    child: Text(isPreview ? 'Đóng xem trước' : 'Đánh dấu đã học xong', style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
