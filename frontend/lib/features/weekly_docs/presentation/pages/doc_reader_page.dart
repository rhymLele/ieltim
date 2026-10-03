// doc_reader_page.dart — U2: đọc tài liệu (Slide / Doc), mobile + desktop. Bố cục: file 6 mục U2.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_routes.dart';
import '../../core/app_tokens.dart';
import '../../domain/entities/weekly_doc.dart';
import '../cubits/doc_reader_cubit.dart';
import '../cubits/ui_state.dart';
import '../widgets/block_view.dart';
import '../widgets/common_widgets.dart';
import '../widgets/reader/doc_body.dart';
import '../widgets/reader/fullscreen_slides.dart';
import '../widgets/reader/html_reader_view.dart';
import '../widgets/reader/reader_chrome.dart';
import '../widgets/reader/slide_views.dart';

class DocReaderPage extends StatelessWidget {
  const DocReaderPage({super.key, required this.docId, this.isAdminPreview = false});

  final String docId;

  /// Admin xem trước: đọc bản đang soạn (mọi trạng thái), không ghi tiến độ.
  final bool isAdminPreview;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DocReaderCubit(docId: docId, isAdminPreview: isAdminPreview)..load(),
      child: _DocReaderView(docId: docId, isAdminPreview: isAdminPreview),
    );
  }
}

class _DocReaderView extends StatefulWidget {
  const _DocReaderView({required this.docId, required this.isAdminPreview});

  final String docId;
  final bool isAdminPreview;

  @override
  State<_DocReaderView> createState() => _DocReaderViewState();
}

class _DocReaderViewState extends State<_DocReaderView> {
  PageController? _pages;
  final _docScroll = ScrollController();
  List<GlobalKey> _sectionKeys = const [];

  /// Tài liệu mà [_pages] / [_sectionKeys] đang gắn với (tải lại thì tạo mới).
  WeeklyDoc? _boundDoc;

  DocReaderCubit get _cubit => context.read<DocReaderCubit>();

  @override
  void initState() {
    super.initState();
    _docScroll.addListener(_onDocScroll);
  }

  @override
  void dispose() {
    _pages?.dispose();
    _docScroll.dispose();
    super.dispose();
  }

  void _bind(DocReaderState state) {
    final doc = state.doc;
    if (doc == null || identical(doc, _boundDoc)) return;
    _boundDoc = doc;
    _pages?.dispose();
    _pages = PageController(initialPage: state.index);
    _sectionKeys = List.generate(doc.sections.length, (_) => GlobalKey());
  }

  void _goTo(int i) {
    final slides = _cubit.state.slides;
    if (i < 0 || i >= slides.length) return;
    final pages = _pages;
    if (pages == null || !pages.hasClients) {
      _cubit.showSlide(i);
      return;
    }
    final duration = motion(context, 300);
    if (duration == Duration.zero) {
      pages.jumpToPage(i);
    } else {
      pages.animateToPage(i, duration: duration, curve: Curves.easeOutCubic);
    }
  }

  void _setView(DocViewMode view) {
    if (view == DocViewMode.slide) {
      // PageView mới gắn vào sẽ mở đúng slide đang xem.
      _pages?.dispose();
      _pages = PageController(initialPage: _cubit.state.index);
    }
    _cubit.setView(view);
  }

  /// Đếm số section đã cuộn qua (đỉnh section đã lên khỏi nửa màn hình).
  void _onDocScroll() {
    final half = MediaQuery.sizeOf(context).height * 0.5;
    var seen = 0;
    for (final key in _sectionKeys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy < half) seen++;
    }
    _cubit.markDocSeen(seen);
  }

  /// Rời màn đọc: quay lại màn trước; mở thẳng bằng link thì về danh sách (admin xem trước: về danh sách admin).
  void _close() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(widget.isAdminPreview ? AppRoutes.adminWeeklyDocs : AppRoutes.weekly);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DocReaderCubit, DocReaderState>(
          listenWhen: (prev, curr) => curr.completion != null && !identical(prev.completion, curr.completion),
          listener: (context, state) => context.go(AppRoutes.weeklyDocDone(widget.docId), extra: state.completion),
        ),
        BlocListener<DocReaderCubit, DocReaderState>(
          listenWhen: (prev, curr) => prev.closeRequests != curr.closeRequests,
          listener: (_, _) => _close(),
        ),
        BlocListener<DocReaderCubit, DocReaderState>(
          listenWhen: (prev, curr) => curr.notice != null && prev.notice?.id != curr.notice?.id,
          listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.notice?.message ?? ''),
            action: SnackBarAction(label: 'Thử lại', onPressed: _cubit.complete),
          )),
        ),
      ],
      child: BlocBuilder<DocReaderCubit, DocReaderState>(builder: (context, state) {
        final doc = state.doc;
        if (state.status == LoadStatus.failure) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: EmptyState(
              isError: true,
              message: state.errorMessage ?? 'Không tải được tài liệu. Kiểm tra mạng rồi thử lại.',
              actionLabel: 'Thử lại',
              onAction: _cubit.load,
            ),
          );
        }
        if (state.status == LoadStatus.loading || doc == null) return const ReaderLoadingView();
        if (doc.isHtml) {
          return HtmlReaderView(
            doc: doc,
            isPreview: widget.isAdminPreview,
            isCompleting: state.isCompleting,
            onBack: _close,
            onComplete: _cubit.complete,
          );
        }
        _bind(state);
        return _ReaderLayout(
          state: state,
          deck: SlideDeck(
            controller: _pages,
            slides: state.slides,
            index: state.index,
            quiz: QuizState(answers: state.answers, onAnswer: _cubit.answer),
            isPreview: widget.isAdminPreview,
            isCompleting: state.isCompleting,
            onPageChanged: _cubit.showSlide,
            onGoTo: _goTo,
            onComplete: _cubit.complete,
          ),
          docScroll: _docScroll,
          sectionKeys: _sectionKeys,
          onBack: _close,
          onViewChanged: _setView,
        );
      }),
    );
  }
}

/// Khung màn đọc tài liệu có cấu trúc: thanh trên, Slide hoặc Doc, thanh dưới (điện thoại), phím ← → / Space.
class _ReaderLayout extends StatelessWidget {
  const _ReaderLayout({
    required this.state,
    required this.deck,
    required this.docScroll,
    required this.sectionKeys,
    required this.onBack,
    required this.onViewChanged,
  });

  final DocReaderState state;
  final SlideDeck deck;
  final ScrollController docScroll;
  final List<GlobalKey> sectionKeys;
  final VoidCallback onBack;
  final ValueChanged<DocViewMode> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final doc = state.doc!;
    final isSlide = state.view == DocViewMode.slide;
    return LayoutBuilder(builder: (context, c) {
      final desktop = c.maxWidth >= AppBreakpoints.desktop;
      final landscapePhone = !desktop && MediaQuery.orientationOf(context) == Orientation.landscape;
      if (isSlide && landscapePhone) return FullscreenSlides(deck: deck, onExit: () => onViewChanged(DocViewMode.doc));
      return Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowRight): _NextIntent(),
          SingleActivator(LogicalKeyboardKey.space): _NextIntent(),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _PrevIntent(),
        },
        child: Actions(
          actions: {
            _NextIntent: CallbackAction<_NextIntent>(onInvoke: (_) {
              if (isSlide) deck.onGoTo(deck.index + 1);
              return null;
            }),
            _PrevIntent: CallbackAction<_PrevIntent>(onInvoke: (_) {
              if (isSlide) deck.onGoTo(deck.index - 1);
              return null;
            }),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: isSlide ? AppColors.readerBg : AppColors.background,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (deck.isPreview) const PreviewBanner(),
                    ReaderHeader(
                      doc: doc,
                      desktop: desktop,
                      view: state.view,
                      readFraction: state.readFraction,
                      onBack: onBack,
                      onViewChanged: onViewChanged,
                    ),
                    Expanded(
                      child: isSlide
                          ? (desktop ? DesktopSlideBody(deck: deck) : MobileSlideBody(deck: deck))
                          : DocBody(
                              doc: doc,
                              desktop: desktop,
                              scrollController: docScroll,
                              sectionKeys: sectionKeys,
                              quiz: deck.quiz,
                              isPreview: deck.isPreview,
                              isCompleting: deck.isCompleting,
                              onComplete: deck.onComplete,
                            ),
                    ),
                    if (isSlide && !desktop && deck.slides.isNotEmpty) MobileSlideFooter(deck: deck),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _NextIntent extends Intent {
  const _NextIntent();
}

class _PrevIntent extends Intent {
  const _PrevIntent();
}
