// admin_docs_screen.dart — A1: danh sách tài liệu theo tuần (admin). Nghiệp vụ: file 7 UC-D01, D06–D11, D13.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_tokens.dart';
import '../../data/weekly_docs_repository.dart';
import '../../domain/weekly_doc.dart';
import '../user/doc_reader_screen.dart';
import '../widgets/common_widgets.dart';
import 'doc_creator_screen.dart';

class AdminDocsScreen extends StatefulWidget {
  const AdminDocsScreen({super.key, required this.repo});
  final WeeklyDocsRepository repo;

  @override
  State<AdminDocsScreen> createState() => _AdminDocsScreenState();
}

enum _Action { edit, preview, duplicate, export, unschedule, unpublish, restore, delete }

class _AdminDocsScreenState extends State<AdminDocsScreen> {
  int? _week;
  final Set<DocStatus> _statuses = {};
  String _query = '';
  bool _loading = true;
  String? _error;

  WeeklyDocsRepository get repo => widget.repo;

  @override
  void initState() {
    super.initState();
    _week = repo.currentWeekNumber;
    repo.addListener(_onRepo);
    _load();
  }

  Future<void> _load() async {
    try {
      await Future.wait<void>([repo.loadWeeks(), repo.loadAdminDocs()]);
      // Lần đầu chưa biết tuần hiện tại: chọn tuần chứa hôm nay (không có thì "Tất cả tuần").
      if (_week == 0 || (_week != null && !repo.weeks.any((w) => w.number == _week))) {
        _week = repo.currentWeekNumber == 0 ? null : repo.currentWeekNumber;
      }
      _error = null;
    } on RepoException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _reload() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  @override
  void dispose() {
    repo.removeListener(_onRepo);
    super.dispose();
  }

  void _onRepo() => setState(() {});

  Future<void> _openCreator({String? docId}) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DocCreatorScreen(repo: repo, docId: docId, initialWeek: _week ?? repo.currentWeekNumber),
    ));
    // Màn soạn đã lưu / xuất bản trên máy chủ: đồng bộ lại danh sách.
    repo.loadAdminDocs().catchError((Object e) => debugPrint('weekly_docs: $e'));
  }

  void _snack(String text, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action, duration: const Duration(seconds: 8)));
  }

  Future<bool> _confirm({required String title, required String body, required String ok, Widget? extra}) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.cardLg)),
        title: Text(title, style: AppText.heading),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(body, style: AppText.body), if (extra != null) ...[const SizedBox(height: AppSpace.md), extra]]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ok),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _onAction(DocRecord d, _Action a) async {
    try {
      switch (a) {
        case _Action.edit:
          await _openCreator(docId: d.id);
        case _Action.preview:
          // Danh sách chỉ có phần tóm tắt: tải đủ nội dung trước khi xem.
          final full = await repo.loadAdminDoc(d.id);
          if (!mounted) return;
          await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DocReaderScreen(repo: repo, docId: d.id, previewDoc: full.doc)));
        case _Action.duplicate:
          final target = await _pickWeek();
          if (target == null) return;
          final copy = await repo.duplicate(d.id, target);
          _snack('Đã nhân bản thành Tuần ${copy.week} · Tài liệu ${copy.order}');
        case _Action.export:
          final full = await repo.loadAdminDoc(d.id);
          await Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(full.json)));
          _snack('Đã sao chép nội dung ${d.id}.json (tích hợp tải file ở tầng app)');
        case _Action.unschedule:
          await repo.unschedule(d.id);
          _snack('Đã huỷ hẹn giờ');
        case _Action.unpublish:
          final ok = await _confirm(
            title: 'Gỡ "${d.title}"?',
            body: 'Người dùng sẽ không thấy tài liệu này nữa. Tiến độ đã học vẫn được giữ.',
            ok: 'Gỡ tài liệu',
          );
          if (ok) await repo.unpublish(d.id);
        case _Action.restore:
          await repo.restore(d.id);
          _snack('Đã khôi phục về nháp');
        case _Action.delete:
          final ok = await _confirm(title: 'Xoá bản nháp "${d.title}"?', body: 'Thao tác không hoàn tác được sau 8 giây.', ok: 'Xoá');
          if (!ok) return;
          await repo.delete(d.id);
          _snack('Đã xoá', action: SnackBarAction(label: 'Hoàn tác', onPressed: () => repo.undoDelete(d).catchError((Object e) => _snack('$e'))));
      }
    } on RepoException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<int?> _pickWeek() => showDialog<int>(
        context: context,
        builder: (ctx) => SimpleDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Nhân bản sang tuần', style: AppText.heading),
          children: [
            for (final w in repo.weeks)
              SimpleDialogOption(onPressed: () => Navigator.pop(ctx, w.number), child: Text('Tuần ${w.number} · ${w.rangeLabel}', style: AppText.body)),
          ],
        ),
      );

  List<_Action> _actionsFor(DocRecord d) => [
        if (d.status != DocStatus.archived) _Action.edit,
        _Action.preview,
        _Action.duplicate,
        _Action.export,
        if (d.status == DocStatus.scheduled) _Action.unschedule,
        if (d.status == DocStatus.published) _Action.unpublish,
        if (d.status == DocStatus.archived) _Action.restore,
        if (d.status == DocStatus.draft && !d.everPublished) _Action.delete,
      ];

  static const _actionLabels = {
    _Action.edit: 'Sửa',
    _Action.preview: 'Xem trước',
    _Action.duplicate: 'Nhân bản',
    _Action.export: 'Tải JSON',
    _Action.unschedule: 'Huỷ hẹn giờ',
    _Action.unpublish: 'Gỡ',
    _Action.restore: 'Khôi phục',
    _Action.delete: 'Xoá',
  };

  @override
  Widget build(BuildContext context) {
    final docs = repo.adminDocs(week: _week, statuses: _statuses, query: _query);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.xxxl),
          children: [
            Row(
              children: [
                const Expanded(child: Text('Tài liệu theo tuần', style: AppText.title)),
                FilledButton.icon(onPressed: () => _openCreator(), icon: const Icon(Icons.add_rounded), label: const Text('Tạo tài liệu')),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _weekDropdown(),
                for (final s in DocStatus.values)
                  FilterChip(
                    label: Text(s.label),
                    selected: _statuses.contains(s),
                    onSelected: (v) => setState(() => v ? _statuses.add(s) : _statuses.remove(s)),
                    selectedColor: AppColors.primary,
                    checkmarkColor: AppColors.onPrimary,
                    labelStyle: TextStyle(color: _statuses.contains(s) ? AppColors.onPrimary : AppColors.text, fontWeight: FontWeight.w700, fontSize: 13),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.borderStrong),
                    shape: const StadiumBorder(),
                  ),
                SizedBox(
                  width: 240,
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded, size: 20), hintText: 'Tìm theo tiêu đề'),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            if (_error != null)
              EmptyState(isError: true, message: _error!, actionLabel: 'Thử lại', onAction: _reload)
            else if (_loading && docs.isEmpty)
              const Padding(padding: EdgeInsets.all(AppSpace.xxxl), child: Center(child: CircularProgressIndicator()))
            else if (docs.isEmpty)
              EmptyState(message: 'Tuần này chưa có tài liệu', actionLabel: 'Tạo tài liệu', onAction: () => _openCreator())
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _headerRow(),
                    for (final d in docs) _row(d),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _weekDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.borderStrong)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _week,
          borderRadius: BorderRadius.circular(AppRadius.md),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Tất cả tuần')),
            for (final w in repo.weeks) DropdownMenuItem<int?>(value: w.number, child: Text('Tuần ${w.number}')),
          ],
          onChanged: (v) => setState(() => _week = v),
        ),
      ),
    );
  }

  static const _cols = [56.0, 0.0, 110.0, 80.0, 200.0, 150.0, 48.0]; // 0 = co giãn

  Widget _cells(List<Widget> cells) => Row(
        children: [
          for (var i = 0; i < cells.length; i++) _cols[i] == 0 ? Expanded(child: cells[i]) : SizedBox(width: _cols[i], child: cells[i]),
        ],
      );

  Widget _headerRow() => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: _cells(const [
          Text('Tuần', style: AppText.eyebrow),
          Text('Tiêu đề', style: AppText.eyebrow),
          Text('Kỹ năng', style: AppText.eyebrow),
          Text('Kiểu', style: AppText.eyebrow),
          Text('Trạng thái', style: AppText.eyebrow),
          Text('Cập nhật', style: AppText.eyebrow),
          SizedBox.shrink(),
        ]),
      );

  Widget _row(DocRecord d) {
    final doc = d.doc;
    final at = d.publishAt;
    final suffix = d.status == DocStatus.scheduled && at != null ? '${at.day}/${at.month} ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}' : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: AppColors.hover,
        onTap: d.status == DocStatus.archived ? null : () => _openCreator(docId: d.id),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: _cells([
            Text('${d.week}·${d.order}', style: AppText.label.copyWith(color: AppColors.textMuted)),
            Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(fontSize: 14)),
            Text(skillLabels[doc.meta.skill] ?? doc.meta.skill, style: AppText.caption),
            Text(doc.isHtml ? 'HTML' : (doc.meta.defaultView == DocViewMode.slide ? 'Slide' : 'Doc'), style: AppText.caption),
            Align(alignment: Alignment.centerLeft, child: StatusBadge(status: d.status, suffix: suffix)),
            Text('${d.updatedAt.hour.toString().padLeft(2, '0')}:${d.updatedAt.minute.toString().padLeft(2, '0')} · ${d.updatedBy}', style: AppText.caption),
            PopupMenuButton<_Action>(
              tooltip: 'Thao tác',
              icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
              color: AppColors.surface,
              onSelected: (a) => _onAction(d, a),
              itemBuilder: (_) => [
                for (final a in _actionsFor(d))
                  PopupMenuItem(value: a, child: Text(_actionLabels[a]!, style: TextStyle(color: a == _Action.delete || a == _Action.unpublish ? AppColors.primary : AppColors.text))),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
