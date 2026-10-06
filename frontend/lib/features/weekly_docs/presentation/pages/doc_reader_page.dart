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
import '../../../annotate/presentation/cubits/doc_annotations_cubit.dart';
import '../widgets/annotate/html_reader_annotations.dart';
import '../widgets/annotate/my_notes_panel.dart';
import '../widgets/annotate/reader_annotations.dart';
import '../widgets/block_view.dart';
import '../widgets/common_widgets.dart';
import '../widgets/reader/doc_body.dart';
import '../widgets/reader/fullscreen_slides.dart';
import '../widgets/reader/html_reader_view.dart';
import '../widgets/reader/reader_chrome.dart';
import '../widgets/reader/slide_views.dart';

class DocReaderPage extends StatelessWidget {
  const DocReaderPage({super.key, required this.docId, this.isAdminPreview = false, this.initialBlock});

  final String docId;

  /// Admin xem trước: đọc bản đang soạn (mọi trạng thái), không ghi tiến độ.
  final bool isAdminPreview;

  /// Khối cần mở tới khi tải xong (`?block=`, từ nguồn trong Sổ từ).
  final String? initialBlock;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DocReaderCubit(docId: docId, isAdminPreview: isAdminPreview)..load(),
      child: _DocReaderView(docId: docId, isAdminPreview: isAdminPreview, initialBlock: initialBlock),
    );
  }
}

class _DocReaderView extends StatefulWidget {
  const _DocReaderView({required this.docId, required this.isAdminPreview, this.initialBlock});

  final String docId;
  final bool isAdminPreview;
  final String? initialBlock;

  @override
  State<_DocReaderView> createState() => _DocReaderViewState();
}

class _DocReaderViewState extends State<_DocReaderView> with WidgetsBindingObserver {
  PageController? _pages;

  /// PageView slide giữ nguyên khi vùng bôi đen bọc ngoài dựng lại (không nhảy về slide đầu).
  final _pagerKey = GlobalKey(debugLabel: 'weekly_docs_slides');
  final _docScroll = ScrollController();
  List<GlobalKey> _sectionKeys = const [];

  /// Tài liệu mà [_pages] / [_sectionKeys] đang gắn với (tải lại thì tạo mới).
  WeeklyDoc? _boundDoc;

  /// Bôi đen, highlight, ghi chú slide của người học (không có khi admin xem trước).
  ReaderAnnotations? _annotations;

  /// Như trên, cho tài liệu HTML (cầu nối với script trong file).
  HtmlReaderAnnotations? _htmlAnnotations;

  DocReaderCubit get _cubit => context.read<DocReaderCubit>();

  @override
  void initState() {
    super.initState();
    _docScroll.addListener(_onDocScroll);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _annotations?.dispose(); // đóng cubit = gửi nốt thay đổi đang chờ
    _htmlAnnotations?.dispose();
    _pages?.dispose();
    _docScroll.dispose();
    super.dispose();
  }

  /// App vào nền: gửi ngay ghi chú đang chờ.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _annotations?.cubit.flush();
      _htmlAnnotations?.cubit.flush();
    }
  }

  void _bind(DocReaderState state) {
    final doc = state.doc;
    if (doc == null || identical(doc, _boundDoc)) return;
    _boundDoc = doc;
    _pages?.dispose();
    _pages = PageController(initialPage: state.index);
    _sectionKeys = List.generate(doc.sections.length, (_) => GlobalKey());
    _annotations?.dispose();
    _htmlAnnotations?.dispose();
    _annotations = widget.isAdminPreview || doc.isHtml ? null : ReaderAnnotations(doc: doc, docVersion: state.docVersion, hostContext: () => context);
    _htmlAnnotations = widget.isAdminPreview || !doc.isHtml ? null : HtmlReaderAnnotations(doc: doc, docVersion: state.docVersion, hostContext: () => context);
    final slides = state.slides;
    final index = state.index;
    if (_annotations != null && slides.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _annotations?.activate(slides[index.clamp(0, slides.length - 1)]);
      });
    }
    final block = widget.initialBlock;
    if (block != null && _annotations != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openBlock(block);
      });
    }
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
    if (view == DocViewMode.doc) _annotations?.slideNotes.stopDrawing(); // kiểu Doc không có lớp vẽ
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

  /// "Ghi chú của tôi": desktop là khung bên phải, điện thoại là bottom sheet.
  void _openMyNotes() {
    final ann = _annotations;
    final html = _htmlAnnotations;
    final cubit = ann?.cubit ?? html?.cubit;
    if (cubit == null) return;
    final slides = _cubit.state.slides;
    Widget panel(BuildContext sheetContext) => BlocProvider.value(
          value: cubit,
          child: MyNotesPanel(
            blocks: ann?.blocks ?? const [NoteBlock(blockKey: htmlBlockKey, label: 'Tài liệu HTML', text: '')],
            changedIds: html?.missing ?? const {},
            slideLabels: ann != null
                ? {for (final (i, page) in slides.indexed) slideKeyOf(page): 'Slide ${i + 1}'}
                : {for (final key in cubit.state.slides.keys) key: htmlSlideLabel(key)},
            onOpenBlock: (key) {
              Navigator.of(sheetContext).pop();
              if (ann != null) _openBlock(key);
            },
            onOpenSlide: (key) {
              Navigator.of(sheetContext).pop();
              if (ann != null) _openSlide(key);
            },
          ),
        );
    if (MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: AppColors.cardSurface,
            child: SizedBox(width: 400, height: double.infinity, child: _MyNotesFrame(child: panel(dialogContext))),
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.cardSurface,
        builder: (sheetContext) => FractionallySizedBox(heightFactor: 0.75, child: _MyNotesFrame(child: panel(sheetContext))),
      );
    }
  }

  /// Tới khối có highlight: kiểu Slide thì sang slide chứa khối, kiểu Doc thì cuộn tới.
  void _openBlock(String key) {
    final state = _cubit.state;
    if (state.view == DocViewMode.slide) {
      final i = state.slides.indexWhere((p) => p.blocks.any((b) => blockKey(p.sectionIndex, b.$1, b.$2) == key));
      if (i >= 0) _goTo(i);
      return;
    }
    final target = _annotations?.registry.keyFor(key).currentContext;
    if (target != null) Scrollable.ensureVisible(target, duration: motion(context, 300), alignment: 0.2);
  }

  /// Tới slide có ghi chú (đang ở kiểu Doc thì chuyển sang Slide).
  void _openSlide(String key) {
    final state = _cubit.state;
    final i = state.slides.indexWhere((p) => slideKeyOf(p) == key);
    if (i < 0) return;
    if (state.view == DocViewMode.slide) {
      _goTo(i);
    } else {
      _cubit.showSlide(i);
      _setView(DocViewMode.slide);
    }
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
        // Slide đang xem đổi: thanh công cụ / ghi chú trỏ sang slide mới.
        BlocListener<DocReaderCubit, DocReaderState>(
          listenWhen: (prev, curr) => prev.index != curr.index && curr.slides.isNotEmpty,
          listener: (_, state) => _annotations?.activate(state.slides[state.index.clamp(0, state.slides.length - 1)]),
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
        _bind(state);
        if (doc.isHtml) {
          return HtmlReaderView(
            doc: doc,
            isPreview: widget.isAdminPreview,
            isCompleting: state.isCompleting,
            onBack: _close,
            onComplete: _cubit.complete,
            annotations: _htmlAnnotations,
            onOpenMyNotes: _htmlAnnotations == null ? null : _openMyNotes,
          );
        }
        final ann = _annotations;
        Widget layout({Set<int> marked = const {}, bool drawing = false}) => _ReaderLayout(
              state: state,
              deck: SlideDeck(
                controller: _pages,
                pagerKey: _pagerKey,
                slides: state.slides,
                index: state.index,
                quiz: QuizState(answers: state.answers, onAnswer: _cubit.answer),
                isPreview: widget.isAdminPreview,
                isCompleting: state.isCompleting,
                onPageChanged: _cubit.showSlide,
                onGoTo: _goTo,
                onComplete: _cubit.complete,
                // Đang vẽ thì khoá vuốt để nét bút không kéo trang đi.
                physics: drawing ? const NeverScrollableScrollPhysics() : null,
                selectable: ann?.selectable,
                slideOverlay: ann?.slideOverlay,
                marked: marked,
              ),
              docScroll: _docScroll,
              sectionKeys: _sectionKeys,
              onBack: _close,
              onViewChanged: _setView,
              annotations: ann,
              drawing: drawing,
              onOpenMyNotes: _openMyNotes,
            );
        if (ann == null) return layout();
        return ann.scope(BlocConsumer<DocAnnotationsCubit, DocAnnotationsState>(
          listenWhen: (prev, curr) => !identical(prev.slideEpochs, curr.slideEpochs),
          listener: (_, annState) => ann.syncSlides(annState),
          buildWhen: (prev, curr) => !identical(prev.slides, curr.slides),
          builder: (_, _) => ListenableBuilder(
            listenable: ann.slideNotes,
            builder: (_, _) => layout(marked: ann.markedSlides(state.slides), drawing: ann.slideNotes.isDrawing),
          ),
        ));
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
    this.annotations,
    this.drawing = false,
    this.onOpenMyNotes,
  });

  final DocReaderState state;
  final SlideDeck deck;
  final ScrollController docScroll;
  final List<GlobalKey> sectionKeys;
  final VoidCallback onBack;
  final ValueChanged<DocViewMode> onViewChanged;

  /// null = admin xem trước (không có ghi chú).
  final ReaderAnnotations? annotations;

  /// Đang cầm bút: phím ← → / Space không chuyển slide.
  final bool drawing;
  final VoidCallback? onOpenMyNotes;

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
              if (isSlide && !drawing) deck.onGoTo(deck.index + 1);
              return null;
            }),
            _PrevIntent: CallbackAction<_PrevIntent>(onInvoke: (_) {
              if (isSlide && !drawing) deck.onGoTo(deck.index - 1);
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
                      actions: [
                        if (onOpenMyNotes case final open?)
                          IconButton(
                            key: const Key('weekly_docs_my_notes_button'),
                            tooltip: 'Ghi chú của tôi',
                            icon: const Icon(Icons.bookmarks_outlined),
                            onPressed: open,
                          ),
                      ],
                    ),
                    if (isSlide && annotations != null && deck.slides.isNotEmpty)
                      SlideAnnotationBar(notes: annotations!.slideNotes, compact: c.maxWidth < 600, showNotesButton: c.maxWidth < AppBreakpoints.adminWide),
                    Expanded(
                      child: isSlide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: desktop ? DesktopSlideBody(deck: deck) : MobileSlideBody(deck: deck)),
                                if (annotations != null && c.maxWidth >= AppBreakpoints.adminWide) SlideNotesColumn(notes: annotations!.slideNotes),
                              ],
                            )
                          : DocBody(
                              doc: doc,
                              desktop: desktop,
                              scrollController: docScroll,
                              sectionKeys: sectionKeys,
                              quiz: deck.quiz,
                              isPreview: deck.isPreview,
                              isCompleting: deck.isCompleting,
                              onComplete: deck.onComplete,
                              selectable: annotations?.selectable,
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

/// Khung "Ghi chú của tôi": tiêu đề + nút đóng + 3 tab.
class _MyNotesFrame extends StatelessWidget {
  const _MyNotesFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                const Expanded(child: Text('Ghi chú của tôi', style: AppText.heading)),
                IconButton(tooltip: 'Đóng', icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
