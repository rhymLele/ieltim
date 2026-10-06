import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/uuid.dart';
import '../../../../../core/widgets/annotate/annotate.dart';
import '../../../../../core/widgets/speak_button.dart';
import '../../../../annotate/presentation/cubits/doc_annotations_cubit.dart';
import '../../../../vocab/domain/entities/vocab_entry.dart';
import '../../../core/app_tokens.dart';
import 'selection_target.dart';

/// Nối hộp thoại bôi đen ([SelectionActionsCard]) với logic: sổ từ, dịch, nghe, sao chép, highlight.
/// Dùng chung cho tài liệu JSON (khối chữ) và HTML (`blockKey = 'html'`).
class AnnotationActions {
  AnnotationActions({required this.cubit, required this.hostContext, required this.docId, required this.week});

  final DocAnnotationsCubit cubit;

  /// Context của màn đọc (còn sống sau khi hộp thoại đóng): mở form sổ từ, báo snackbar.
  final BuildContext Function() hostContext;
  final String docId;
  final int week;

  static const maxHighlightLength = 300;

  /// Hộp thoại cho chữ vừa bôi đen. [target] null = vùng chọn kéo qua nhiều khối: chỉ dịch / nghe / sao chép.
  Widget card({
    required String text,
    required SelectionTarget? target,
    required VoidCallback close,
    TextHighlight? current,
    void Function(TextHighlight highlight)? onHighlighted,
    void Function(String id)? onHighlightRemoved,
  }) {
    return _SelectionCardHost(
      key: ValueKey('$text|${current?.id}'),
      actions: this,
      text: text,
      target: target,
      close: close,
      current: current,
      onHighlighted: onHighlighted,
      onHighlightRemoved: onHighlightRemoved,
    );
  }

  void _toast(String message) {
    final context = hostContext();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> addVocab(String text, SelectionTarget? target) async {
    final sentence = target?.sentence;
    final translation = await cubit.cachedTranslation(text, sentence: sentence);
    final decks = await cubit.decks(week: week);
    final context = hostContext();
    if (!context.mounted) return;
    final draft = await showVocabSheet(
      context,
      text: text,
      ipa: translation?.ipa,
      suggestedMeaning: translation?.meaning,
      example: sentence,
      decks: decks,
      initialDeck: decks.first,
      sourceDocId: docId,
    );
    if (draft == null) return;
    final result = await cubit.addVocab(NewVocab(
      text: draft.text,
      meaning: draft.meaning,
      ipa: draft.ipa,
      example: draft.example,
      partOfSpeech: translation?.partOfSpeech,
      deck: draft.deck,
      sourceDocId: docId,
      sourceBlockKey: target?.blockKey,
    ));
    switch (result) {
      case Success():
        _toast('Đã thêm "${draft.text}" vào Sổ từ · ${draft.deck}');
      case Failure(exception: VocabExistsException()):
        _toast('Từ này đã có trong Sổ từ');
      case Failure(:final exception):
        _toast(exception.message);
    }
  }

  /// Tô [color] cho vùng chọn; highlight cũ chồng lên vùng này bị thay.
  TextHighlight? highlight(String text, SelectionTarget? target, HighlightColor color, {required Iterable<String> overlapping}) {
    if (target == null) {
      _toast('Chọn chữ trong một đoạn để highlight');
      return null;
    }
    if (text.length > maxHighlightLength) {
      _toast('Highlight tối đa $maxHighlightLength ký tự');
      return null;
    }
    final h = TextHighlight(
      id: uuidV4(),
      blockKey: target.blockKey,
      quote: text,
      prefix: target.prefix,
      suffix: target.suffix,
      start: target.start,
      end: target.end,
      color: color,
    );
    cubit.addHighlight(h, replaces: overlapping);
    return h;
  }

  Future<void> copy(String text) => Clipboard.setData(ClipboardData(text: text));
}

class _SelectionCardHost extends StatefulWidget {
  const _SelectionCardHost({
    super.key,
    required this.actions,
    required this.text,
    required this.target,
    required this.close,
    this.current,
    this.onHighlighted,
    this.onHighlightRemoved,
  });

  final AnnotationActions actions;
  final String text;
  final SelectionTarget? target;
  final VoidCallback close;
  final TextHighlight? current;
  final void Function(TextHighlight highlight)? onHighlighted;
  final void Function(String id)? onHighlightRemoved;

  @override
  State<_SelectionCardHost> createState() => _SelectionCardHostState();
}

class _SelectionCardHostState extends State<_SelectionCardHost> {
  bool _inVocab = false;

  AnnotationActions get _a => widget.actions;

  @override
  void initState() {
    super.initState();
    _a.cubit.vocabExists(widget.text).then((exists) {
      if (mounted && exists) setState(() => _inVocab = true);
    });
  }

  /// Highlight của tôi chồng lên vùng chọn trong cùng khối.
  Iterable<String> _overlapping() {
    final target = widget.target;
    if (target == null) return const [];
    return [
      for (final h in _a.cubit.state.highlightsOf(target.blockKey))
        if ((h.start ?? -1) < target.end && (h.end ?? -1) > target.start) h.id,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final multiBlock = widget.target == null && widget.current == null;
    final current = widget.current;
    final card = SelectionActionsCard(
      text: widget.text,
      currentHighlight: current?.color,
      alreadyInVocab: _inVocab,
      onAddVocab: () {
        widget.close();
        if (multiBlock) {
          _a._toast('Chọn chữ trong một đoạn để thêm vào sổ từ');
          return;
        }
        _a.addVocab(widget.text, widget.target);
      },
      onTranslate: () => _a.cubit.translate(widget.text, sentence: widget.target?.sentence),
      onHighlight: (color) {
        if (current != null) {
          _a.cubit.recolorHighlight(current.id, color);
        } else {
          final h = _a.highlight(widget.text, widget.target, color, overlapping: _overlapping());
          if (h != null) widget.onHighlighted?.call(h);
        }
        widget.close();
      },
      onRemoveHighlight: current == null
          ? null
          : () {
              _a.cubit.removeHighlight(current.id);
              widget.onHighlightRemoved?.call(current.id);
              widget.close();
            },
      onSpeak: () => SpeakButton.speak(widget.text),
      onCopy: () {
        _a.copy(widget.text);
        widget.close();
      },
    );
    if (!multiBlock) return card;
    // Vùng chọn kéo qua nhiều khối: sổ từ và highlight không dùng được.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        card,
        const SizedBox(height: 6),
        Material(
          color: AppColors.tipBg,
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Chọn chữ trong một đoạn để highlight', style: TextStyle(fontSize: 12, color: AppColors.warnText)),
          ),
        ),
      ],
    );
  }
}

/// Hộp thoại đặt cạnh một điểm trên màn (chạm vào chữ đã highlight, vùng chọn trong file HTML):
/// phía trên điểm nếu đủ chỗ, không thì phía dưới; luôn nằm trong màn hình.
class FloatingCardOverlay {
  OverlayEntry? _entry;
  VoidCallback? _onClosed;

  bool get isOpen => _entry != null;

  /// [anchorTop] / [anchorBottom] là toạ độ trên màn hình (global). [onClosed] gọi một lần khi hộp thoại đóng (mọi cách đóng).
  void show(
    BuildContext context, {
    required Offset anchorTop,
    required Offset anchorBottom,
    required Widget Function(VoidCallback close) builder,
    VoidCallback? onClosed,
  }) {
    close();
    final overlay = Overlay.of(context);
    // Màn đọc nằm trong khung có thanh bên (ShellRoute): Overlay gần nhất không bắt đầu ở góc màn hình.
    final box = overlay.context.findRenderObject();
    Offset local(Offset global) => box is RenderBox && box.hasSize ? box.globalToLocal(global) : global;
    final top = local(anchorTop), bottom = local(anchorBottom);
    final entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.translucent, onTapDown: (_) => close())),
          CustomSingleChildLayout(
            delegate: _FloatingCardLayout(anchorTop: top, anchorBottom: bottom),
            child: builder(close),
          ),
        ],
      ),
    );
    _entry = entry;
    _onClosed = onClosed;
    overlay.insert(entry);
  }

  void close() {
    final entry = _entry;
    if (entry == null) return;
    entry.remove();
    _entry = null;
    final onClosed = _onClosed;
    _onClosed = null;
    onClosed?.call();
  }
}

class _FloatingCardLayout extends SingleChildLayoutDelegate {
  _FloatingCardLayout({required this.anchorTop, required this.anchorBottom});

  final Offset anchorTop;
  final Offset anchorBottom;
  static const _pad = 12.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(Size(constraints.maxWidth - _pad * 2, constraints.maxHeight - _pad * 2));

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (anchorTop.dx - child.width / 2).clamp(_pad, (size.width - child.width - _pad).clamp(_pad, double.infinity));
    final above = anchorTop.dy - child.height - 8;
    final y = above >= _pad + 24 ? above : (anchorBottom.dy + 8).clamp(_pad, (size.height - child.height - _pad).clamp(_pad, double.infinity));
    return Offset(x.toDouble(), y.toDouble());
  }

  @override
  bool shouldRelayout(covariant _FloatingCardLayout old) => old.anchorTop != anchorTop || old.anchorBottom != anchorBottom;
}

