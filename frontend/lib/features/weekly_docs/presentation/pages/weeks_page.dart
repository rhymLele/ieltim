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
    final lessons = entries.where((e) => !e.summary.isHomework).toList();
    final homework = entries.where((e) => e.summary.isHomework).toList();
    final nextLocked = state.weekList.weeks.where((w) => w.isLocked);
    final loading = state.isLoadingDocs && entries.isEmpty;
    return ListView(
      padding: padding,
      children: [
        if (desktop) ...[const Text('Theo tuần', style: AppText.display), const SizedBox(height: AppSpace.lg)],
        WeekChips(weeks: state.visibleWeeks, selectedWeek: state.selectedWeek, onSelected: context.read<WeeksCubit>().selectWeek),
        const SizedBox(height: 14),
        WeekSummaryCard(week: selected, counts: WeekProgressCounts.of(entries), desktop: desktop),
        const SizedBox(height: 14),
        _DocSection(
          key: const Key('weekly_docs_lessons_section'),
          title: 'Tài liệu tuần này',
          entries: lessons,
          isLoading: loading,
          emptyMessage: 'Tuần này chưa có tài liệu',
          desktop: desktop,
          screenWidth: screenWidth,
          onOpen: (e) => _open(context, e),
        ),
        if (!loading) ...[
          const SizedBox(height: AppSpace.lg),
          _DocSection(
            key: const Key('weekly_docs_homework_section'),
            title: 'Bài tập về nhà',
            entries: homework,
            isLoading: false,
            emptyMessage: 'Tuần này chưa có bài tập',
            desktop: desktop,
            screenWidth: screenWidth,
            onOpen: (e) => _open(context, e),
          ),
        ],
        const SizedBox(height: 2),
        NewDocsHint(nextWeek: nextLocked.isEmpty ? null : nextLocked.first),
      ],
    );
  }
}

/// Một nhóm thẻ có tiêu đề ("Tài liệu tuần này" / "Bài tập về nhà"): đang tải, trống, lưới (desktop) hoặc danh sách.
class _DocSection extends StatelessWidget {
  const _DocSection({
    super.key,
    required this.title,
    required this.entries,
    required this.isLoading,
    required this.emptyMessage,
    required this.desktop,
    required this.screenWidth,
    required this.onOpen,
  });

  final String title;
  final List<WeekDocEntry> entries;
  final bool isLoading;
  final String emptyMessage;
  final bool desktop;
  final double screenWidth;
  final ValueChanged<WeekDocEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Eyebrow(title),
        const SizedBox(height: AppSpace.md),
        if (isLoading)
          for (var i = 0; i < 2; i++) ...[const SkeletonBox(height: 108, radius: AppRadius.cardLg), const SizedBox(height: 14)]
        else if (entries.isEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(emptyMessage, style: AppText.caption))
        else if (desktop)
          Padding(padding: const EdgeInsets.only(bottom: 14), child: WeekDocGrid(entries: entries, screenWidth: screenWidth, onOpen: onOpen))
        else
          for (final e in entries) ...[WeekDocCard(entry: e, onTap: () => onOpen(e)), const SizedBox(height: 14)],
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
