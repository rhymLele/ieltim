import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/doc_status.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../../../domain/rules/doc_validator.dart';
import '../../../domain/rules/html_file.dart';
import '../../cubits/doc_creator_cubit.dart';
import '../common_widgets.dart';
import 'creator_flows.dart';

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// Bước 3: cài đặt hiển thị, thời điểm xuất bản, kết quả kiểm tra. Xuất bản xong: thẻ thành công.
class StepPublish extends StatelessWidget {
  const StepPublish({super.key, required this.state, required this.onCreateNext});

  final DocCreatorState state;

  /// "Tạo tài liệu N" trên thẻ thành công.
  final ValueChanged<int> onCreateNext;

  @override
  Widget build(BuildContext context) {
    if (state.published) return PublishSuccessCard(state: state, onCreateNext: onCreateNext);
    return ListView(
      padding: const EdgeInsets.all(AppSpace.xxl),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DisplaySettingsCard(state: state),
              const SizedBox(height: AppSpace.lg),
              ValidationSummary(state: state),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Hiển thị cho người dùng": kiểu mặc định, cho đổi Slide / Doc, xuất bản ngay hay hẹn giờ.
class DisplaySettingsCard extends StatelessWidget {
  const DisplaySettingsCard({super.key, required this.state});

  final DocCreatorState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocCreatorCubit>();
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hiển thị cho người dùng', style: AppText.heading),
          const SizedBox(height: 14),
          if (state.isHtmlDoc) ...[
            const Text('Tài liệu HTML hiển thị nguyên file, file tự lo trình chiếu. Không có Slide / Doc.', style: AppText.body),
            const SizedBox(height: 10),
          ] else ...[
            const Text('Kiểu mặc định', style: AppText.label),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              _ChoiceButton(label: 'Slide', selected: state.defaultView == DocViewMode.slide, onTap: () => cubit.setDefaultView(DocViewMode.slide)),
              _ChoiceButton(label: 'Doc', selected: state.defaultView == DocViewMode.doc, onTap: () => cubit.setDefaultView(DocViewMode.doc)),
            ]),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              key: const Key('weekly_docs_creator_allow_switch_toggle'),
              contentPadding: EdgeInsets.zero,
              value: state.allowSwitch,
              activeThumbColor: AppColors.primary,
              onChanged: (allow) => cubit.setAllowSwitch(allow: allow),
              title: const Text('Cho phép người dùng tự đổi giữa Slide và Doc', style: AppText.label),
            ),
          ],
          if (!state.isPublishedDoc) ...[
            const SizedBox(height: 4),
            const Text('Thời điểm', style: AppText.label),
            _ScheduleOptions(scheduleMode: state.scheduleMode, scheduleAt: state.scheduleAt),
          ],
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: selected
            ? FilledButton(onPressed: onTap, child: Text(label))
            : OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: AppColors.textInk), child: Text(label)),
      );
}

/// "Xuất bản ngay" / "Hẹn giờ" (kèm nút chọn ngày giờ).
class _ScheduleOptions extends StatelessWidget {
  const _ScheduleOptions({required this.scheduleMode, required this.scheduleAt});

  final bool scheduleMode;
  final DateTime? scheduleAt;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocCreatorCubit>();
    final at = scheduleAt;
    return RadioGroup<bool>(
      groupValue: scheduleMode,
      onChanged: (scheduled) => cubit.setScheduleMode(scheduled: scheduled ?? false),
      child: Column(
        children: [
          const RadioListTile<bool>(
            key: Key('weekly_docs_creator_publish_now_radio'),
            contentPadding: EdgeInsets.zero,
            value: false,
            activeColor: AppColors.primary,
            title: Text('Xuất bản ngay', style: AppText.body),
          ),
          RadioListTile<bool>(
            key: const Key('weekly_docs_creator_schedule_radio'),
            contentPadding: EdgeInsets.zero,
            value: true,
            activeColor: AppColors.primary,
            title: const Text('Hẹn giờ', style: AppText.body),
            subtitle: scheduleMode
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('weekly_docs_creator_schedule_pick_button'),
                      onPressed: () => pickScheduleTime(context),
                      icon: const Icon(Icons.event_outlined, size: 18),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      label: Text(at == null ? 'Chọn ngày giờ' : '${at.day}/${at.month}/${at.year} ${_twoDigits(at.hour)}:${_twoDigits(at.minute)}'),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Kết quả kiểm tra: lỗi (đỏ) / lưu ý (vàng) / sẵn sàng (xanh); bấm lỗi để về đúng khối.
class ValidationSummary extends StatelessWidget {
  const ValidationSummary({super.key, required this.state});

  final DocCreatorState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocCreatorCubit>();
    final v = state.validation;
    final doc = state.doc;
    final blocks = doc.sections.fold<int>(0, (n, s) => n + s.blocks.length);
    final issues = <ValidationIssue>[...v.errors, ...v.warnings];
    final (bg, fg, title) = !v.isValid
        ? (AppColors.errorBg, AppColors.primary, '${v.errors.length} lỗi cần sửa')
        : (v.warnings.isNotEmpty ? (AppColors.tipBg, AppColors.warnText, 'Hợp lệ, nhưng còn lưu ý') : (AppColors.successBg, AppColors.success, 'Hợp lệ, sẵn sàng xuất bản'));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 6),
          if (issues.isEmpty)
            Text(
              state.isHtmlDoc ? '${state.htmlFileName} · ${formatFileSize(state.htmlSize)}' : '${doc.sections.length} section, $blocks khối',
              style: AppText.body.copyWith(fontSize: 13),
            ),
          for (final issue in issues)
            InkWell(
              onTap: issue.location == null ? null : () => cubit.jumpToIssue(issue),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• $issue', style: AppText.body.copyWith(fontSize: 13))),
            ),
        ],
      ),
    );
  }
}

/// Xuất bản / hẹn giờ xong: sao chép JSON, tạo tài liệu tiếp theo cùng tuần.
class PublishSuccessCard extends StatelessWidget {
  const PublishSuccessCard({super.key, required this.state, required this.onCreateNext});

  final DocCreatorState state;
  final ValueChanged<int> onCreateNext;

  Future<void> _copyJson(BuildContext context, String id) async {
    await Clipboard.setData(ClipboardData(text: context.read<DocCreatorCubit>().prettyJson()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã sao chép $id.json')));
  }

  @override
  Widget build(BuildContext context) {
    final doc = state.doc;
    final scheduled = state.record?.status == DocStatus.scheduled;
    final nextOrder = context.read<DocCreatorCubit>().nextOrder(doc.week);
    return ListView(
      padding: const EdgeInsets.all(AppSpace.xxl),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AppCard(
            radius: AppRadius.cardLg,
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.success, size: 28),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  scheduled ? 'Đã hẹn giờ ${doc.numberLabel} · Tuần ${doc.week}' : 'Đã xuất bản ${doc.numberLabel} vào Tuần ${doc.week}',
                  style: AppText.title.copyWith(fontSize: 22),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  state.isHtmlDoc
                      ? 'Người dùng sẽ thấy tài liệu ở mục Theo tuần, hiển thị nguyên file HTML.'
                      : 'Người dùng sẽ thấy tài liệu ở mục Theo tuần, mặc định hiển thị dạng ${state.defaultView == DocViewMode.slide ? 'Slide' : 'Doc'}.',
                  style: AppText.body.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpace.lg),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      key: const Key('weekly_docs_creator_copy_json_button'),
                      onPressed: () => _copyJson(context, doc.id),
                      child: Text('Sao chép ${doc.id}.json'),
                    ),
                    OutlinedButton(
                      key: const Key('weekly_docs_creator_create_next_button'),
                      onPressed: () => onCreateNext(doc.week),
                      child: Text('Tạo ${state.category.label.toLowerCase()} $nextOrder'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
