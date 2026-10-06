import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/annotate/annotate.dart';
import '../../../../annotate/presentation/controllers/slide_annotation_controllers.dart';
import '../../../../annotate/presentation/cubits/doc_annotations_cubit.dart';
import '../../../core/app_tokens.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../html_frame.dart';
import 'annotation_actions.dart';
import 'selection_target.dart';

/// Highlight của tài liệu HTML có `blockKey = 'html'`.
const htmlBlockKey = 'html';

/// Cách gắn ghi chú vẽ vào file HTML, đoán từ tin `viewport` của script cầu nối.
enum HtmlNoteMode {
  /// File chia slide (`#hash`, `<section>` / `[data-slide]` ở giữa màn): mỗi slide một bộ ghi chú.
  slides,

  /// Trang cuộn dọc: chia theo "màn hình" (`y0`, `y1`…), nét vẽ trôi theo nội dung khi cuộn.
  screens,

  /// Không xác định được (canvas, game…): chỉ ghim ghi chú cho cả tài liệu.
  whole,
}

/// Lớp ghi chú của người học trên tài liệu HTML: bôi đen trong file → hộp thoại, highlight bằng `<mark>`,
/// vẽ đè lên WebView / iframe theo slide hoặc màn hình đang xem.
class HtmlReaderAnnotations extends ChangeNotifier {
  HtmlReaderAnnotations({required this.doc, required this.docVersion, required BuildContext Function() hostContext})
      : cubit = DocAnnotationsCubit(docId: doc.id, docVersion: docVersion) {
    actions = AnnotationActions(cubit: cubit, hostContext: hostContext, docId: doc.id, week: doc.week);
    slideNotes = SlideAnnotationControllers(onChanged: cubit.slideChanged)..addListener(_onToolChanged);
    cubit.load().then((_) => _applyAll());
    activate('doc');
  }

  final WeeklyDoc doc;
  final int docVersion;
  final DocAnnotationsCubit cubit;
  late final AnnotationActions actions;
  late final SlideAnnotationControllers slideNotes;
  final bridge = HtmlBridgeController();
  final _floating = FloatingCardOverlay();

  /// Vị trí khung HTML trên màn (đổi toạ độ vùng chọn trong file sang toạ độ màn hình).
  final frameKey = GlobalKey();

  HtmlNoteMode mode = HtmlNoteMode.whole;
  double _scrollY = 0;
  double _viewport = 1;

  /// Highlight không còn tìm thấy trong file (admin đã sửa đoạn đó).
  final missing = <String>{};

  /// Lệch dọc của lớp vẽ so với khung (trang cuộn dọc): nét bám theo nội dung.
  double get scrollShift => mode == HtmlNoteMode.screens ? _scrollY - (_scrollY / _viewport).floor() * _viewport : 0;

  bool get drawingSupported => mode != HtmlNoteMode.whole;

  void activate(String key) {
    slideNotes.activate(key, initial: cubit.state.slides[key]);
    notifyListeners();
  }

  /// Tin từ script cầu nối (đã lọc đúng nguồn).
  void onMessage(Map<String, Object?> msg) {
    switch (msg['type']) {
      case 'selection':
        _showSelection(msg);
      case 'selectionCleared':
        _floating.close();
      case 'highlightTap':
        _showHighlight(msg);
      case 'highlightMissing':
        if (msg['id'] case final String id) missing.add(id);
      case 'viewport':
        _onViewport(msg);
    }
  }

  /// File tải xong (hoặc tải lại): áp mọi highlight đã lưu.
  void onLoaded() => _applyAll();

  void _applyAll() {
    final items = [for (final h in cubit.state.highlightsOf(htmlBlockKey)) h.toJson()];
    if (items.isNotEmpty) bridge.send({'type': 'applyHighlights', 'items': items});
  }

  void _onViewport(Map<String, Object?> msg) {
    final slideKey = msg['slideKey'];
    final scrollY = (msg['scrollY'] as num?)?.toDouble() ?? 0;
    final height = (msg['height'] as num?)?.toDouble() ?? 1;
    final docHeight = (msg['docHeight'] as num?)?.toDouble() ?? height;
    if (height <= 0) return; // khung chưa có kích thước (vừa tạo): chờ tin sau
    _scrollY = scrollY;
    _viewport = height <= 0 ? 1 : height;
    if (slideKey is String && slideKey.isNotEmpty) {
      mode = HtmlNoteMode.slides;
      activate(slideKey);
    } else if (docHeight > height + 8) {
      mode = HtmlNoteMode.screens;
      activate('y${(scrollY / _viewport).floor()}');
    } else {
      mode = HtmlNoteMode.whole;
      activate('doc');
    }
  }

  /// Đang cầm bút: chuột / chạm đi tới lớp vẽ (web), trang cuộn dọc thì khoá cuộn trong file.
  void _onToolChanged() {
    final drawing = slideNotes.isDrawing;
    bridge.setPointerPassthrough(enabled: drawing);
    if (mode == HtmlNoteMode.screens) bridge.send({'type': 'lockScroll', 'on': drawing});
    notifyListeners();
  }

  Rect _toGlobal(Object? rect) {
    final box = frameKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final r = rect is Map ? rect : const {};
    double v(String k) => (r[k] as num?)?.toDouble() ?? 0;
    return Rect.fromLTWH(origin.dx + v('x'), origin.dy + v('y'), v('w'), v('h'));
  }

  void _showSelection(Map<String, Object?> msg) {
    final text = (msg['text'] as String? ?? '').trim();
    final context = actions.hostContext();
    if (text.isEmpty || !context.mounted) return;
    final start = (msg['start'] as num?)?.toInt() ?? 0;
    final target = SelectionTarget(
      blockKey: htmlBlockKey,
      start: start,
      end: start + text.length,
      prefix: msg['prefix'] as String? ?? '',
      suffix: msg['suffix'] as String? ?? '',
      sentence: msg['sentence'] as String? ?? text,
    );
    final rect = _toGlobal(msg['rect']);
    _floating.show(
      context,
      anchorTop: rect.topCenter,
      anchorBottom: rect.bottomCenter,
      builder: (close) => actions.card(
        text: text,
        target: target,
        close: () {
          close();
          bridge.send({'type': 'clearSelection'});
        },
        onHighlighted: (h) {
          for (final old in _overlapping(target, except: h.id)) {
            bridge.send({'type': 'removeHighlight', 'id': old});
          }
          bridge.send({
            'type': 'applyHighlights',
            'items': [h.toJson()],
          });
        },
      ),
    );
  }

  Iterable<String> _overlapping(SelectionTarget t, {required String except}) => [
        for (final h in cubit.state.highlightsOf(htmlBlockKey))
          if (h.id != except && (h.start ?? -1) < t.end && (h.end ?? -1) > t.start) h.id,
      ];

  void _showHighlight(Map<String, Object?> msg) {
    final id = msg['id'];
    final h = id is String ? cubit.state.byId(id) : null;
    final context = actions.hostContext();
    if (h == null || !context.mounted) return;
    final rect = _toGlobal(msg['rect']);
    _floating.show(
      context,
      anchorTop: rect.topCenter,
      anchorBottom: rect.bottomCenter,
      builder: (close) => BlocProvider.value(
        value: cubit,
        child: _RecolorWatcher(
          id: h.id,
          onChanged: (updated) => bridge.send({
            'type': 'applyHighlights',
            'items': [updated.toJson()],
          }),
          child: actions.card(
            text: h.quote,
            target: null,
            current: h,
            close: close,
            onHighlightRemoved: (id) => bridge.send({'type': 'removeHighlight', 'id': id}),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _floating.close();
    slideNotes
      ..removeListener(_onToolChanged)
      ..dispose();
    cubit.close();
    super.dispose();
  }
}

/// Đổi màu highlight trong hộp thoại → áp màu mới vào file.
class _RecolorWatcher extends StatelessWidget {
  const _RecolorWatcher({required this.id, required this.onChanged, required this.child});

  final String id;
  final ValueChanged<TextHighlight> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocAnnotationsCubit, DocAnnotationsState>(
      listenWhen: (prev, curr) => prev.byId(id)?.color != curr.byId(id)?.color && curr.byId(id) != null,
      listener: (_, state) => onChanged(state.byId(id)!),
      child: child,
    );
  }
}

/// Thanh công cụ ghi chú cho tài liệu HTML. File không xác định được slide / cuộn: chỉ cho ghim ghi chú.
class HtmlAnnotationBar extends StatelessWidget {
  const HtmlAnnotationBar({super.key, required this.annotations, required this.compact, required this.onOpenNotes});

  final HtmlReaderAnnotations annotations;
  final bool compact;
  final VoidCallback onOpenNotes;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: annotations,
      builder: (context, _) {
        final controller = annotations.slideNotes.active;
        if (controller == null) return const SizedBox.shrink();
        final notesButton = IconButton.filledTonal(
          key: const Key('weekly_docs_slide_notes_button'),
          tooltip: 'Ghi chú của slide',
          icon: const Icon(Icons.sticky_note_2_outlined),
          onPressed: onOpenNotes,
        );
        if (annotations.drawingSupported) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              Expanded(child: Align(alignment: compact ? Alignment.centerLeft : Alignment.center, child: AnnotationToolbar(controller: controller, compact: compact))),
              const SizedBox(width: 6),
              notesButton,
            ]),
          );
        }
        final pinning = controller.tool == AnnotationTool.comment;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              FilterChip(
                key: const Key('weekly_docs_html_pin_toggle'),
                avatar: const Icon(Icons.mode_comment_outlined, size: 18),
                label: const Text('Ghi chú'),
                selected: pinning,
                onSelected: (on) => controller.tool = on ? AnnotationTool.comment : AnnotationTool.view,
              ),
              const SizedBox(width: AppSpace.sm),
              const Expanded(child: Text('File này không hỗ trợ vẽ', style: AppText.caption)),
              IconButton(tooltip: 'Hoàn tác', onPressed: controller.canUndo ? controller.undo : null, icon: const Icon(Icons.undo_rounded)),
              notesButton,
            ],
          ),
        );
      },
    );
  }
}

/// Lớp vẽ đè lên khung HTML; trang cuộn dọc thì trôi theo nội dung trong màn đang xem.
class HtmlAnnotationOverlay extends StatelessWidget {
  const HtmlAnnotationOverlay({super.key, required this.annotations});

  final HtmlReaderAnnotations annotations;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: annotations,
      builder: (context, _) {
        final controller = annotations.slideNotes.active;
        if (controller == null) return const SizedBox.shrink();
        return ClipRect(
          child: Transform.translate(
            offset: Offset(0, -annotations.scrollShift),
            child: AnnotationLayer(key: ValueKey(annotations.slideNotes.activeKey), controller: controller, child: const SizedBox.expand()),
          ),
        );
      },
    );
  }
}

/// Tên hiển thị của khoá ghi chú trên tài liệu HTML: "Slide 4", "Màn 3", "#muc-2", "Cả tài liệu".
String htmlSlideLabel(String key) {
  final n = int.tryParse(key.substring(key.isEmpty ? 0 : 1));
  return switch (key) {
    'doc' => 'Cả tài liệu',
    _ when key.startsWith('s') && n != null => 'Slide ${n + 1}',
    _ when key.startsWith('y') && n != null => 'Màn ${n + 1}',
    _ when key.startsWith('h') => '#${key.substring(1)}',
    _ => key,
  };
}
