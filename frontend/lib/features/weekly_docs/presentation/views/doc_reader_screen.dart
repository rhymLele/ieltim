import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../../../core/widgets/dragon_loader.dart';
import '../../data/fake_weekly_docs_repository.dart';
import '../../domain/models/weekly_doc.dart';
import '../../domain/slide_splitter.dart';
import '../bloc/doc_reader_bloc.dart';
import '../blocks/block_context.dart';
import '../doc_theme.dart';
import '../widgets/doc_view.dart';
import '../widgets/slide_view.dart';

/// Màn đọc tài liệu: progress bar trên đầu, toggle Slide/Doc, body là
/// [DocView] hoặc [SlideView], hoàn thành → [DocCompleteScreen].
class DocReaderScreen extends StatelessWidget {
  const DocReaderScreen({super.key, required this.docId});

  final String docId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DocReaderBloc(repo: FakeWeeklyDocsRepository())
        ..add(LoadDoc(docId: docId)),
      child: const _DocReaderBody(),
    );
  }
}

class _DocReaderBody extends StatelessWidget {
  const _DocReaderBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocReaderBloc, DocReaderState>(
      builder: (context, state) {
        if (state.status == DocReaderStatus.loading ||
            state.status == DocReaderStatus.initial) {
          return const Center(child: DragonLoader());
        }
        if (state.status == DocReaderStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 40, color: Brand.textSecondary),
                const SizedBox(height: 12),
                Text(
                  state.error ?? 'Lỗi',
                  style: DocFonts.body().copyWith(color: Brand.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          );
        }
        if (!state.isReady || state.doc == null) {
          return const SizedBox.shrink();
        }

        final doc = state.doc!;
        final isMobile = MediaQuery.of(context).size.width < 768;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final slides = splitSlides(doc);

        return Column(
          children: [
            _ReaderHeader(
              doc: doc,
              viewMode: state.viewMode,
              progress: state.progress,
              currentSlide: state.currentSlide + 1,
              totalSlides: slides.length,
            ),
            Expanded(
              child: state.viewMode == DocViewMode.doc
                  ? _buildDocView(context, state, doc, isMobile)
                  : _buildSlideView(context, state, doc, isLandscape, isMobile),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocView(
    BuildContext context,
    DocReaderState state,
    WeeklyDoc doc,
    bool isMobile,
  ) {
    final base = _buildContext(context, state, doc);
    return DocView(
      doc: doc,
      base: base,
      isMobile: isMobile,
      completed: state.isCompleted,
      onComplete: _handleComplete(context),
    );
  }

  Widget _buildSlideView(
    BuildContext context,
    DocReaderState state,
    WeeklyDoc doc,
    bool isLandscape,
    bool isMobile,
  ) {
    final base = _buildContext(context, state, doc);
    return SlideView(
      doc: doc,
      base: base,
      currentSlide: state.currentSlide,
      onSlideChanged: (i) => context.read<DocReaderBloc>().add(SetSlide(index: i)),
      onComplete: _handleComplete(context),
      isLandscape: isLandscape,
    );
  }

  BlockContext _buildContext(
    BuildContext context,
    DocReaderState state,
    WeeklyDoc doc,
  ) {
    return BlockContext(
      mode: state.viewMode == DocViewMode.doc ? RenderMode.doc : RenderMode.slide,
      onQuizAnswer: (blockKey, idx) =>
          context.read<DocReaderBloc>().add(AnswerQuiz(blockKey: blockKey, selectedIndex: idx)),
      quizAnswerFor: (blockKey) => state.quizAnswers[blockKey],
    );
  }

  VoidCallback _handleComplete(BuildContext context) {
    return () {
      context.read<DocReaderBloc>().add(const CompleteDoc());
      final docId = context.read<DocReaderBloc>().state.doc?.id ?? '';
      final week = context.read<DocReaderBloc>().state.doc?.meta.week ?? 1;
      context.pushReplacement('/weekly/complete?docId=$docId&week=$week');
    };
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({
    required this.doc,
    required this.viewMode,
    required this.progress,
    required this.currentSlide,
    required this.totalSlides,
  });

  final WeeklyDoc doc;
  final DocViewMode viewMode;
  final double progress;
  final int currentSlide;
  final int totalSlides;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final canSwitch = doc.meta.allowsSwitch;

    return Container(
      color: Brand.surface,
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, 12, isMobile ? 16 : 32, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Brand.textPrimary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.meta.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DocFonts.title(size: isMobile ? 15 : 17),
                    ),
                    if (doc.meta.skill != null)
                      Text(
                        'Tuần ${doc.meta.week} · ${doc.meta.skill}',
                        style: DocFonts.body(size: 11)
                            .copyWith(color: Brand.textSecondary),
                      ),
                  ],
                ),
              ),
              if (canSwitch)
                _ViewToggle(
                  current: viewMode,
                  onChanged: (mode) =>
                      context.read<DocReaderBloc>().add(SwitchViewMode(mode: mode)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Brand.border,
              valueColor: const AlwaysStoppedAnimation(Brand.primary),
            ),
          ),
          if (viewMode == DocViewMode.slide)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$currentSlide / $totalSlides',
                  style: DocFonts.body(size: 11)
                      .copyWith(color: Brand.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.current, required this.onChanged});

  final DocViewMode current;
  final ValueChanged<DocViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Brand.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Brand.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton(DocViewMode.slide, Icons.photo_size_select_actual),
          _toggleButton(DocViewMode.doc, Icons.description_outlined),
        ],
      ),
    );
  }

  Widget _toggleButton(DocViewMode mode, IconData icon) {
    final isActive = current == mode;
    return InkWell(
      onTap: () => onChanged(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Brand.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : Brand.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              mode == DocViewMode.slide ? 'Slide' : 'Doc',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Brand.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
