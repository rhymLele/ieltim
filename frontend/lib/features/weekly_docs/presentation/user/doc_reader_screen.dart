// doc_reader_screen.dart — U2: đọc tài liệu (Slide / Doc), mobile + desktop. Bố cục: file 6 mục U2.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_tokens.dart';
import '../../data/weekly_docs_repository.dart';
import '../../domain/weekly_doc.dart';
import '../widgets/block_view.dart';
import '../widgets/common_widgets.dart';
import '../widgets/doc_renderers.dart';
import '../widgets/html_frame.dart';
import 'doc_complete_screen.dart';

class DocReaderScreen extends StatefulWidget {
  const DocReaderScreen({super.key, required this.repo, required this.docId, this.previewDoc});

  final WeeklyDocsRepository repo;
  final String docId;

  /// Admin xem trước: truyền tài liệu trực tiếp, không ghi tiến độ.
  final WeeklyDoc? previewDoc;

  @override
  State<DocReaderScreen> createState() => _DocReaderScreenState();
}

class _DocReaderScreenState extends State<DocReaderScreen> {
  WeeklyDoc? _doc;
  Object? _error;
  List<SlidePage> _slides = const [];
  int _index = 0;
  DocViewMode _view = DocViewMode.slide;
  final Map<String, int> _answers = {};
  PageController? _pages;
  final _docScroll = ScrollController();
  List<GlobalKey> _sectionKeys = const [];
  int _docSeen = 0;
  bool _completing = false;
  bool _chromeVisible = true;
  Timer? _chromeTimer;

  bool get _isPreview => widget.previewDoc != null;

  @override
  void initState() {
    super.initState();
    _docScroll.addListener(_onDocScroll);
    _load();
  }

  @override
  void dispose() {
    _pages?.dispose();
    _docScroll.dispose();
    _chromeTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _doc = null;
    });
    try {
      final doc = widget.previewDoc ?? await widget.repo.loadDoc(widget.docId);
      final p = widget.repo.progressOf(widget.docId);
      final slides = buildSlides(doc);
      var start = 0;
      if (!_isPreview && !p.completed) {
        start = slides.indexWhere((s) => s.sectionIndex == p.lastSection);
        if (start < 0) start = slides.length - 1;
      }
      final view = _isPreview ? doc.meta.defaultView : (doc.meta.canSwitch ? (p.lastView ?? doc.meta.defaultView) : doc.meta.allowedViews.first);
      if (!mounted) return;
      setState(() {
        _doc = doc;
        _slides = slides;
        _index = start.clamp(0, slides.isEmpty ? 0 : slides.length - 1);
        _view = view;
        _sectionKeys = List.generate(doc.sections.length, (_) => GlobalKey());
        if (!_isPreview) _answers.addAll(p.answers);
        _pages?.dispose();
        _pages = PageController(initialPage: _index);
      });
      _record(_index);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _record(int slideIndex) {
    if (_isPreview || _slides.isEmpty) return;
    widget.repo.saveProgress(widget.docId, sectionIndex: _slides[slideIndex].sectionIndex, view: _view);
  }

  void _goTo(int i) {
    if (i < 0 || i >= _slides.length) return;
    final d = motion(context, 300);
    if (_pages?.hasClients ?? false) {
      if (d == Duration.zero) {
        _pages!.jumpToPage(i);
      } else {
        _pages!.animateToPage(i, duration: d, curve: Curves.easeOutCubic);
      }
    } else {
      _onPageChanged(i);
    }
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    _record(i);
  }

  void _onAnswer(String key, int option) {
    setState(() => _answers[key] = option);
    if (!_isPreview) widget.repo.answerQuiz(widget.docId, key, option);
  }

  void _setView(DocViewMode v) {
    setState(() => _view = v);
    if (!_isPreview && _slides.isNotEmpty) widget.repo.saveProgress(widget.docId, sectionIndex: _slides[_index].sectionIndex, view: v);
    if (v == DocViewMode.slide) {
      _pages?.dispose();
      _pages = PageController(initialPage: _index);
    }
  }

  void _onDocScroll() {
    // Đếm số section đã cuộn qua (đỉnh section đã lên khỏi nửa màn hình).
    final h = MediaQuery.sizeOf(context).height;
    var seen = 0;
    for (final k in _sectionKeys) {
      final box = k.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy < h * 0.5) seen++;
    }
    if (seen != _docSeen) {
      setState(() => _docSeen = seen);
      if (!_isPreview && seen > 0) widget.repo.saveProgress(widget.docId, sectionIndex: seen - 1, view: DocViewMode.doc);
    }
  }

  Future<void> _complete() async {
    final doc = _doc;
    if (doc == null || _completing) return;
    if (_isPreview) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _completing = true);
    try {
      final result = await widget.repo.complete(widget.docId, doc.sections.length);
      if (!mounted) return;
      final next = widget.repo.publishedDocs(doc.week).where((d) => d.order > doc.order).toList();
      await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => DocCompleteScreen(
          repo: widget.repo,
          doc: doc,
          result: result,
          nextDoc: next.isEmpty ? null : next.first,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Chưa lưu được. ${e is RepoException ? e.message : 'Kiểm tra mạng rồi thử lại.'}'),
        action: SnackBarAction(label: 'Thử lại', onPressed: _complete),
      ));
    }
  }

  // ───────────────────────────── build ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: EmptyState(
          isError: true,
          message: _error is RepoException ? (_error! as RepoException).message : 'Không tải được tài liệu. Kiểm tra mạng rồi thử lại.',
          actionLabel: 'Thử lại',
          onAction: _load,
        ),
      );
    }
    if (doc == null) return _loading();
    if (doc.isHtml) return _htmlReader(doc);

    return LayoutBuilder(builder: (context, c) {
      final desktop = c.maxWidth >= AppBreakpoints.desktop;
      final landscapePhone = !desktop && MediaQuery.orientationOf(context) == Orientation.landscape;
      if (_view == DocViewMode.slide && landscapePhone) return _fullscreenSlides(doc);
      return Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowRight): _NextIntent(),
          SingleActivator(LogicalKeyboardKey.space): _NextIntent(),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _PrevIntent(),
        },
        child: Actions(
          actions: {
            _NextIntent: CallbackAction<_NextIntent>(onInvoke: (_) {
              if (_view == DocViewMode.slide) _goTo(_index + 1);
              return null;
            }),
            _PrevIntent: CallbackAction<_PrevIntent>(onInvoke: (_) {
              if (_view == DocViewMode.slide) _goTo(_index - 1);
              return null;
            }),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: _view == DocViewMode.slide ? AppColors.readerBg : AppColors.background,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (_isPreview) _previewBanner(),
                    _header(doc, desktop),
                    Expanded(child: _view == DocViewMode.slide ? _slideBody(doc, desktop) : _docBody(doc, desktop)),
                    if (_view == DocViewMode.slide && !desktop) _footer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _loading() => Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Padding(
          padding: EdgeInsets.all(AppSpace.lg),
          child: Column(children: [SkeletonBox(height: 28, width: 220, radius: AppRadius.sm), SizedBox(height: AppSpace.lg), Expanded(child: SkeletonBox(height: double.infinity, radius: AppRadius.slide))]),
        ),
      );

  Widget _previewBanner() => Container(
        width: double.infinity,
        color: AppColors.tipBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Text('Bản xem trước · Không ghi tiến độ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warnText)),
      );

  double get _readFraction {
    if (_slides.isEmpty) return 0;
    if (_view == DocViewMode.slide) return (_index + 1) / _slides.length;
    final total = _doc?.sections.length ?? 1;
    return total == 0 ? 0 : _docSeen / total;
  }

  Widget _header(WeeklyDoc doc, bool desktop) {
    final toggle = doc.meta.canSwitch
        ? ViewModeToggle(
            value: _view,
            onChanged: _setView,
            iconOnly: !desktop,
            compact: false,
            order: desktop ? const [DocViewMode.doc, DocViewMode.slide] : const [DocViewMode.slide, DocViewMode.doc],
          )
        : const SizedBox.shrink();
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
                  IconButton(tooltip: 'Quay lại', icon: const Icon(Icons.chevron_left_rounded, size: 28), onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 4),
                  Expanded(child: _titleBlock(doc, desktop)),
                  toggle,
                  SizedBox(width: desktop ? 0 : 8),
                ],
              ),
            ),
          ),
          PillProgress(value: _readFraction, height: 3, track: AppColors.sidebar),
        ],
      ),
    );
  }

  Widget _titleBlock(WeeklyDoc doc, bool desktop) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            desktop ? 'Theo tuần › Tuần ${doc.week} › Tài liệu ${doc.order}' : 'Tuần ${doc.week} · Tài liệu ${doc.order}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: desktop ? 18 : 14, fontWeight: FontWeight.w800, color: AppColors.text)),
        ],
      );

  /// Tài liệu HTML (file 9): thanh trên (quay lại · tên · Hoàn thành) + nguyên file.
  /// File tự có nút chuyển slide; không có thanh tiến độ hay công tắc Slide / Doc.
  Widget _htmlReader(WeeklyDoc doc) {
    final desktop = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final html = doc.html ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (_isPreview) _previewBanner(),
            Container(
              height: desktop ? 64 : 56,
              padding: EdgeInsets.symmetric(horizontal: desktop ? 24 : 8),
              decoration: const BoxDecoration(color: AppColors.background, border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  IconButton(tooltip: 'Quay lại', icon: const Icon(Icons.chevron_left_rounded, size: 28), onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 4),
                  Expanded(child: _titleBlock(doc, desktop)),
                  const SizedBox(width: AppSpace.sm),
                  FilledButton(
                    onPressed: _completing ? null : _complete,
                    style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 18)),
                    child: _completing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                        : Text(_isPreview ? 'Đóng xem trước' : 'Hoàn thành'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: html.isEmpty
                  ? const EmptyState(message: 'Tài liệu chưa có nội dung')
                  : ColoredBox(color: AppColors.surface, child: HtmlFrame(html: html, autofocus: true)),
            ),
          ],
        ),
      ),
    );
  }

  QuizState get _quiz => QuizState(answers: _answers, onAnswer: _onAnswer);

  Widget _slideBody(WeeklyDoc doc, bool desktop) {
    if (_slides.isEmpty) return const EmptyState(message: 'Tài liệu chưa có nội dung');
    if (desktop) {
      return LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 64).clamp(320.0, 1000.0);
        final h = w * 9 / 16;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
          child: Column(
            children: [
              SizedBox(
                width: w,
                height: h,
                child: PageView.builder(
                  controller: _pages,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _slideFrame(
                      radius: AppRadius.cardLg,
                      padding: 44,
                      watermark: true,
                      child: SlideContent(page: _slides[i], scale: BlockScale.slideWide, quiz: _quiz),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RoundNavButton(icon: Icons.chevron_left_rounded, tooltip: 'Slide trước', size: 44, onPressed: _index == 0 ? null : () => _goTo(_index - 1)),
                  const SizedBox(width: 14),
                  SlideDots(count: _slides.length, index: _index, onTap: _goTo, size: 10),
                  const SizedBox(width: 14),
                  _nextButton(size: 44),
                  const SizedBox(width: 14),
                  Text('${_index + 1} / ${_slides.length}', style: AppText.label.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        );
      });
    }
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pages,
            onPageChanged: _onPageChanged,
            itemCount: _slides.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _slideFrame(
                radius: AppRadius.slide,
                padding: 20,
                child: SlideContent(page: _slides[i], scale: BlockScale.slideMobile, quiz: _quiz),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.screen_rotation_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('Xoay ngang để trình chiếu toàn màn hình', style: AppText.caption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _slideFrame({required Widget child, required double radius, required double padding, bool watermark = false}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(radius), boxShadow: AppShadows.slide),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: SingleChildScrollView(padding: EdgeInsets.all(padding), child: child)),
          if (watermark)
            const Positioned(
              right: 22,
              top: 18,
              child: ExcludeSemantics(child: Text('ieltshub.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFE9D0C8)))),
            ),
        ],
      ),
    );
  }

  Widget _nextButton({double size = 48}) {
    final last = _index >= _slides.length - 1;
    if (!last) return RoundNavButton(icon: Icons.chevron_right_rounded, tooltip: 'Slide sau', filled: true, size: size, onPressed: () => _goTo(_index + 1));
    return SizedBox(
      height: size,
      child: FilledButton(
        onPressed: _completing ? null : _complete,
        style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.only(left: 20, right: 14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isPreview ? 'Đóng xem trước' : 'Hoàn thành'),
            const SizedBox(width: 6),
            if (_completing)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
            else
              const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      decoration: const BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.border))),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 18 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        children: [
          RoundNavButton(icon: Icons.chevron_left_rounded, tooltip: 'Slide trước', onPressed: _index == 0 ? null : () => _goTo(_index - 1)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SlideDots(count: _slides.length, index: _index, onTap: _goTo),
                Text('${_index + 1} / ${_slides.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              ],
            ),
          ),
          _nextButton(),
        ],
      ),
    );
  }

  Widget _docBody(WeeklyDoc doc, bool desktop) {
    return ListView(
      controller: _docScroll,
      padding: desktop ? const EdgeInsets.symmetric(vertical: 32, horizontal: 24) : EdgeInsets.fromLTRB(16, 16, 16, 28 + MediaQuery.paddingOf(context).bottom),
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
                  child: DocContent(doc: doc, scale: desktop ? BlockScale.docDesktop : BlockScale.docMobile, quiz: _quiz, sectionKeys: _sectionKeys),
                ),
                const SizedBox(height: AppSpace.lg),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _completing ? null : _complete,
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card))),
                    child: Text(_isPreview ? 'Đóng xem trước' : 'Đánh dấu đã học xong', style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Điện thoại xoay ngang: slide 16:9 toàn màn, chạm cạnh để chuyển, chạm giữa để hiện điều khiển.
  Widget _fullscreenSlides(WeeklyDoc doc) {
    void showChrome() {
      setState(() => _chromeVisible = true);
      _chromeTimer?.cancel();
      _chromeTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _chromeVisible = false);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.text,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: PageView.builder(
                controller: _pages,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (_, i) => _slideFrame(radius: 0, padding: 28, child: SlideContent(page: _slides[i], scale: BlockScale.slideMobile, quiz: _quiz)),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                SizedBox(width: 64, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _goTo(_index - 1))),
                Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: showChrome)),
                SizedBox(width: 64, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _goTo(_index + 1))),
              ],
            ),
          ),
          if (_chromeVisible)
            Positioned(
              left: 12,
              top: 12,
              child: SafeArea(
                child: RoundNavButton(icon: Icons.close_rounded, tooltip: 'Thoát trình chiếu', size: 44, onPressed: () => _setView(DocViewMode.doc)),
              ),
            ),
          if (_chromeVisible)
            Positioned(
              right: 16,
              bottom: 12,
              child: SafeArea(child: Text('${_index + 1} / ${_slides.length}', style: const TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.w700))),
            ),
        ],
      ),
    );
  }
}

class _NextIntent extends Intent {
  const _NextIntent();
}

class _PrevIntent extends Intent {
  const _PrevIntent();
}
