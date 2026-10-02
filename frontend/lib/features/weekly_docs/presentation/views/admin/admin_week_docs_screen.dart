import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../../../core/widgets/dragon_loader.dart';
import '../../../domain/models/weekly_doc.dart';
import '../../bloc/admin_week_docs_bloc.dart';
import '../../doc_theme.dart';

/// Màn A1: danh sách tài liệu admin với bộ lọc, search, menu ⋯.
class AdminWeekDocsScreen extends StatelessWidget {
  const AdminWeekDocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminWeekDocsBloc(
        repo: FakeWeeklyDocsRepository(),
      )..add(const LoadAdminDocs()),
      child: const _AdminWeekDocsBody(),
    );
  }
}

class _AdminWeekDocsBody extends StatefulWidget {
  const _AdminWeekDocsBody();

  @override
  State<_AdminWeekDocsBody> createState() => _AdminWeekDocsBodyState();
}

class _AdminWeekDocsBodyState extends State<_AdminWeekDocsBody> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<AdminWeekDocsBloc>().add(SetSearch(query: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final pad = isMobile ? 16.0 : 32.0;

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quản lý tài liệu theo tuần',
                  style: DocFonts.title(size: isMobile ? 20 : 26),
                ),
              ),
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Brand.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => context.push('/admin/weekly-docs/create'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tạo tài liệu'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filters
          BlocBuilder<AdminWeekDocsBloc, AdminWeekDocsState>(
            builder: (context, state) {
              return Row(
                children: [
                  // Week filter
                  Expanded(
                    flex: 2,
                    child: _FilterDropdown<int?>(
                      label: 'Tuần',
                      value: state.filterWeek,
                      items: [
                        (null, 'Tất cả tuần'),
                        ...state.weeks.map((w) => (w, 'Tuần $w')),
                      ],
                      onChanged: (v) => context
                          .read<AdminWeekDocsBloc>()
                          .add(SetWeekFilter(week: v)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Status filter
                  Expanded(
                    flex: 2,
                    child: _FilterDropdown<DocStatus?>(
                      label: 'Trạng thái',
                      value: state.filterStatus,
                      items: const [
                        (null, 'Tất cả'),
                        (DocStatus.draft, 'Draft'),
                        (DocStatus.published, 'Published'),
                        (DocStatus.archived, 'Archived'),
                      ],
                      onChanged: (v) => context
                          .read<AdminWeekDocsBloc>()
                          .add(SetStatusFilter(status: v)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Skill filter
                  Expanded(
                    flex: 2,
                    child: _FilterDropdown<String?>(
                      label: 'Kỹ năng',
                      value: state.filterSkill,
                      items: const [
                        (null, 'Tất cả'),
                        ('Reading', 'Reading'),
                        ('Listening', 'Listening'),
                        ('Writing', 'Writing'),
                        ('Speaking', 'Speaking'),
                        ('Vocabulary', 'Vocabulary'),
                      ],
                      onChanged: (v) => context
                          .read<AdminWeekDocsBloc>()
                          .add(SetSkillFilter(skill: v)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Search
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tiêu đề…',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Brand.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Brand.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Brand.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Table / List
          Expanded(
            child: BlocBuilder<AdminWeekDocsBloc, AdminWeekDocsState>(
              builder: (context, state) {
                if (state.loading && state.docs.isEmpty) {
                  return const Center(child: DragonLoader());
                }
                if (state.error != null && state.docs.isEmpty) {
                  return Center(
                    child: Text(state.error!,
                        style: DocFonts.body().copyWith(color: Brand.error)),
                  );
                }
                if (state.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: Brand.textSecondary),
                        const SizedBox(height: 12),
                        Text('Chưa có tài liệu',
                            style: DocFonts.body(size: 15)
                                .copyWith(color: Brand.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: state.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _DocRow(
                    doc: state.docs[i],
                    onEdit: () =>
                        context.push('/admin/weekly-docs/${state.docs[i].id}/edit'),
                    onMenu: (ctx, doc) => _showDocMenu(ctx, doc, isMobile),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDocMenu(BuildContext overlayCtx, WeeklyDoc doc, bool isMobile) {
    final bloc = context.read<AdminWeekDocsBloc>();
    final status = doc.meta.status;

    void snackbar(String msg) {
      ScaffoldMessenger.of(overlayCtx).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }

    showMenu(
      context: overlayCtx,
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      items: [
        if (status == DocStatus.draft || status == DocStatus.published)
          PopupMenuItem(
            child: const Text('Sửa'),
            onTap: () =>
                context.push('/admin/weekly-docs/${doc.id}/edit'),
          ),
        if (status == DocStatus.draft)
          PopupMenuItem(
            child: const Text('Xuất bản'),
            onTap: () {
              bloc.add(PublishDocEvent(docId: doc.id));
              snackbar('Đã xuất bản');
            },
          ),
        if (status == DocStatus.published)
          PopupMenuItem(
            child: const Text('Gỡ (Unpublish)'),
            onTap: () {
              bloc.add(UnpublishDocEvent(docId: doc.id));
              snackbar('Đã gỡ');
            },
          ),
        if (status == DocStatus.archived)
          PopupMenuItem(
            child: const Text('Khôi phục'),
            onTap: () {
              bloc.add(RestoreDocEvent(docId: doc.id));
              snackbar('Đã khôi phục');
            },
          ),
        PopupMenuItem(
          child: const Text('Nhân bản'),
          onTap: () {
            bloc.add(DuplicateDocEvent(docId: doc.id));
            snackbar('Đã nhân bản');
          },
        ),
        PopupMenuItem(
          child: const Text('Export JSON'),
          onTap: () {
            final json = FakeWeeklyDocsRepository().exportJson(doc);
            Clipboard.setData(ClipboardData(text: json));
            snackbar('Đã copy JSON vào clipboard');
          },
        ),
        if (status == DocStatus.draft)
          PopupMenuItem(
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: overlayCtx,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xoá tài liệu'),
                  content: Text(
                      'Xoá bản nháp "${doc.meta.title}"? Thao tác không hoàn tác được.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Huỷ'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(ctx);
                        bloc.add(DeleteDocEvent(docId: doc.id));
                      },
                      child: const Text('Xoá'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

// ─── Row ─────────────────────────────────────────────────────────────────────

class _DocRow extends StatelessWidget {
  final WeeklyDoc doc;
  final VoidCallback onEdit;
  final void Function(BuildContext, WeeklyDoc) onMenu;

  const _DocRow({
    required this.doc,
    required this.onEdit,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final meta = doc.meta;

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 4 : 8,
          vertical: isMobile ? 10 : 12,
        ),
        child: Row(
          children: [
            // Order
            SizedBox(
              width: 32,
              child: Text(
                '${meta.order}',
                style: DocFonts.body(size: 13, weight: FontWeight.w700)
                    .copyWith(color: Brand.textSecondary),
              ),
            ),
            // Title + skill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DocFonts.body(size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tuần ${meta.week} · ${meta.skill ?? '—'} · ${meta.defaultView.name}',
                    style: DocFonts.body(size: 11)
                        .copyWith(color: Brand.textSecondary),
                  ),
                ],
              ),
            ),
            // Status badge
            _StatusBadge(status: meta.status),
            const SizedBox(width: 8),
            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (_) {},
              itemBuilder: (ctx) => [
                for (final item in _menuItems(doc.meta.status))
                  PopupMenuItem(
                    key: ValueKey(item),
                    value: item,
                    child: Text(item),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _menuItems(DocStatus status) {
    final items = <String>[];
    if (status == DocStatus.draft) {
      items.addAll(['Sửa', 'Xuất bản', 'Nhân bản', 'Export JSON', 'Xoá']);
    } else if (status == DocStatus.published) {
      items.addAll(['Sửa', 'Gỡ', 'Nhân bản', 'Export JSON']);
    } else {
      items.addAll(['Khôi phục', 'Nhân bản', 'Export JSON']);
    }
    return items;
  }
}

// ─── Status Badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final DocStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      DocStatus.draft => ('Draft', const Color(0xFFEDE6DE), Brand.textSecondary),
      DocStatus.published => ('Published', const Color(0xFFE8F5E9), const Color(0xFF2F7A4B)),
      DocStatus.archived => ('Archived', const Color(0xFFFDE8E8), const Color(0xFF800020)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ─── Filter Dropdown ─────────────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<(T?, String)> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      value: value,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Brand.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Brand.primary),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem<T?>(value: e.$1, child: Text(e.$2)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
