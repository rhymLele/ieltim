import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/brand_colors.dart';
import '../../../../bloc/doc_creator_bloc.dart';
import '../../../../domain/doc_validator.dart';
import '../../../../domain/models/weekly_doc.dart';
import '../../../doc_theme.dart';

/// Bước 3: settings xuất bản + kết quả validate.
class StepPublish extends StatelessWidget {
  const StepPublish({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DocCreatorBloc>().state;
    final doc = state.doc!;
    final meta = doc.meta;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // View mode settings
          _SectionTitle('Kiểu xem mặc định'),
          Row(
            children: [
              _ViewModeChip(
                label: 'Doc',
                icon: Icons.description_outlined,
                selected: meta.defaultView == DocViewMode.doc,
                enabled: meta.allowedViews.contains(DocViewMode.doc),
                onTap: meta.allowedViews.contains(DocViewMode.doc)
                    ? () => context.read<DocCreatorBloc>().add(
                          UpdatePublish(defaultView: DocViewMode.doc),
                        )
                    : null,
              ),
              const SizedBox(width: 10),
              _ViewModeChip(
                label: 'Slide',
                icon: Icons.photo_size_select_actual,
                selected: meta.defaultView == DocViewMode.slide,
                enabled: meta.allowedViews.contains(DocViewMode.slide),
                onTap: meta.allowedViews.contains(DocViewMode.slide)
                    ? () => context.read<DocCreatorBloc>().add(
                          UpdatePublish(defaultView: DocViewMode.slide),
                        )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Allowed views
          _SectionTitle('Cho phép người dùng xem dạng'),
          Row(
            children: [
              _ToggleChip(
                label: 'Doc',
                selected: meta.allowedViews.contains(DocViewMode.doc),
                onTap: () {
                  final views = List<DocViewMode>.from(meta.allowedViews);
                  if (views.contains(DocViewMode.doc)) {
                    if (views.length <= 1) return; // keep at least 1
                    views.remove(DocViewMode.doc);
                  } else {
                    views.add(DocViewMode.doc);
                  }
                  context.read<DocCreatorBloc>().add(
                        UpdatePublish(
                          allowedViews: views,
                          defaultView: meta.defaultView
                                  .allowedIn(views)
                              ? meta.defaultView
                              : views.first,
                        ),
                      );
                },
              ),
              const SizedBox(width: 10),
              _ToggleChip(
                label: 'Slide',
                selected: meta.allowedViews.contains(DocViewMode.slide),
                onTap: () {
                  final views = List<DocViewMode>.from(meta.allowedViews);
                  if (views.contains(DocViewMode.slide)) {
                    if (views.length <= 1) return;
                    views.remove(DocViewMode.slide);
                  } else {
                    views.add(DocViewMode.slide);
                  }
                  context.read<DocCreatorBloc>().add(
                        UpdatePublish(
                          allowedViews: views,
                          defaultView: meta.defaultView
                                  .allowedIn(views)
                              ? meta.defaultView
                              : views.first,
                        ),
                      );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Cho phép người dùng tự đổi kiểu xem',
              style: DocFonts.body(size: 13),
            ),
            subtitle: Text(
              meta.allowedViews.length > 1
                  ? 'Có 2+ kiểu → hiện nút đổi'
                  : 'Chỉ 1 kiểu → không hiện',
              style: DocFonts.body(size: 11)
                  .copyWith(color: Brand.textSecondary),
            ),
            value: meta.allowUserSwitchView,
            onChanged: (v) => context.read<DocCreatorBloc>().add(
                  UpdatePublish(allowUserSwitchView: v ?? false),
                ),
          ),
          const Divider(height: 24),

          // Validation results
          _SectionTitle('Kiểm tra'),
          if (state.validations.isEmpty)
            const _ValidRow(ok: true, text: 'Không có lỗi. Sẵn sàng xuất bản!')
          else ...[
            for (final v in state.validations)
              _ValidRow(
                ok: v.level == IssueLevel.warning,
                text: v.message,
                path: v.path,
              ),
          ],
          const SizedBox(height: 20),

          // Summary
          _SectionTitle('Tóm tắt'),
          _SummaryCard(doc: doc),
        ],
      ),
    );
  }
}

// DocViewMode helper
extension DocViewModeX on DocViewMode {
  bool allowedIn(List<DocViewMode> views) => views.contains(this);
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: DocFonts.body(size: 13, weight: FontWeight.w700)
            .copyWith(color: Brand.textSecondary),
      ),
    );
  }
}

class _ViewModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _ViewModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Brand.primary : Brand.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Brand.primary : Brand.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : Brand.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Brand.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Brand.success.withOpacity(0.1)
              : Brand.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Brand.success : Brand.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color: selected ? Brand.success : Brand.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Brand.success : Brand.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidRow extends StatelessWidget {
  final bool ok;
  final String text;
  final String? path;

  const _ValidRow({required this.ok, required this.text, this.path});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: ok ? Brand.success : Brand.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: ok ? Brand.textPrimary : Brand.error,
              ),
            ),
          ),
          if (path != null && path!.isNotEmpty)
            Text(
              path!,
              style: const TextStyle(
                  fontSize: 10, color: Brand.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final WeeklyDoc doc;
  const _SummaryCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final meta = doc.meta;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('ID', doc.id),
          _row('Tiêu đề', meta.title),
          _row('Tuần', '${meta.week} · #${meta.order}'),
          _row('Kỹ năng', meta.skill ?? '—'),
          _row('Kiểu mặc định', meta.defaultView.name),
          _row('Sections', '${doc.sections.length}'),
          _row('Blocks', '${doc.totalBlocks}'),
          _row('Thời lượng ước tính', '${meta.estimatedMinutes} phút'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: Brand.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Brand.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
