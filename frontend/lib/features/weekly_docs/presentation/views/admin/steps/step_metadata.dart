import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/brand_colors.dart';
import '../../../../bloc/doc_creator_bloc.dart';
import '../../../../data/doc_templates.dart';
import '../../../doc_theme.dart';

/// Bước 1: nhập thông tin metadata + chọn template.
class StepMetadata extends StatefulWidget {
  const StepMetadata({super.key});

  @override
  State<StepMetadata> createState() => _StepMetadataState();
}

class _StepMetadataState extends State<StepMetadata> {
  late TextEditingController _titleCtrl;
  late TextEditingController _orderCtrl;
  String? _skill;
  String? _templateId;

  @override
  void initState() {
    super.initState();
    final doc = context.read<DocCreatorBloc>().state.doc!;
    _titleCtrl = TextEditingController(text: doc.meta.title);
    _orderCtrl = TextEditingController(text: '${doc.meta.order}');
    _skill = doc.meta.skill;
    _templateId = 'reading-lesson';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final order = int.tryParse(_orderCtrl.text.trim()) ?? 1;
    context.read<DocCreatorBloc>().add(UpdateMetadata(
          title: _titleCtrl.text.trim(),
          order: order,
          skill: _skill,
          templateId: _templateId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DocCreatorBloc>().state;
    final doc = state.doc!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _FieldLabel('Tên tài liệu *'),
          TextField(
            controller: _titleCtrl,
            onChanged: (_) => _apply(),
            decoration: const InputDecoration(
              hintText: 'VD: Reading: Academic Passage - Week 1',
              border: _InputBorder,
              focusedBorder: _FocusBorder,
            ),
            style: DocFonts.body(size: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Week
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Tuần *'),
                    DropdownButtonFormField<int>(
                      value: doc.meta.week,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: _InputBorder,
                        focusedBorder: _FocusBorder,
                      ),
                      items: state.weeks
                          .map((w) =>
                              DropdownMenuItem(value: w, child: Text('Tuần $w')))
                          .toList(),
                      onChanged: (w) {
                        if (w != null) _applyWeek(w);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Order
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Số thứ tự *'),
                    TextField(
                      controller: _orderCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _apply(),
                      decoration: const InputDecoration(
                        border: _InputBorder,
                        focusedBorder: _FocusBorder,
                      ),
                      style: DocFonts.body(size: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Skill
          const _FieldLabel('Kỹ năng *'),
          Row(
            children: const [
              'Reading',
              'Listening',
              'Writing',
              'Speaking',
              'Vocabulary',
            ].map((s) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: _SkillChip(key: ValueKey('')),
                  ),
                )),
          ),
          // Use Choice Chips instead
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: const [
              'Reading',
              'Listening',
              'Writing',
              'Speaking',
              'Vocabulary',
            ].map((s) {
              final selected = _skill == s;
              return GestureDetector(
                onTap: () {
                  setState(() => _skill = s);
                  _apply();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? Brand.primary : Brand.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? Brand.primary : Brand.border),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Brand.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Template
          const _FieldLabel('Template *'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: docTemplates.map((t) {
              final selected = _templateId == t.id;
              return GestureDetector(
                onTap: () {
                  setState(() => _templateId = t.id);
                  _apply();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? Brand.primary.withOpacity(0.06)
                        : Brand.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected ? Brand.primary : Brand.border,
                        width: selected ? 1.5 : 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.label,
                        style: DocFonts.body(
                            size: 13, weight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.description,
                        style: DocFonts.body(size: 11)
                            .copyWith(color: Brand.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Brand.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Brand.error.withOpacity(0.3)),
              ),
              child: Text(
                state.error!,
                style: const TextStyle(color: Brand.error, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _applyWeek(int week) {
    context.read<DocCreatorBloc>().add(UpdateMetadata(week: week));
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: DocFonts.body(size: 13, weight: FontWeight.w600)
            .copyWith(color: Brand.textPrimary),
      ),
    );
  }
}

const _InputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: Brand.border),
);
const _FocusBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: Brand.primary),
);

class _SkillChip extends StatelessWidget {
  const _SkillChip({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
