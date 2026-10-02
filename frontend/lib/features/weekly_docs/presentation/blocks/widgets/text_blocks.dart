import 'package:flutter/material.dart';

import '../../../../../core/theme/brand_colors.dart';
import '../../../domain/mini_markdown.dart';
import '../../../domain/models/weekly_doc.dart';
import '../block_context.dart';
import '../../doc_theme.dart';

/// Heading: chữ 24–34, đậm 800.
class HeadingBlockWidget extends StatelessWidget {
  const HeadingBlockWidget({super.key, required this.block, required this.ctx});

  final HeadingBlock block;
  final BlockContext ctx;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        block.text,
        style: DocFonts.heading(
          size: ctx.mode == RenderMode.slide ? 30 : 26,
        ),
      ),
    );
  }
}

/// Paragraph: 15–18, line-height 1.6, hỗ trợ markdown.
class ParagraphBlockWidget extends StatelessWidget {
  const ParagraphBlockWidget({super.key, required this.block, required this.ctx});

  final ParagraphBlock block;
  final BlockContext ctx;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text.rich(
        parseMiniMarkdown(
          block.text,
          base: DocFonts.body(size: 16, height: 1.6),
          onLinkTap: ctx.onOpenLink,
        ),
      ),
    );
  }
}

/// Callout "Mẹo": nền #FDF1DE, icon bóng đèn.
class CalloutBlockWidget extends StatelessWidget {
  const CalloutBlockWidget({super.key, required this.block, required this.ctx});

  final CalloutBlock block;
  final BlockContext ctx;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brand.calloutBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3E2BE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, size: 20, color: Brand.goldDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              parseMiniMarkdown(
                block.text,
                base: DocFonts.body(size: 15, height: 1.5),
                onLinkTap: ctx.onOpenLink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pattern: khối nền primary chữ kem, nhãn "MẪU CÂU".
class PatternBlockWidget extends StatelessWidget {
  const PatternBlockWidget({super.key, required this.block, required this.ctx});

  final PatternBlock block;
  final BlockContext ctx;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brand.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MẪU CÂU',
            style: DocFonts.kicker(size: 11, color: Brand.goldLight),
          ),
          const SizedBox(height: 8),
          Text(
            block.text,
            style: DocFonts.body(size: 17, color: Brand.background, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
