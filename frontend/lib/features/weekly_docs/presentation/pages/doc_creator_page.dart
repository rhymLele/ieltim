// doc_creator_page.dart — A2: tạo / sửa tài liệu, wizard 3 bước + cột xem trước.
// Bố cục: file 6 mục A2 · Nghiệp vụ: file 7 UC-D02, D03, D05, D12.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_routes.dart';
import '../../core/app_tokens.dart';
import '../../domain/entities/doc_category.dart';
import '../cubits/doc_creator_cubit.dart';
import '../cubits/ui_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/creator/conflict_dialog.dart';
import '../widgets/creator/creator_footer.dart';
import '../widgets/creator/creator_header.dart';
import '../widgets/creator/creator_preview.dart';
import '../widgets/creator/step_content.dart';
import '../widgets/creator/step_publish.dart';
import '../widgets/creator/step_template.dart';

class DocCreatorPage extends StatelessWidget {
  const DocCreatorPage({super.key, this.docId, this.initialWeek = 0, this.initialCategory = DocCategory.lesson});

  /// null = tạo mới; có giá trị = sửa (mở ở bước 2).
  final String? docId;

  /// Tuần gợi ý khi tạo mới; 0 = tuần hiện tại.
  final int initialWeek;

  /// Loại chọn sẵn khi tạo mới (đổi được ở bước 1).
  final DocCategory initialCategory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DocCreatorCubit(docId: docId, initialWeek: initialWeek, initialCategory: initialCategory)..start(),
      child: _DocCreatorView(isEditRoute: docId != null),
    );
  }
}

class _DocCreatorView extends StatefulWidget {
  const _DocCreatorView({required this.isEditRoute});

  final bool isEditRoute;

  @override
  State<_DocCreatorView> createState() => _DocCreatorViewState();
}

class _DocCreatorViewState extends State<_DocCreatorView> {
  /// Nội dung tab "Nhập JSON": admin gõ tự do, chỉ áp dụng khi bấm "Kiểm tra & áp dụng" / "Tiếp tục".
  final _jsonCtl = TextEditingController();

  DocCreatorCubit get _cubit => context.read<DocCreatorCubit>();

  @override
  void dispose() {
    _jsonCtl.dispose();
    super.dispose();
  }

  /// Đóng màn soạn: quay lại danh sách; mở thẳng bằng link thì đi tới danh sách admin.
  void _close() => context.canPop() ? context.pop() : context.go(AppRoutes.adminWeeklyDocs);

  void _forward() => _cubit.forward(jsonText: _cubit.state.jsonMode ? _jsonCtl.text : null);

  /// "Tạo tài liệu / bài tập N" sau khi xuất bản (cùng loại). Màn tạo mới vẫn ở cùng URL nên cubit tự làm lại từ đầu.
  void _createNext(int week) {
    final homework = _cubit.state.category == DocCategory.homework;
    if (!widget.isEditRoute) _cubit.startOver(week);
    context.go(AppRoutes.adminWeeklyDocCreate(week: week, homework: homework));
  }

  Future<void> _onConflict(String message) async {
    final reload = await ConflictDialog.show(context, message);
    if (mounted) await _cubit.resolveConflict(reload: reload);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Mở tab JSON, hoặc nội dung bị thay từ ngoài khi đang ở tab JSON: nạp lại JSON hiện tại.
        BlocListener<DocCreatorCubit, DocCreatorState>(
          listenWhen: (prev, curr) => curr.jsonMode && (!prev.jsonMode || (prev.epoch != curr.epoch && curr.jsonCheck == null)),
          listener: (_, _) => _jsonCtl.text = _cubit.prettyJson(),
        ),
        BlocListener<DocCreatorCubit, DocCreatorState>(
          listenWhen: (prev, curr) => curr.conflictMessage != null && prev.conflictMessage != curr.conflictMessage,
          listener: (_, state) => _onConflict(state.conflictMessage!),
        ),
        BlocListener<DocCreatorCubit, DocCreatorState>(
          listenWhen: (prev, curr) => curr.notice != null && prev.notice?.id != curr.notice?.id,
          listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.notice?.message ?? ''))),
        ),
      ],
      child: BlocBuilder<DocCreatorCubit, DocCreatorState>(builder: (context, state) {
        if (state.status != LoadStatus.ready) return _CreatorLoadingView(state: state, onClose: _close);
        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= AppBreakpoints.adminWide;
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  CreatorHeader(state: state, wide: wide, isEditRoute: widget.isEditRoute, onClose: _close),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: switch (state.step) {
                            1 => StepTemplate(state: state, wide: wide),
                            2 => StepContent(state: state, jsonController: _jsonCtl),
                            _ => StepPublish(state: state, onCreateNext: _createNext),
                          },
                        ),
                        if (wide)
                          Container(
                            width: 500,
                            decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.borderLight))),
                            child: const CreatorPreview(),
                          ),
                      ],
                    ),
                  ),
                  CreatorFooter(state: state, onForward: _forward),
                ],
              ),
            ),
          );
        });
      }),
    );
  }
}

/// Mở để sửa: đang tải bản đầy đủ, hoặc lỗi kèm "Thử lại".
class _CreatorLoadingView extends StatelessWidget {
  const _CreatorLoadingView({required this.state, required this.onClose});

  final DocCreatorState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final error = state.loadError;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(key: const Key('weekly_docs_creator_close_button'), tooltip: 'Đóng', icon: const Icon(Icons.close_rounded), onPressed: onClose),
        title: const Text('Sửa tài liệu', style: AppText.heading),
      ),
      body: state.status == LoadStatus.failure
          ? EmptyState(isError: true, message: error ?? 'Không tải được tài liệu.', actionLabel: 'Thử lại', onAction: context.read<DocCreatorCubit>().retryLoad)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
