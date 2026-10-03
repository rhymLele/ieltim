// weeks_page.dart — U1: danh sách theo tuần (mobile + desktop). Bố cục: file 6 mục U1.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_routes.dart';
import '../../core/app_tokens.dart';
import '../../domain/entities/learner_doc.dart';
import '../cubits/ui_state.dart';
import '../cubits/weeks_cubit.dart';
import '../widgets/common_widgets.dart';
import '../widgets/weeks/new_docs_hint.dart';
import '../widgets/weeks/week_chips.dart';
import '../widgets/weeks/week_doc_card.dart';
import '../widgets/weeks/week_summary_card.dart';

class WeeksPage extends StatelessWidget {
  const WeeksPage({super.key, this.onOpenMenu});

  /// Mở drawer chung của app (mobile). null = ẩn nút ☰.
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WeeksCubit()..load(),
      child: BlocListener<WeeksCubit, WeeksState>(
        listenWhen: (prev, curr) => curr.notice != null && prev.notice?.id != curr.notice?.id,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.notice?.message ?? ''))),
        child: _WeeksLayout(onOpenMenu: onOpenMenu),
      ),
    );
  }
}

class _WeeksLayout extends StatelessWidget {
  const _WeeksLayout({required this.onOpenMenu});

  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final desktop = c.maxWidth >= AppBreakpoints.desktop;
      final content = RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<WeeksCubit>().refresh(),
        child: _WeeksContent(desktop: desktop, screenWidth: c.maxWidth),
      );
      if (desktop) {
        return ColoredBox(
          color: AppColors.background,
          child: Align(alignment: Alignment.topLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1080), child: content)),
        );
      }
      final menu = onOpenMenu;
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 60,
          leading: menu == null ? null : IconButton(tooltip: 'Mở menu', icon: const Icon(Icons.menu_rounded), onPressed: menu),
          titleSpacing: menu == null ? 16 : 0,
          title: const Text('Theo tuần', style: AppText.heading),
          shape: const Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        body: content,
      );
    });
  }
}

class _WeeksContent extends StatelessWidget {
  const _WeeksContent({required this.desktop, required this.screenWidth});

  final bool desktop;
  final double screenWidth;

  void _open(BuildContext context, WeekDocEntry entry) => context.go(AppRoutes.weeklyDoc(entry.summary.id));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WeeksCubit>().state;
    final padding = desktop ? const EdgeInsets.all(AppSpace.xxxl) : const EdgeInsets.fromLTRB(16, 14, 16, 28);
    final selected = state.selected;
    if (state.weekList.weeks.isEmpty || selected == null) {
      return ListView(
        padding: padding,
        children: [
          if (desktop) ...[const Text('Theo tuần', style: AppText.display), const SizedBox(height: AppSpace.lg)],
          _NoWeeksBody(state: state),
        ],
      );
    }
    final entries = state.entries;
    final done = entries.where((e) => e.progress.completed).length;
    final nextLocked = state.weekList.weeks.where((w) => w.isLocked);
    return ListView(
      padding: padding,
      children: [
        if (desktop) ...[const Text('Theo tuần', style: AppText.display), const SizedBox(height: AppSpace.lg)],
        WeekChips(weeks: state.visibleWeeks, selectedWeek: state.selectedWeek, onSelected: context.read<WeeksCubit>().selectWeek),
        const SizedBox(height: 14),
        WeekSummaryCard(week: selected, done: done, total: entries.length, desktop: desktop),
        const SizedBox(height: 14),
        const Eyebrow('Tài liệu tuần này'),
        const SizedBox(height: AppSpace.md),
        if (state.isLoadingDocs && entries.isEmpty)
          for (var i = 0; i < 2; i++) ...[const SkeletonBox(height: 108, radius: AppRadius.cardLg), const SizedBox(height: 14)]
        else if (entries.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 24), child: EmptyState(message: 'Tuần này chưa có tài liệu'))
        else if (desktop)
          WeekDocGrid(entries: entries, screenWidth: screenWidth, onOpen: (e) => _open(context, e))
        else
          for (final e in entries) ...[WeekDocCard(entry: e, onTap: () => _open(context, e)), const SizedBox(height: 14)],
        const SizedBox(height: 2),
        NewDocsHint(nextWeek: nextLocked.isEmpty ? null : nextLocked.first),
      ],
    );
  }
}

/// Chưa có tuần nào: đang tải, lỗi (thử lại), hoặc admin chưa tạo tuần.
class _NoWeeksBody extends StatelessWidget {
  const _NoWeeksBody({required this.state});

  final WeeksState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      LoadStatus.failure => EmptyState(
          isError: true,
          message: state.errorMessage ?? 'Không tải được danh sách tuần.',
          actionLabel: 'Thử lại',
          onAction: () => context.read<WeeksCubit>().refresh(),
        ),
      LoadStatus.loading => const Column(
          children: [SkeletonBox(height: 56, radius: AppRadius.card), SizedBox(height: 14), SkeletonBox(height: 96, radius: AppRadius.cardLg)],
        ),
      LoadStatus.ready => const EmptyState(message: 'Chưa có tuần học nào'),
    };
  }
}
