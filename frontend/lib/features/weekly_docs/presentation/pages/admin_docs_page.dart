// admin_docs_page.dart — A1: danh sách tài liệu theo tuần (admin). Nghiệp vụ: file 7 UC-D01, D06–D11, D13.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_routes.dart';
import '../../core/app_tokens.dart';
import '../../domain/entities/doc_summary.dart';
import '../cubits/admin_docs_cubit.dart';
import '../cubits/ui_state.dart';
import '../widgets/admin_list/admin_dialogs.dart';
import '../widgets/admin_list/admin_doc_action.dart';
import '../widgets/admin_list/admin_docs_table.dart';
import '../widgets/admin_list/admin_docs_toolbar.dart';
import '../widgets/common_widgets.dart';

class AdminDocsPage extends StatelessWidget {
  const AdminDocsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDocsCubit()..load(),
      child: BlocListener<AdminDocsCubit, AdminDocsState>(
        listenWhen: (prev, curr) => curr.notice != null && prev.notice?.id != curr.notice?.id,
        listener: (context, state) {
          final notice = state.notice!;
          final undoId = notice.undoDocId;
          final cubit = context.read<AdminDocsCubit>();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(notice.message),
              duration: const Duration(seconds: 8),
              action: undoId == null ? null : SnackBarAction(label: 'Hoàn tác', onPressed: () => cubit.undoDelete(undoId)),
            ));
        },
        child: const _AdminDocsView(),
      ),
    );
  }
}

class _AdminDocsView extends StatelessWidget {
  const _AdminDocsView();

  /// Màn soạn lồng dưới danh sách: đóng lại thì danh sách vẫn còn và tự tải lại sau mỗi lần lưu.
  void _openCreator(BuildContext context, {String? docId}) {
    final week = context.read<AdminDocsCubit>().state.week;
    context.go(docId == null ? AppRoutes.adminWeeklyDocCreate(week: week) : AppRoutes.adminWeeklyDocEdit(docId));
  }

  Future<void> _onAction(BuildContext context, DocSummary doc, AdminDocAction action) async {
    final cubit = context.read<AdminDocsCubit>();
    switch (action) {
      case AdminDocAction.edit:
        _openCreator(context, docId: doc.id);
      case AdminDocAction.preview:
        context.go(AppRoutes.adminWeeklyDocPreview(doc.id));
      case AdminDocAction.duplicate:
        final target = await WeekPickerDialog.show(context, cubit.state.weeks);
        if (target != null) await cubit.duplicate(doc.id, target);
      case AdminDocAction.export:
        final json = await cubit.exportJson(doc.id);
        if (json == null || !context.mounted) return;
        await Clipboard.setData(ClipboardData(text: json));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã sao chép nội dung ${doc.id}.json (tích hợp tải file ở tầng app)')));
      case AdminDocAction.unschedule:
        await cubit.unschedule(doc.id);
      case AdminDocAction.unpublish:
        final ok = await ConfirmActionDialog.show(
          context,
          title: 'Gỡ "${doc.title}"?',
          body: 'Người dùng sẽ không thấy tài liệu này nữa. Tiến độ đã học vẫn được giữ.',
          confirmLabel: 'Gỡ tài liệu',
        );
        if (ok) await cubit.unpublish(doc.id);
      case AdminDocAction.restore:
        await cubit.restore(doc.id);
      case AdminDocAction.delete:
        final ok = await ConfirmActionDialog.show(context, title: 'Xoá bản nháp "${doc.title}"?', body: 'Thao tác không hoàn tác được sau 8 giây.', confirmLabel: 'Xoá');
        if (ok) await cubit.delete(doc.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AdminDocsCubit>().state;
    final cubit = context.read<AdminDocsCubit>();
    final docs = state.visibleDocs;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.xxxl),
          children: [
            Row(
              children: [
                const Expanded(child: Text('Tài liệu theo tuần', style: AppText.title)),
                FilledButton.icon(
                  key: const Key('weekly_docs_admin_create_button'),
                  onPressed: () => _openCreator(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tạo tài liệu'),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            AdminDocsToolbar(
              weeks: state.weeks,
              week: state.week,
              statuses: state.statuses,
              onWeekChanged: cubit.setWeek,
              onStatusToggled: (s, selected) => cubit.toggleStatus(s, selected: selected),
              onQueryChanged: cubit.setQuery,
            ),
            const SizedBox(height: AppSpace.lg),
            switch (state.status) {
              LoadStatus.failure => EmptyState(isError: true, message: state.errorMessage ?? 'Không tải được danh sách.', actionLabel: 'Thử lại', onAction: cubit.retry),
              LoadStatus.loading => const Padding(padding: EdgeInsets.all(AppSpace.xxxl), child: Center(child: CircularProgressIndicator())),
              LoadStatus.ready when docs.isEmpty => EmptyState(message: 'Tuần này chưa có tài liệu', actionLabel: 'Tạo tài liệu', onAction: () => _openCreator(context)),
              LoadStatus.ready => AdminDocsTable(
                  docs: docs,
                  onOpen: (d) => _openCreator(context, docId: d.id),
                  onAction: (d, a) => _onAction(context, d, a),
                ),
            },
          ],
        ),
      ),
    );
  }
}
