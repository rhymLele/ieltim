// weeks_screen.dart — U1: danh sách theo tuần (mobile + desktop). Bố cục: file 6 mục U1.

import 'package:flutter/material.dart';

import '../../core/app_tokens.dart';
import '../../data/weekly_docs_repository.dart';
import '../../domain/weekly_doc.dart';
import '../widgets/common_widgets.dart';
import 'doc_reader_screen.dart';

class WeeksScreen extends StatefulWidget {
  const WeeksScreen({super.key, required this.repo, this.onOpenMenu});

  final WeeklyDocsRepository repo;

  /// Mở drawer chung của app (mobile). null = ẩn nút ☰.
  final VoidCallback? onOpenMenu;

  @override
  State<WeeksScreen> createState() => _WeeksScreenState();
}

class _WeeksScreenState extends State<WeeksScreen> {
  late int _week = widget.repo.currentWeekNumber;
  final _chipsController = ScrollController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.repo.addListener(_onRepo);
    _load();
  }

  /// Tải danh sách tuần rồi tài liệu của tuần đang chọn (mặc định tuần hiện tại).
  Future<void> _load() async {
    try {
      await widget.repo.loadWeeks();
      bool open(int n) => widget.repo.weeks.any((w) => w.number == n && !w.isLocked);
      if (!open(_week)) _week = widget.repo.currentWeekNumber;
      if (open(_week)) await widget.repo.loadWeekDocs(_week);
      _error = null;
    } on RepoException catch (e) {
      _error = e.message;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  Future<void> _reload() {
    setState(() {
      _loading = true;
      _error = null;
    });
    return _load();
  }

  Future<void> _selectWeek(int number) async {
    setState(() => _week = number);
    try {
      await widget.repo.loadWeekDocs(number);
    } on RepoException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  void dispose() {
    widget.repo.removeListener(_onRepo);
    _chipsController.dispose();
    super.dispose();
  }

  void _onRepo() => setState(() {});

  /// Tuần đã mở + tuần sắp mở gần nhất. BE tự sinh sẵn vài tuần tới cho admin soạn trước;
  /// người học chỉ cần thấy tuần kế tiếp.
  List<WeekInfo> get _visibleWeeks {
    final weeks = widget.repo.weeks;
    final firstLocked = weeks.indexWhere((w) => w.isLocked);
    return [for (var i = 0; i < weeks.length; i++) if (!weeks[i].isLocked || i == firstLocked) weeks[i]];
  }

  void _scrollToCurrent() {
    if (!_chipsController.hasClients) return;
    final i = _visibleWeeks.indexWhere((w) => w.number == _week);
    _chipsController.jumpTo((i * 92.0 - 16).clamp(0.0, _chipsController.position.maxScrollExtent));
  }

  Future<void> _open(DocRecord d) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DocReaderScreen(repo: widget.repo, docId: d.id)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final desktop = c.maxWidth >= AppBreakpoints.desktop;
      final docs = widget.repo.publishedDocs(_week);
      final content = RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _reload,
        child: widget.repo.weeks.isEmpty ? _noWeeks(desktop) : ListView(
          padding: desktop ? const EdgeInsets.all(AppSpace.xxxl) : const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            if (desktop) ...[
              const Text('Theo tuần', style: AppText.display),
              const SizedBox(height: AppSpace.lg),
            ],
            _weekChips(desktop),
            const SizedBox(height: 14),
            _weekCard(docs, desktop),
            const SizedBox(height: 14),
            const Eyebrow('Tài liệu tuần này'),
            const SizedBox(height: AppSpace.md),
            if (_loading && docs.isEmpty)
              for (var i = 0; i < 2; i++) ...[const SkeletonBox(height: 108, radius: AppRadius.cardLg), const SizedBox(height: 14)]
            else if (docs.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 24), child: EmptyState(message: 'Tuần này chưa có tài liệu'))
            else if (desktop)
              _docGrid(docs, c.maxWidth)
            else
              ...[
                for (final d in docs) ...[_DocCard(record: d, progress: widget.repo.progressOf(d.id), onTap: () => _open(d)), const SizedBox(height: 14)],
              ],
            const SizedBox(height: 2),
            _hintBox(),
          ],
        ),
      );
      if (desktop) return ColoredBox(color: AppColors.background, child: Align(alignment: Alignment.topLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1080), child: content)));
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 60,
          leading: widget.onOpenMenu == null ? null : IconButton(tooltip: 'Mở menu', icon: const Icon(Icons.menu_rounded), onPressed: widget.onOpenMenu),
          titleSpacing: widget.onOpenMenu == null ? 16 : 0,
          title: const Text('Theo tuần', style: AppText.heading),
          shape: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        body: content,
      );
    });
  }

  /// Chưa có tuần nào: đang tải, lỗi (thử lại), hoặc admin chưa tạo tuần.
  Widget _noWeeks(bool desktop) {
    final Widget body;
    if (_error != null) {
      body = EmptyState(isError: true, message: _error!, actionLabel: 'Thử lại', onAction: _reload);
    } else if (_loading) {
      body = const Column(children: [SkeletonBox(height: 56, radius: AppRadius.card), SizedBox(height: 14), SkeletonBox(height: 96, radius: AppRadius.cardLg)]);
    } else {
      body = const EmptyState(message: 'Chưa có tuần học nào');
    }
    return ListView(
      padding: desktop ? const EdgeInsets.all(AppSpace.xxxl) : const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        if (desktop) ...[const Text('Theo tuần', style: AppText.display), const SizedBox(height: AppSpace.lg)],
        body,
      ],
    );
  }

  Widget _weekChips(bool desktop) {
    final weeks = _visibleWeeks;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        controller: _chipsController,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: weeks.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (_, i) {
          final w = weeks[i];
          final selected = w.number == _week;
          // BE tính sẵn số tài liệu / số đã học của mỗi tuần; bản giả thì đếm từ danh sách.
          final docs = widget.repo.publishedDocs(w.number);
          final total = w.docTotal ?? docs.length;
          final done = w.docDone ?? docs.where((d) => widget.repo.progressOf(d.id).completed).length;
          final allDone = total > 0 && done == total;
          final sub = w.isLocked ? w.opensLabel : (allDone && !selected ? '$done/$total ✓' : '$done/$total tài liệu');
          final bg = selected ? AppColors.primary : (w.isLocked ? AppColors.locked : AppColors.surface);
          final fg = selected ? AppColors.onPrimary : (w.isLocked ? AppColors.textDisabled : AppColors.text);
          return Semantics(
            button: !w.isLocked,
            selected: selected,
            label: 'Tuần ${w.number}, $sub${w.isLocked ? ', chưa mở' : ''}',
            excludeSemantics: true,
            child: Material(
              color: bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card), side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: 1.5)),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: w.isLocked ? null : () => _selectWeek(w.number),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 84),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tuần ${w.number}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                      const SizedBox(height: 2),
                      Text(sub, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg.withAlpha(217))),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _weekCard(List<DocRecord> docs, bool desktop) {
    final w = widget.repo.weekOf(_week);
    final done = docs.where((d) => widget.repo.progressOf(d.id).completed).length;
    final total = docs.length;
    final value = total == 0 ? 0.0 : done / total;
    final bar = PillProgress(value: value, height: 8, color: AppColors.goldLight, track: AppColors.onPrimary.withAlpha(51));
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.cardLg)),
      child: desktop
          ? Row(
              children: [
                Text('Tuần ${w.number}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onPrimary)),
                const SizedBox(width: AppSpace.md),
                Text(w.rangeLabel, style: const TextStyle(fontSize: 12, color: AppColors.softOnPrimary)),
                const SizedBox(width: AppSpace.xxl),
                Expanded(child: bar),
                const SizedBox(width: AppSpace.lg),
                Text('$done/$total tài liệu đã học · Học xong tuần để vượt vũ môn', style: const TextStyle(fontSize: 12, color: AppColors.softOnPrimary)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Tuần ${w.number}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onPrimary)),
                    const Spacer(),
                    Text(w.rangeLabel, style: const TextStyle(fontSize: 12, color: AppColors.softOnPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                bar,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('$done/$total tài liệu đã học', style: const TextStyle(fontSize: 12, color: AppColors.softOnPrimary)),
                    const Spacer(),
                    const Flexible(child: Text('Học xong tuần để vượt vũ môn', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: AppColors.softOnPrimary))),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _docGrid(List<DocRecord> docs, double width) {
    final cols = width >= 1200 ? 3 : 2;
    return LayoutBuilder(builder: (context, c) {
      const gap = 16.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final d in docs) SizedBox(width: w, child: _DocCard(record: d, progress: widget.repo.progressOf(d.id), onTap: () => _open(d))),
        ],
      );
    });
  }

  Widget _hintBox() {
    final next = widget.repo.weeks.where((w) => w.isLocked).toList();
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          'Tài liệu mới của tuần sẽ hiện ở đây khi admin xuất bản.${next.isEmpty ? '' : ' Tuần ${next.first.number} ${next.first.opensLabel.toLowerCase()}.'}',
          style: AppText.caption.copyWith(fontSize: 13, height: 1.5),
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({required this.record, required this.progress, required this.onTap});
  final DocRecord record;
  final DocProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final doc = record.doc;
    final total = record.sectionCount;
    final seen = progress.completed ? total : progress.seenSections.length.clamp(0, total);
    final done = progress.completed;
    final status = done ? 'Đã học' : (seen == 0 ? 'Chưa học' : 'Đang học $seen/$total');
    final statusColor = done ? AppColors.success : (seen == 0 ? AppColors.textMuted : AppColors.primary);
    final isSlide = doc.meta.defaultView == DocViewMode.slide;
    // Tài liệu HTML chỉ có 2 trạng thái: Chưa học / Đã học.
    final kind = doc.isHtml ? 'HTML · tự trình chiếu' : '${isSlide ? 'Slide' : 'Doc'} · $total phần · khoảng ${record.estimatedMinutes} phút';
    final icon = doc.isHtml ? Icons.code_rounded : (isSlide ? Icons.slideshow_outlined : Icons.description_outlined);
    return AppCard(
      radius: AppRadius.cardLg,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: done ? AppColors.successBg : AppColors.sidebar, borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Icon(icon, color: done ? AppColors.success : AppColors.primary),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tài liệu ${record.order} · ${skillLabels[doc.meta.skill] ?? doc.meta.skill}', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(doc.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, height: 1.25, fontWeight: FontWeight.w800, color: AppColors.text)),
                    const SizedBox(height: 3),
                    Text(kind, style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: PillProgress(value: done ? 1 : (total == 0 ? 0 : seen / total), color: done ? AppColors.success : AppColors.primary)),
              const SizedBox(width: 10),
              Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.lg));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.borderStrong;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + 6).clamp(0, m.length)), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
