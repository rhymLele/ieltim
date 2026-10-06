import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/annotate/annotate.dart';
import '../../../../annotate/presentation/controllers/slide_annotation_controllers.dart';
import '../../../../annotate/presentation/cubits/doc_annotations_cubit.dart';
import '../../../core/app_tokens.dart';
import '../../../domain/entities/weekly_doc.dart';
import 'annotation_actions.dart';
import 'annotation_scope.dart';
import 'block_text.dart';
import 'my_notes_panel.dart';
import 'selection_target.dart';

/// slideKey của một trang slide tài liệu JSON: `"{section}-{phần}"`.
String slideKeyOf(SlidePage page) => '${page.sectionIndex}-${page.partIndex}';

/// Lớp ghi chú của người học trên màn đọc tài liệu JSON: bôi đen → hộp thoại, highlight, vẽ trên slide.
/// Màn đọc tạo một đối tượng cho mỗi tài liệu (không dùng khi admin xem trước) và gọi [dispose] khi rời màn.
class ReaderAnnotations {
  ReaderAnnotations({required this.doc, required this.docVersion, required BuildContext Function() hostContext})
      : cubit = DocAnnotationsCubit(docId: doc.id, docVersion: docVersion) {
    actions = AnnotationActions(cubit: cubit, hostContext: hostContext, docId: doc.id, week: doc.week);
    slideNotes = SlideAnnotationControllers(onChanged: cubit.slideChanged);
    blocks = [
      for (var si = 0; si < doc.sections.length; si++)
        for (var bi = 0; bi < doc.sections[si].blocks.length; bi++)
          if (annotatableText(doc.sections[si].blocks[bi]) case final text?)
            NoteBlock(
              blockKey: blockKey(si, bi, doc.sections[si].blocks[bi]),
              label: 'Section ${si + 1} · ${blockTypeLabels[doc.sections[si].blocks[bi].type] ?? 'Khối'}',
              text: text,
            ),
    ];
    blockTexts = {for (final b in blocks) b.blockKey: b.text};
    cubit.load();
  }

  final WeeklyDoc doc;
  final int docVersion;
  final DocAnnotationsCubit cubit;
  late final AnnotationActions actions;
  late final SlideAnnotationControllers slideNotes;
  final registry = BlockKeyRegistry();
  late final List<NoteBlock> blocks;
  late final Map<String, String> blockTexts;
  final _floating = FloatingCardOverlay();

  /// Vị trí ngón tay / con trỏ lần chạm gần nhất (đặt hộp thoại, chọn khối khi chữ trùng ở nhiều khối).
  Offset? _lastPointer;

  /// Bọc cả màn đọc: cung cấp cubit + highlight cho các khối chữ.
  Widget scope(Widget child) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<DocAnnotationsCubit, DocAnnotationsState>(
          buildWhen: (prev, curr) => !identical(prev.highlights, curr.highlights),
          builder: (context, state) => AnnotationScope(highlights: state.highlights, registry: registry, onTapHighlight: _openHighlight, child: child),
        ),
      );

  /// Bọc vùng nội dung (Doc / các slide) để bôi đen chữ.
  Widget selectable(Widget child) => Listener(
        onPointerDown: (e) => _lastPointer = e.position,
        onPointerUp: (e) {
          _lastPointer = e.position;
          // Thả chuột: AnnotatableSelectionArea mở hộp thoại ở post-frame callback, mà màn hình đứng yên thì
          // không có frame nào → xin một frame để hộp thoại hiện ngay.
          WidgetsBinding.instance.scheduleFrame();
        },
        child: AnnotatableSelectionArea(
          cardBuilder: (context, text, close) => actions.card(
            text: text,
            target: locateSelection(text, blockTexts: blockTexts, mounted: registry.mounted, anchor: _lastPointer),
            close: close,
          ),
          child: child,
        ),
      );

  /// Lớp vẽ đè lên khung một slide.
  Widget slideOverlay(SlidePage page, Widget frame) {
    final key = slideKeyOf(page);
    final controller = slideNotes.controllerFor(key, initial: cubit.state.slides[key]);
    return _DrawingGestures(controller: controller, child: AnnotationLayer(controller: controller, child: frame));
  }

  /// Slide đang xem (thanh công cụ, danh sách ghi chú trỏ vào slide này).
  void activate(SlidePage page) {
    final key = slideKeyOf(page);
    slideNotes.activate(key, initial: cubit.state.slides[key]);
  }

  /// Ghi chú bị thay từ ngoài (tải từ máy chủ, gộp với máy khác) → nạp lại lớp vẽ.
  void syncSlides(DocAnnotationsState state) => slideNotes.sync(state.slides, state.slideEpochs);

  /// Chỉ số các slide có ghi chú (chấm trang viền vàng).
  Set<int> markedSlides(List<SlidePage> slides) => {
        for (final (i, page) in slides.indexed)
          if (cubit.state.hasNotes(slideKeyOf(page))) i,
      };

  /// Chạm vào đoạn đã highlight: hộp thoại đổi màu / bỏ.
  void _openHighlight(String id) {
    final h = cubit.state.byId(id);
    final at = _lastPointer;
    final context = actions.hostContext();
    if (h == null || at == null || !context.mounted) return;
    final target = targetIn(blockTexts[h.blockKey] ?? '', h.quote, blockKey: h.blockKey);
    _floating.show(
      context,
      anchorTop: at.translate(0, -12),
      anchorBottom: at.translate(0, 16),
      builder: (close) => actions.card(text: h.quote, target: target, close: close, current: h),
    );
  }

  void dispose() {
    _floating.close();
    slideNotes.dispose();
    cubit.close();
  }
}

/// Thanh công cụ ghi chú trên slide (+ nút mở danh sách ghi chú trên điện thoại).
class SlideAnnotationBar extends StatelessWidget {
  const SlideAnnotationBar({super.key, required this.notes, required this.compact, required this.showNotesButton});

  final SlideAnnotationControllers notes;
  final bool compact;

  /// Điện thoại: danh sách ghi chú mở bằng bottom sheet.
  final bool showNotesButton;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notes,
      builder: (context, _) {
        final controller = notes.active;
        if (controller == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: compact ? Alignment.centerLeft : Alignment.center,
                  child: AnnotationToolbar(key: const Key('weekly_docs_annotation_toolbar'), controller: controller, compact: compact),
                ),
              ),
              if (showNotesButton) ...[
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  key: const Key('weekly_docs_slide_notes_button'),
                  tooltip: 'Ghi chú của slide',
                  icon: const Icon(Icons.sticky_note_2_outlined),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.cardSurface,
                    builder: (_) => FractionallySizedBox(heightFactor: 0.6, child: NotesPanel(controller: controller)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Cột ghi chú của slide đang xem (desktop ≥ 1024).
class SlideNotesColumn extends StatelessWidget {
  const SlideNotesColumn({super.key, required this.notes});

  final SlideAnnotationControllers notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(color: AppColors.cardSurface, border: Border(left: BorderSide(color: AppColors.borderLight))),
      child: ListenableBuilder(
        listenable: notes,
        builder: (context, _) {
          final controller = notes.active;
          return controller == null ? const SizedBox.shrink() : NotesPanel(key: ValueKey(notes.activeKey), controller: controller);
        },
      ),
    );
  }
}

/// Đang cầm công cụ vẽ: hạ ngưỡng bắt đầu kéo của lớp vẽ để nét vẽ thắng thao tác kéo-chọn chữ của
/// SelectionArea bọc ngoài (ngưỡng cố định 18px, giành nét vuốt ngang bằng ngón tay trên web cảm ứng).
class _DrawingGestures extends StatelessWidget {
  const _DrawingGestures({required this.controller, required this.child});

  final AnnotationController controller;
  final Widget child;

  static const _drawingSettings = DeviceGestureSettings(touchSlop: 4);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      child: child,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final drawing = controller.tool != AnnotationTool.view;
        return MediaQuery(data: drawing ? media.copyWith(gestureSettings: _drawingSettings) : media, child: child!);
      },
    );
  }
}
