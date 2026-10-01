import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/widgets/grid_background.dart';
import 'package:frontend/core/widgets/vu_mon_progress.dart';
import 'package:frontend/features/home/presentation/views/home_page.dart';
import 'package:frontend/features/documents/presentation/bloc/weekly_documents_bloc.dart';
import 'package:frontend/features/documents/presentation/views/weekly_documents_page.dart';
import 'package:frontend/features/search/presentation/bloc/search_bloc.dart';
import 'package:frontend/features/search/presentation/views/search_page.dart';
import 'package:frontend/features/wordbook/presentation/bloc/wordbook_bloc.dart';
import 'package:frontend/features/wordbook/presentation/views/wordbook_page.dart';
import 'package:frontend/features/web_resources/presentation/bloc/web_resources_bloc.dart';
import 'package:frontend/features/web_resources/presentation/views/web_resources_page.dart';
import 'package:frontend/features/admin/documents/presentation/bloc/admin_documents_bloc.dart';
import 'package:frontend/features/admin/documents/presentation/views/admin_documents_page.dart';
import 'package:frontend/features/admin/vocabularies/presentation/views/admin_vocabularies_page.dart';
import 'package:frontend/features/admin/sentence_patterns/presentation/views/admin_sentence_patterns_page.dart';
import 'package:frontend/features/admin/tags/presentation/views/admin_tags_page.dart';
import 'package:frontend/features/admin/access_keys/presentation/views/admin_access_keys_page.dart';

class TabPage {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  final bool adminOnly;
  final String? route;

  const TabPage({
    required this.label,
    required this.icon,
    required this.builder,
    this.adminOnly = false,
    this.route,
  });
}

List<TabPage> get allTabs => [
  TabPage(
    label: 'Home',
    icon: Icons.home,
    builder: (_) => const HomePage(),
    route: '/home',
  ),
  TabPage(
    label: 'Tài liệu web',
    icon: Icons.description,
    builder: (_) => BlocProvider(
      create: (_) => WebResourcesBloc()..add(LoadResources()),
      child: const WebResourcesPage(),
    ),
    route: '/resources',
  ),
  TabPage(
    label: 'Theo tuần',
    icon: Icons.calendar_month,
    builder: (_) => BlocProvider(
      create: (_) => WeeklyDocumentsBloc()..add(LoadDocuments(week: 1)),
      child: const WeeklyDocumentsPage(),
    ),
    route: '/weekly',
  ),
  TabPage(
    label: 'Sổ từ',
    icon: Icons.book_outlined,
    builder: (_) => BlocProvider(
      create: (_) => WordbookBloc()..add(LoadWordbook()),
      child: const WordbookPage(),
    ),
    route: '/wordbook',
  ),
  TabPage(
    label: 'Search',
    icon: Icons.search,
    builder: (_) =>
        BlocProvider(create: (_) => SearchBloc(), child: const SearchPage()),
    route: '/search',
  ),
  TabPage(
    label: 'Quản lý tài liệu',
    icon: Icons.edit_note,
    builder: (_) => BlocProvider(
      create: (_) => AdminDocumentsBloc()..add(LoadAdminDocuments()),
      child: const AdminDocumentsPage(),
    ),
    adminOnly: true,
    route: '/admin',
  ),
  TabPage(
    label: 'Từ vựng',
    icon: Icons.translate,
    builder: (_) => const AdminVocabulariesPage(),
    adminOnly: true,
    route: '/admin/vocabularies',
  ),
  TabPage(
    label: 'Cấu trúc câu',
    icon: Icons.format_quote,
    builder: (_) => const AdminSentencePatternsPage(),
    adminOnly: true,
    route: '/admin/sentence-patterns',
  ),
  TabPage(
    label: 'Tags',
    icon: Icons.local_offer,
    builder: (_) => const AdminTagsPage(),
    adminOnly: true,
    route: '/admin/tags',
  ),
  TabPage(
    label: 'Access Keys',
    icon: Icons.vpn_key,
    builder: (_) => const AdminAccessKeysPage(),
    adminOnly: true,
    route: '/admin/access-keys',
  ),
];

class AppLayout extends StatefulWidget {
  final Widget? child;

  const AppLayout({super.key, this.child});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  String? _role;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await TokenStorage().getRole();
    if (mounted) setState(() => _role = role);
  }

  List<TabPage> get _visibleTabs =>
      _role == 'ADMIN' ? allTabs : allTabs.where((t) => !t.adminOnly).toList();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return _MobileLayout(activeIndex: _activeIndex, role: _role);
    }

    final isTablet = MediaQuery.of(context).size.width < 1024;
    final sidebarWidth = isTablet ? 200.0 : 240.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: _Sidebar(
              tabs: _visibleTabs,
              activeIndex: _activeIndex,
              role: _role,
              onTabSelected: (index) => setState(() => _activeIndex = index),
              onLogout: _logout,
            ),
          ),
          Expanded(
            child: GridBackgroundContainer(
              child: _visibleTabs[_activeIndex].builder(context),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await TokenStorage().clear();
    if (mounted) context.go('/access');
  }
}

class _Sidebar extends StatelessWidget {
  final List<TabPage> tabs;
  final int activeIndex;
  final String? role;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.tabs,
    required this.activeIndex,
    required this.role,
    required this.onTabSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [Image.asset('assets/images/app_logo.png', height: 30)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: const Divider(height: 1, color: AppColors.border),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: VuMonProgress(
                          // Lesson completion is not tracked yet, so the koi
                          // keeps climbing as decoration instead of showing
                          // fake counts.
                          repeat: true,
                          background: AppColors.surface,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel('Knowledge'),
                            ..._visibleUserTabs,
                            if (role == 'ADMIN') ...[
                              const _SectionLabel('Admin'),
                              ..._visibleAdminTabs,
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: const Divider(height: 1, color: AppColors.border),
          ),
          _UserSection(role: role, onLogout: onLogout),
        ],
      ),
    );
  }

  List<Widget> get _visibleUserTabs =>
      tabs.where((t) => !t.adminOnly).toList().asMap().entries.map((e) {
        return _TabItem(
          icon: e.value.icon,
          label: e.value.label,
          isActive: e.key == activeIndex,
          onTap: () => onTabSelected(e.key),
        );
      }).toList();

  List<Widget> get _visibleAdminTabs {
    final adminTabs = tabs.where((t) => t.adminOnly).toList();
    final userTabCount = tabs.where((t) => !t.adminOnly).length;
    return adminTabs.asMap().entries.map((e) {
      return _TabItem(
        icon: e.value.icon,
        label: e.value.label,
        isActive: (e.key + userTabCount) == activeIndex,
        onTap: () => onTabSelected(e.key + userTabCount),
      );
    }).toList();
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserSection extends StatelessWidget {
  final String? role;
  final VoidCallback onLogout;

  const _UserSection({required this.role, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role == 'ADMIN' ? 'Admin' : 'User',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            role ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onLogout,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final int activeIndex;
  final String? role;

  const _MobileLayout({required this.activeIndex, required this.role});

  @override
  Widget build(BuildContext context) {
    final visibleTabs = role == 'ADMIN'
        ? allTabs
        : allTabs.where((t) => !t.adminOnly).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/app_icon.png', width: 24, height: 24),
            const SizedBox(width: 8),
            const Text(
              'IELTS Hub',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            onSelected: (index) {
              final tab = visibleTabs[index];
              if (tab.route != null) {
                context.go(tab.route!);
              }
            },
            itemBuilder: (context) => visibleTabs.asMap().entries.map((e) {
              return PopupMenuItem(
                value: e.key,
                child: Row(
                  children: [
                    Icon(e.value.icon, size: 18),
                    const SizedBox(width: 8),
                    Text(e.value.label),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: IndexedStack(
        index: activeIndex,
        children: visibleTabs.map((tab) => tab.builder(context)).toList(),
      ),
    );
  }
}
