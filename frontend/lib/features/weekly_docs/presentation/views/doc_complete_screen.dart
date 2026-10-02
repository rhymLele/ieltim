import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../../../core/widgets/vu_mon_progress.dart';
import '../../data/fake_weekly_docs_repository.dart';
import '../../data/weekly_docs_repository.dart';
import '../doc_theme.dart';

/// Màn chúc mừng khi hoàn thành tài liệu: cá chép vượt vũ môn,
/// progress tuần, nút quay lại danh sách.
class DocCompleteScreen extends StatefulWidget {
  const DocCompleteScreen({
    super.key,
    required this.docId,
    required this.week,
  });

  final String docId;
  final int week;

  @override
  State<DocCompleteScreen> createState() => _DocCompleteScreenState();
}

class _DocCompleteScreenState extends State<DocCompleteScreen> {
  final _repo = FakeWeeklyDocsRepository();
  WeekProgress? _progress;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final p = await _repo.getWeekProgress(widget.week);
    if (mounted) setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final completed = _progress?.completed ?? 0;
    final total = _progress?.total ?? 1;
    final weekDone = completed >= total && total > 0;

    return Scaffold(
      backgroundColor: Brand.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 24 : 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Checkmark animation
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Brand.success,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Đã hoàn thành!',
                  style: DocFonts.title(size: isMobile ? 24 : 32),
                ),
                const SizedBox(height: 8),
                Text(
                  weekDone
                      ? 'Cá chép đã vượt vũ môn tuần này!'
                      : 'Cá chép đang leo thác, tiếp tục nhé!',
                  textAlign: TextAlign.center,
                  style: DocFonts.body(size: isMobile ? 14 : 16)
                      .copyWith(color: Brand.textSecondary),
                ),
                const SizedBox(height: 32),
                // VuMonProgress: play once if week just completed, otherwise show state
                SizedBox(
                  width: isMobile ? 160 : 200,
                  child: VuMonProgress(
                    playOnce: weekDone,
                    completed: completed,
                    total: total,
                    background: Brand.background,
                  ),
                ),
                const SizedBox(height: 40),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Brand.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.go('/weekly'),
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text(
                        'Về danh sách',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
