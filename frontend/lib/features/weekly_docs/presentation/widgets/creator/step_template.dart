import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../../../domain/rules/doc_templates.dart';
import '../../../domain/rules/html_file.dart';
import '../../cubits/doc_creator_cubit.dart';
import '../common_widgets.dart';
import 'creator_flows.dart';

/// Bước 1: tên · tuần · số thứ tự · kỹ năng · chọn template.
class StepTemplate extends StatefulWidget {
  const StepTemplate({super.key, required this.state, required this.wide});

  final DocCreatorState state;
  final bool wide;

  @override
  State<StepTemplate> createState() => _StepTemplateState();
}

class _StepTemplateState extends State<StepTemplate> {
  late final _titleCtl = TextEditingController(text: widget.state.title);
  late final _weekCtl = TextEditingController(text: widget.state.weekText);
  late final _orderCtl = TextEditingController(text: widget.state.orderText);

  @override
  void didUpdateWidget(StepTemplate old) {
    super.didUpdateWidget(old);
    // Cubit tự điền ô (gợi ý số thứ tự, tên từ file HTML): chỉ ghi khi khác để không mất vị trí con trỏ.
    if (old.state.fieldsEpoch != widget.state.fieldsEpoch) {
      _sync(_titleCtl, widget.state.title);
      _sync(_weekCtl, widget.state.weekText);
      _sync(_orderCtl, widget.state.orderText);
    }
  }

  void _sync(TextEditingController controller, String text) {
    if (controller.text != text) controller.text = text;
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _weekCtl.dispose();
    _orderCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<DocCreatorCubit>();
    return ListView(
      padding: const EdgeInsets.all(AppSpace.xxl),
      children: [
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.md,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _LabeledField(
              label: 'Loại',
              child: _CategoryChips(selected: state.category, enabled: !state.isEdit, onSelected: cubit.setCategory),
            ),
            SizedBox(
              width: widget.wide ? 340 : double.infinity,
              child: _LabeledField(
                label: 'Tên ${state.category.label.toLowerCase()}',
                child: TextField(
                  key: const Key('weekly_docs_creator_title_field'),
                  controller: _titleCtl,
                  onChanged: cubit.setTitle,
                  decoration: InputDecoration(hintText: 'Ví dụ: Reading: Matching Headings', errorText: state.titleError),
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: _LabeledField(
                label: 'Tuần',
                child: TextField(
                  key: const Key('weekly_docs_creator_week_field'),
                  controller: _weekCtl,
                  enabled: !state.isEdit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: cubit.setWeekText,
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: _LabeledField(
                label: '${state.category.label} số',
                child: TextField(
                  key: const Key('weekly_docs_creator_order_field'),
                  controller: _orderCtl,
                  enabled: !state.isEdit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: cubit.setOrderText,
                  decoration: InputDecoration(errorText: state.orderError, errorMaxLines: 2),
                ),
              ),
            ),
            _LabeledField(label: 'Kỹ năng', child: _SkillChips(selected: state.skill, onSelected: cubit.setSkill)),
          ],
        ),
        if (state.isEdit) ...[
          const SizedBox(height: 6),
          const Text('Loại, tuần và số thứ tự không đổi được sau khi tạo. Muốn chuyển tuần, hãy dùng "Nhân bản".', style: AppText.caption),
        ],
        const SizedBox(height: AppSpace.xl),
        const Eyebrow('Chọn template'),
        const SizedBox(height: 10),
        _TemplateGrid(state: state),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [Text(label, style: AppText.label), const SizedBox(height: 6), child],
      );
}

/// Tài liệu / Bài tập (HOMEWORK). Đang sửa thì khoá (loại là một phần của mã tài liệu).
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.enabled, required this.onSelected});

  final DocCategory selected;
  final bool enabled;
  final ValueChanged<DocCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final c in DocCategory.values)
          ChoiceChip(
            key: Key('weekly_docs_creator_category_${c.name}_chip'),
            label: Text(c == DocCategory.homework ? '${c.label} (HOMEWORK)' : c.label),
            selected: selected == c,
            onSelected: enabled ? (_) => onSelected(c) : null,
            showCheckmark: false,
            selectedColor: AppColors.primary,
            disabledColor: selected == c ? AppColors.primary : AppColors.cardSurface,
            backgroundColor: AppColors.cardSurface,
            side: BorderSide(color: selected == c ? AppColors.primary : AppColors.borderStrong),
            shape: const StadiumBorder(),
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected == c ? AppColors.onPrimary : AppColors.textInk),
          ),
      ],
    );
  }
}

class _SkillChips extends StatelessWidget {
  const _SkillChips({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final e in skillLabels.entries)
          ChoiceChip(
            key: Key('weekly_docs_creator_skill_${e.key}_chip'),
            label: Text(e.value),
            selected: selected == e.key,
            onSelected: (_) => onSelected(e.key),
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.cardSurface,
            side: BorderSide(color: selected == e.key ? AppColors.primary : AppColors.borderStrong),
            shape: const StadiumBorder(),
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected == e.key ? AppColors.onPrimary : AppColors.textInk),
          ),
      ],
    );
  }
}

/// Lưới thẻ template: 3 / 2 / 1 cột theo bề rộng.
class _TemplateGrid extends StatelessWidget {
  const _TemplateGrid({required this.state});

  final DocCreatorState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 700 ? 3 : (c.maxWidth >= 420 ? 2 : 1);
      const gap = 14.0;
      final width = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final t in docTemplates)
            SizedBox(
              width: width,
              child: TemplateCard(
                template: t,
                selected: state.templateId == t.id,
                // Thẻ HTML đang chọn thì hiện file đã tải thay cho mô tả.
                selectedFileLabel: t.isHtml && state.isHtmlDoc ? 'Đã chọn: ${state.htmlFileName} · ${formatFileSize(state.htmlSize)}' : null,
                onTap: () => pickTemplate(context, t),
              ),
            ),
        ],
      );
    });
  }
}

/// Thẻ template: ảnh thu nhỏ (dàn ý), tên, mô tả.
class TemplateCard extends StatelessWidget {
  const TemplateCard({super.key, required this.template, required this.selected, required this.onTap, this.selectedFileLabel});

  final DocTemplate template;
  final bool selected;
  final VoidCallback onTap;
  final String? selectedFileLabel;

  @override
  Widget build(BuildContext context) {
    final t = template;
    final on = selected;
    final code = t.isImport || t.isHtml;
    final thumbBg = code ? AppColors.codeBg : (on ? AppColors.primary : AppColors.sidebar);
    final thumbFg = code ? AppColors.codeText : (on ? AppColors.onPrimary : AppColors.textMuted);
    final bar = code ? AppColors.gold : (on ? AppColors.onPrimary.withAlpha(128) : AppColors.borderStrong);
    final description = on ? (selectedFileLabel ?? t.description) : t.description;
    return Semantics(
      selected: on,
      button: true,
      label: 'Template ${t.name}${on ? ', đang chọn' : ''}',
      child: Material(
        color: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: on ? AppColors.primary : AppColors.borderLight, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('weekly_docs_creator_template_${t.id}_card'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 96,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: thumbBg, borderRadius: BorderRadius.circular(AppRadius.md)),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.isImport ? '{ JSON }' : (t.isHtml ? '</> HTML' : t.id.toUpperCase()),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, height: 1.2, color: thumbFg),
                      ),
                      const SizedBox(height: 2),
                      for (final line in t.outline.take(4)) _OutlineLine(text: line, bar: bar, color: thumbFg),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text(t.name, style: AppText.label.copyWith(fontSize: 14, fontWeight: FontWeight.w800))),
                    if (on) const Text('ĐANG CHỌN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(height: 1.45)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineLine extends StatelessWidget {
  const _OutlineLine({required this.text, required this.bar, required this.color});

  final String text;
  final Color bar;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 14, height: 4, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, height: 1.3, color: color))),
        ],
      );
}
