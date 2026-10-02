import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/brand_colors.dart';
import '../../../../bloc/doc_creator_bloc.dart';
import '../../../../domain/models/weekly_doc.dart';
import '../../../doc_theme.dart';

/// Bước 2: block editor — thêm/sửa/xoá blocks theo section.
class StepContent extends StatefulWidget {
  const StepContent({super.key});

  @override
  State<StepContent> createState() => _StepContentState();
}

class _StepContentState extends State<StepContent> {
  int? _expandedSection;

  void _emit(List<DocSection> sections) {
    context.read<DocCreatorBloc>().add(UpdateContent(sections: sections));
  }

  @override
  Widget build(BuildContext context) {
    final doc = context.watch<DocCreatorBloc>().state.doc!;

    return Column(
      children: [
        // Add section button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              final sections = List<DocSection>.from(doc.sections);
              sections.add(DocSection(
                number: sections.length + 1,
                title: 'Section ${sections.length + 1}',
                blocks: [DocBlock.paragraph(text: '')],
              ));
              _emit(sections);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm section'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (var s = 0; s < doc.sections.length; s++)
                _SectionEditor(
                  section: doc.sections[s],
                  sectionIndex: s,
                  expanded: _expandedSection == s,
                  onToggle: () =>
                      setState(() => _expandedSection = _expandedSection == s ? null : s),
                  onRemoveSection: () {
                    final sections = List<DocSection>.from(doc.sections)..removeAt(s);
                    _emit(sections);
                  },
                  onUpdateSection: (updated) {
                    final sections = List<DocSection>.from(doc.sections);
                    sections[s] = updated;
                    _emit(sections);
                  },
                  onAddBlock: (block) {
                    final sections = List<DocSection>.from(doc.sections);
                    sections[s] = sections[s].copyWith(
                      blocks: [...sections[s].blocks, block],
                    );
                    _emit(sections);
                  },
                  onRemoveBlock: (bIdx) {
                    final sections = List<DocSection>.from(doc.sections);
                    final blocks = List<DocBlock>.from(sections[s].blocks)..removeAt(bIdx);
                    sections[s] = sections[s].copyWith(blocks: blocks);
                    _emit(sections);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Section Editor ──────────────────────────────────────────────────────────

class _SectionEditor extends StatefulWidget {
  final DocSection section;
  final int sectionIndex;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onRemoveSection;
  final void Function(DocSection) onUpdateSection;
  final void Function(DocBlock) onAddBlock;
  final void Function(int blockIndex) onRemoveBlock;

  const _SectionEditor({
    required this.section,
    required this.sectionIndex,
    required this.expanded,
    required this.onToggle,
    required this.onRemoveSection,
    required this.onUpdateSection,
    required this.onAddBlock,
    required this.onRemoveBlock,
  });

  @override
  State<_SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends State<_SectionEditor> {
  late TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.section.title);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          InkWell(
            onTap: widget.onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    widget.expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: Brand.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                        color: Brand.primary, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.section.number}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _titleCtrl,
                      onChanged: (v) => widget.onUpdateSection(
                        widget.section.copyWith(title: v),
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: DocFonts.body(size: 14, weight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Brand.textSecondary),
                    onPressed: widget.onRemoveSection,
                    tooltip: 'Xoá section',
                  ),
                ],
              ),
            ),
          ),
          if (widget.expanded) ...[
            const Divider(height: 1, indent: 12, endIndent: 12),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blocks list
                  for (var b = 0; b < widget.section.blocks.length; b++)
                    _BlockChip(
                      block: widget.section.blocks[b],
                      index: b,
                      onRemove: () => widget.onRemoveBlock(b),
                    ),
                  const SizedBox(height: 8),
                  // Add block
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final (type, label) in _blockTypes)
                        GestureDetector(
                          onTap: () => widget.onAddBlock(_makeBlock(type)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Brand.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Brand.border),
                            ),
                            child: Text(
                              '+ $label',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Brand.textPrimary),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const _blockTypes = <(String, String)>[
    ('heading', 'Heading'),
    ('paragraph', 'Paragraph'),
    ('callout', 'Callout'),
    ('steps', 'Steps'),
    ('passage', 'Passage'),
    ('quiz', 'Quiz'),
    ('vocab', 'Vocab'),
    ('pattern', 'Pattern'),
    ('image', 'Image'),
    ('slideBreak', 'Slide Break'),
  ];

  DocBlock _makeBlock(String type) => switch (type) {
        'heading' => DocBlock.heading(text: 'New heading'),
        'paragraph' => DocBlock.paragraph(text: 'New paragraph'),
        'callout' => DocBlock.callout(text: 'New callout'),
        'steps' => DocBlock.steps(items: ['Step 1']),
        'passage' => DocBlock.passage(label: 'Label', text: 'Content'),
        'quiz' => DocBlock.quiz(
            question: 'Question?',
            options: ['A', 'B', 'C', 'D'],
            correctIndex: 0,
            explanation: ''),
        'vocab' => DocBlock.vocab(
            items: [VocabItem(word: 'word', meaning: 'meaning')]),
        'pattern' => DocBlock.pattern(text: 'pattern'),
        'image' => DocBlock.image(url: '', alt: 'image'),
        'slideBreak' => DocBlock.slideBreak(),
        _ => DocBlock.paragraph(text: ''),
      };
}

// ─── Block Chip ──────────────────────────────────────────────────────────────

class _BlockChip extends StatelessWidget {
  final DocBlock block;
  final int index;
  final VoidCallback onRemove;

  const _BlockChip({required this.block, required this.index, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final typeLabel = block.typeLabel;
    final preview = _preview(block);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Brand.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Brand.border),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Brand.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              typeLabel,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Brand.primary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Brand.textSecondary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onRemove,
            tooltip: 'Xoá block',
          ),
        ],
      ),
    );
  }

  String _preview(DocBlock b) => b.when(
        heading: (_, text) => text,
        paragraph: (_, text) => text,
        callout: (_, text) => text,
        steps: (_, items) => '${items.length} bước',
        passage: (_, label, _) => label,
        quiz: (_, question, options, _, _) =>
            '$question (${options.length} options)',
        vocab: (_, items) => '${items.length} từ',
        pattern: (_, text) => text,
        image: (_, url, alt) => alt.isNotEmpty ? alt : url,
        slideBreak: (_) => '--- slide break ---',
        unknown: (_, type, _) => 'Unknown: $type',
      );
}
