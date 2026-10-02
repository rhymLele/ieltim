import 'package:flutter/material.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../domain/models/weekly_doc.dart';
import 'block_context.dart';
import 'widgets/content_blocks.dart';
import 'widgets/interactive_blocks.dart';
import 'widgets/text_blocks.dart';

/// Cách dựng một [Widget] từ [DocBlock] trong ngữ cảnh [BlockContext].
typedef BlockBuilder =
    Widget Function(BuildContext context, DocBlock block, BlockContext ctx);

/// Bộ hiển thị khối — dùng chung cho mọi màn (DocView, SlideView, preview admin).
///
/// Bảng ánh xạ `Map<Type, BlockBuilder>`; type lạ / chưa biết → widget
/// [UnknownBlockWidget]. Khối đang chọn (admin) được tô viền vàng.
class BlockRegistry {
  BlockRegistry._();

  static final Map<Type, BlockBuilder> _builders = {
    HeadingBlock: (c, b, ctx) =>
        HeadingBlockWidget(block: b as HeadingBlock, ctx: ctx),
    ParagraphBlock: (c, b, ctx) =>
        ParagraphBlockWidget(block: b as ParagraphBlock, ctx: ctx),
    CalloutBlock: (c, b, ctx) =>
        CalloutBlockWidget(block: b as CalloutBlock, ctx: ctx),
    StepsBlock: (c, b, ctx) =>
        StepsBlockWidget(block: b as StepsBlock, ctx: ctx),
    PassageBlock: (c, b, ctx) =>
        PassageBlockWidget(block: b as PassageBlock, ctx: ctx),
    QuizBlock: (c, b, ctx) =>
        QuizBlockWidget(block: b as QuizBlock, ctx: ctx),
    VocabBlock: (c, b, ctx) =>
        VocabBlockWidget(block: b as VocabBlock, ctx: ctx),
    PatternBlock: (c, b, ctx) =>
        PatternBlockWidget(block: b as PatternBlock, ctx: ctx),
    ImageBlock: (c, b, ctx) =>
        ImageBlockWidget(block: b as ImageBlock, ctx: ctx),
    SlideBreakBlock: (c, b, ctx) => const SizedBox.shrink(),
    UnknownBlock: (c, b, ctx) =>
        UnknownBlockWidget(block: b as UnknownBlock, ctx: ctx),
  };

  /// Dựng widget cho [block]. [ctx] đã chứa [BlockContext.blockKey] đúng khối.
  static Widget build(
    BuildContext context,
    DocBlock block,
    BlockContext ctx, {
    bool highlightSelected = true,
  }) {
    final builder = _builders[block.runtimeType] ?? _builders[UnknownBlock]!;
    final widget = builder(context, block, ctx);
    if (highlightSelected && ctx.isSelected) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Brand.gold, width: 2),
        ),
        child: widget,
      );
    }
    return widget;
  }
}
