// doc_complete_page.dart — U3: hoàn thành tài liệu. Bố cục: file 6 mục U3.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_routes.dart';
import '../../core/app_tokens.dart';
import '../cubits/doc_complete_cubit.dart';
import '../widgets/complete/jumping_koi.dart';
import '../widgets/complete/stage_progress_pill.dart';

class DocCompletePage extends StatelessWidget {
  const DocCompletePage({super.key, required this.args});

  final DocCompleteArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DocCompleteCubit(),
      child: BlocListener<DocCompleteCubit, DocCompleteState>(
        listenWhen: (prev, curr) => curr.notice != null && prev.notice?.id != curr.notice?.id,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.notice?.message ?? ''))),
        child: _CompleteLayout(args: args),
      ),
    );
  }
}

/// Desktop: hộp giữa màn trên nền mờ. Điện thoại: toàn màn, cuộn được.
class _CompleteLayout extends StatelessWidget {
  const _CompleteLayout({required this.args});

  final DocCompleteArgs args;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final content = _CompleteContent(args: args);
    if (desktop) {
      return Scaffold(
        backgroundColor: AppColors.textInk.withAlpha(115),
        body: Center(
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(AppSpace.xxxl),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.slide)),
            child: content,
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpace.xxl), child: content))),
    );
  }
}

class _CompleteContent extends StatelessWidget {
  const _CompleteContent({required this.args});

  final DocCompleteArgs args;

  void _backToList(BuildContext context) => context.go(AppRoutes.weekly);

  @override
  Widget build(BuildContext context) {
    final result = args.result;
    final next = args.nextDoc;
    final vocabCount = args.doc.allVocab.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const JumpingKoi(),
        const SizedBox(height: AppSpace.lg),
        Text(
          'Hoàn thành ${args.doc.numberLabel}!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.textInk),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          result.completedNow ? 'Cá chép tiến thêm một chặng trên thác Vũ Môn.' : 'Bạn đã học xong tài liệu này trước đó.',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpace.lg),
        StageProgressPill(result: result),
        const SizedBox(height: AppSpace.xxl),
        if (vocabCount > 0) ...[
          _SaveVocabButton(docId: args.doc.id, vocabCount: vocabCount),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            key: const Key('weekly_docs_complete_next_button'),
            onPressed: next == null ? () => _backToList(context) : () => context.go(AppRoutes.weeklyDoc(next.id)),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card))),
            child: Text(
              next == null ? 'Về danh sách tuần' : '${next.isHomework ? 'Làm' : 'Học'} ${next.numberLabel} →',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        if (next != null) ...[
          const SizedBox(height: 6),
          TextButton(onPressed: () => _backToList(context), child: const Text('Về danh sách tuần')),
        ],
      ],
    );
  }
}

class _SaveVocabButton extends StatelessWidget {
  const _SaveVocabButton({required this.docId, required this.vocabCount});

  final String docId;
  final int vocabCount;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DocCompleteCubit>().state;
    final saved = state.savedCount != null;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        key: const Key('weekly_docs_complete_save_vocab_button'),
        onPressed: state.isSaving || saved ? null : () => context.read<DocCompleteCubit>().saveVocab(docId),
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card))),
        child: Text(saved ? 'Đã lưu $vocabCount từ vào Sổ từ' : (state.isSaving ? 'Đang lưu…' : 'Lưu $vocabCount từ vựng của bài vào Sổ từ')),
      ),
    );
  }
}
