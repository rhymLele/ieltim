import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../../../domain/rules/html_file.dart';
import '../../cubits/doc_creator_cubit.dart';
import '../common_widgets.dart';
import '../html_frame.dart';
import 'block_editor_panel.dart';
import 'creator_flows.dart';
import 'json_tab.dart';

/// Bước 2: soạn theo form / nhập JSON; tài liệu HTML thì thẻ file + hiển thị thử.
class StepContent extends StatelessWidget {
  const StepContent({super.key, required this.state, required this.jsonController});

  final DocCreatorState state;
  final TextEditingController jsonController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocCreatorCubit>();
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isPublishedDoc) const PublishedDocBanner(),
          if (state.isHtmlDoc)
            Expanded(child: HtmlTab(state: state))
          else ...[
            Row(
              children: [
                _ModeToggle(jsonMode: state.jsonMode, onChanged: (on) => cubit.setJsonMode(on: on)),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    state.jsonMode
                        ? 'Hệ thống đọc các key: schemaVersion, title, sections[].title, sections[].blocks[].type …'
                        : 'Mọi thay đổi được ghi vào JSON, xem trước cập nhật ngay.',
                    style: AppText.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(child: state.jsonMode ? JsonTab(controller: jsonController, check: state.jsonCheck) : FormTab(state: state)),
          ],
        ],
      ),
    );
  }
}

/// Tài liệu đang phát hành: thay đổi chỉ áp dụng khi bấm "Cập nhật bản phát hành".
class PublishedDocBanner extends StatelessWidget {
  const PublishedDocBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.tipBg, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: const Text(
          'Tài liệu đang hiển thị cho người dùng. Thay đổi chỉ được áp dụng khi bạn bấm "Cập nhật bản phát hành" ở bước 3.',
          style: TextStyle(fontSize: 13, color: AppColors.warnText, fontWeight: FontWeight.w600),
        ),
      );
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.jsonMode, required this.onChanged});

  final bool jsonMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.sidebar, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(key: const Key('weekly_docs_creator_form_mode_button'), label: 'Soạn theo form', selected: !jsonMode, onTap: () => onChanged(false)),
          _ModeButton(key: const Key('weekly_docs_creator_json_mode_button'), label: 'Nhập JSON', selected: jsonMode, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.primary : AppColors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: selected ? AppColors.onPrimary : AppColors.textMuted)),
          ),
        ),
      );
}

/// Tab "Soạn theo form": dàn ý (section / khối) + khung sửa khối đang chọn.
class FormTab extends StatelessWidget {
  const FormTab({super.key, required this.state});

  final DocCreatorState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocCreatorCubit>();
    final section = state.selectedSectionJson;
    // Template rỗng (vd. 'html' có sections: []) thì chưa có gì để sửa.
    if (section == null) {
      return AppCard(child: EmptyState(message: 'Tài liệu chưa có section nào', actionLabel: '+ Thêm section', onAction: cubit.addSection));
    }
    final sectionIndex = state.selectedSection.clamp(0, state.sections.length - 1);
    final blockCount = state.blocksOf(sectionIndex).length;
    return LayoutBuilder(builder: (context, c) {
      final outline = AppCard(padding: EdgeInsets.zero, child: DocOutline(state: state));
      final editor = AppCard(
        padding: EdgeInsets.zero,
        child: BlockEditorPanel(
          section: section,
          block: state.selectedBlockJson,
          fieldKeyPrefix: '$sectionIndex-${state.selectedBlock}-${state.epoch}',
          onChanged: cubit.contentEdited,
          onAddBlock: cubit.addBlock,
          onMoveUp: state.selectedBlock > 0 ? () => cubit.moveBlock(-1) : null,
          onMoveDown: state.selectedBlock < blockCount - 1 ? () => cubit.moveBlock(1) : null,
          onDelete: cubit.deleteBlock,
        ),
      );
      if (c.maxWidth < 640) {
        return Column(children: [SizedBox(height: 220, child: outline), const SizedBox(height: 14), Expanded(child: editor)]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [SizedBox(width: 290, child: outline), const SizedBox(width: 14), Expanded(child: editor)],
      );
    });
  }
}

/// Dàn ý: mỗi section một dòng tiêu đề, dưới là các khối; cuối có "+ Thêm section".
class DocOutline extends StatelessWidget {
  const DocOutline({super.key, required this.state});

  final DocCreatorState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocCreatorCubit>();
    final sections = state.sections;
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        for (var si = 0; si < sections.length; si++) ...[
          _OutlineSection(
            index: si,
            title: asJsonMap(sections[si])['title'] as String? ?? '',
            selected: si == state.selectedSection,
            onTap: () => cubit.select(si, 0),
          ),
          for (var bi = 0; bi < state.blocksOf(si).length; bi++)
            _OutlineRow(
              block: asJsonMap(state.blocksOf(si)[bi]),
              selected: si == state.selectedSection && bi == state.selectedBlock,
              onTap: () => cubit.select(si, bi),
            ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 4),
        OutlinedButton(
          key: const Key('weekly_docs_creator_add_section_button'),
          onPressed: cubit.addSection,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          child: const Text('+ Thêm section (slide mới)'),
        ),
      ],
    );
  }
}

class _OutlineSection extends StatelessWidget {
  const _OutlineSection({required this.index, required this.title, required this.selected, required this.onTap});

  final int index;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.sidebar : AppColors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SectionLabel(number: index + 1, title: title.isNotEmpty ? title : '(chưa đặt tên)', size: 20, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

/// Một khối trong dàn ý: loại khối + đoạn đầu nội dung.
class _OutlineRow extends StatelessWidget {
  const _OutlineRow({required this.block, required this.selected, required this.onTap});

  final Map<String, dynamic> block;
  final bool selected;
  final VoidCallback onTap;

  String get _snippet {
    final items = block['items'];
    final first = items is List && items.isNotEmpty ? items.first : null;
    final raw = block['text'] ?? block['question'] ?? block['structure'] ?? (first is Map ? first['word'] : first) ?? block['url'] ?? '';
    return raw.toString().replaceAll('**', '');
  }

  @override
  Widget build(BuildContext context) {
    final type = block['type'] as String? ?? '';
    final snippet = _snippet;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Material(
        color: selected ? AppColors.cardSurface : AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: selected ? const BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          hoverColor: AppColors.hover,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 7, 10, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(blockTypeLabels[type] ?? type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                if (snippet.isNotEmpty) Text(snippet, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textInk)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bước 2 của tài liệu HTML: thẻ file + khung "Hiển thị thử" chạy nguyên file.
class HtmlTab extends StatelessWidget {
  const HtmlTab({super.key, required this.state});

  final DocCreatorState state;

  @override
  Widget build(BuildContext context) {
    final html = state.html;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const HtmlFileBadge(),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.htmlFileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(html.isEmpty ? 'Chưa tải file' : formatFileSize(state.htmlSize), style: AppText.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              OutlinedButton.icon(
                key: const Key('weekly_docs_creator_change_html_button'),
                onPressed: () => pickHtmlFile(context),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Đổi file'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        const Eyebrow('Hiển thị thử'),
        const SizedBox(height: AppSpace.sm),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.borderLight)),
            clipBehavior: Clip.antiAlias,
            child: html.isEmpty ? EmptyState(message: 'Chưa tải file HTML', actionLabel: 'Tải file', onAction: () => pickHtmlFile(context)) : HtmlFrame(html: html),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        const Text('File tự lo trình chiếu và điều hướng. Bấm vào khung rồi dùng phím hoặc nút của file để thử.', style: AppText.caption),
      ],
    );
  }
}
