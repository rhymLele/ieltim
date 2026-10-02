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
import 'package:frontend/features/weekly_docs/presentation/views/weeks_screen.dart';
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
import 'package:frontend/features/weekly_docs/presentation/views/admin/admin_week_docs_screen.dart';

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
    builder: (_) => const WeeksScreen(),
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
  TabPage(
    label: 'Tài liệu tuần',
    icon: Icons.menu_book,
    builder: (_) => const AdminWeekDocsScreen(),
    adminOnly: true,
    route: '/admin/weekly-docs',
  ),
];

const _mobileBreakpoint = 840.0;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;

        if (isMobile) {
          return _MobileLayout(
            activeIndex: _activeIndex,
            role: _role,
            tabs: _visibleTabs,
            onTabSelected: (index) => setState(() => _activeIndex = index),
            onLogout: _logout,
          );
        }

        final isTablet = constraints.maxWidth < 1024;
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
                  onTabSelected: (index) =>
                      setState(() => _activeIndex = index),
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
      },
    );
  }

  void _logout() async {
    await TokenStorage().clear();
    if (mounted) context.go('/access');
  }
}

// ─── Shared NavPanel ─────────────────────────────────────────────────────────

class NavPanel extends StatefulWidget {
  const NavPanel({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.inDrawer,
    required this.onTabSelected,
  });

  final List<TabPage> tabs;
  final int activeIndex;
  final bool inDrawer;
  final ValueChanged<int> onTabSelected;

  @override
  State<NavPanel> createState() => _NavPanelState();
}

class _NavPanelState extends State<NavPanel> {
  static const _itemHeight = 44.0;
  static const _labelHeight = 32.0;
  static const _indicatorColor = Color(0xFFE7C9BC);

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    // Tab của user trước, rồi nhãn "Admin" và các tab admin (chỉ có khi
    // tài khoản là admin). Index vẫn là vị trí trong [widget.tabs].
    final userTabs = widget.tabs.where((t) => !t.adminOnly).toList();
    final adminTabs = widget.tabs.where((t) => t.adminOnly).toList();
    final hasAdmin = adminTabs.isNotEmpty;
    final rows = [...userTabs, ...adminTabs];
    double rowTop(int row) => row < userTabs.length
        ? row * _itemHeight
        : row * _itemHeight + _labelHeight;
    final activeRow = widget.activeIndex < widget.tabs.length
        ? rows.indexOf(widget.tabs[widget.activeIndex])
        : -1;

    Widget item(TabPage tab) {
      final index = widget.tabs.indexOf(tab);
      final isActive = index == widget.activeIndex;
      return SizedBox(
        height: _itemHeight,
        child: InkWell(
          onTap: () => widget.onTabSelected(index),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.inDrawer ? 24 : 20,
            ),
            child: Row(
              children: [
                Icon(
                  tab.icon,
                  size: 18,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tab.label,
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
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.inDrawer)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: _SectionLabel('Knowledge'),
          ),
        SizedBox(
          height: rows.length * _itemHeight + (hasAdmin ? _labelHeight : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (activeRow >= 0)
                AnimatedPositioned(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  top: rowTop(activeRow),
                  left: widget.inDrawer ? 12 : 8,
                  right: widget.inDrawer ? 12 : 8,
                  height: _itemHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _indicatorColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...userTabs.map(item),
                  if (hasAdmin)
                    SizedBox(
                      height: _labelHeight,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            widget.inDrawer ? 24 : 16,
                            0,
                            16,
                            6,
                          ),
                          child: const _SectionLabel('Admin'),
                        ),
                      ),
                    ),
                  ...adminTabs.map(item),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Desktop Sidebar ─────────────────────────────────────────────────────────

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
              children: [
                Image.asset('assets/images/logo_horizontal.png', height: 30),
              ],
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: VuMonProgress(
                          repeat: true,
                          background: AppColors.surface,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: NavPanel(
                          tabs: tabs,
                          activeIndex: activeIndex,
                          inDrawer: false,
                          onTabSelected: onTabSelected,
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

// ─── Mobile Layout ───────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final int activeIndex;
  final String? role;
  final List<TabPage> tabs;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onLogout;

  const _MobileLayout({
    required this.activeIndex,
    required this.role,
    required this.tabs,
    required this.onTabSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final userName = role == 'ADMIN' ? 'Admin' : 'User';
    final avatarLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (context) => Tooltip(
            message: 'Menu',
            child: IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF2A1418)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        title: Row(
          children: [
            Image.asset('assets/images/logo_horizontal.png', height: 24),
          ],
        ),
        titleSpacing: 0,
        actions: [
          Tooltip(
            message: 'Tìm kiếm',
            child: IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF2A1418)),
              onPressed: () {
                final idx = tabs.indexWhere((t) => t.label == 'Search');
                if (idx >= 0) onTabSelected(idx);
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEFDCCB)),
        ),
      ),
      drawer: _MobileDrawer(
        tabs: tabs,
        activeIndex: activeIndex,
        role: role,
        userName: userName,
        avatarLetter: avatarLetter,
        onTabSelected: (index) {
          onTabSelected(index);
          Scaffold.of(context).closeDrawer();
        },
        onLogout: onLogout,
      ),
      body: IndexedStack(
        index: activeIndex,
        children: tabs.map((tab) => tab.builder(context)).toList(),
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final List<TabPage> tabs;
  final int activeIndex;
  final String? role;
  final String userName;
  final String avatarLetter;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onLogout;

  const _MobileDrawer({
    required this.tabs,
    required this.activeIndex,
    required this.role,
    required this.userName,
    required this.avatarLetter,
    required this.onTabSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF3E5D5),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final drawerHeight = constraints.maxHeight;
            final showVuMon = drawerHeight >= 560;
            return Column(
              children: [
                // Header: logo + close
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                  child: Row(
                    children: [
                      Image.asset('assets/images/app_logo.png', height: 28),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF2A1418)),
                        tooltip: 'Đóng menu',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // User info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF800020),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          avatarLetter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2A1418),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '0 ngày liên tiếp',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B4A4F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Menu items
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: NavPanel(
                      tabs: tabs,
                      activeIndex: activeIndex,
                      inDrawer: true,
                      onTabSelected: onTabSelected,
                    ),
                  ),
                ),
                // VuMonProgress - hide if not enough space
                if (showVuMon)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: VuMonProgress(
                      repeat: true,
                      background: const Color(0xFFF3E5D5),
                    ),
                  ),
                // Logout
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onLogout,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout,
                            size: 18,
                            color: Color(0xFF6B4A4F),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Đăng xuất',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B4A4F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
