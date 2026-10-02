import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../../../core/widgets/dragon_loader.dart';
import '../../data/fake_weekly_docs_repository.dart';
import '../../data/weekly_docs_repository.dart';
import '../doc_theme.dart';

/// Màn danh sách tuần: mỗi tuần là một thẻ có progress, tap mở tuần đầu tiên
/// (hoặc vào DocReader).
class WeeksScreen extends StatefulWidget {
  const WeeksScreen({super.key});

  @override
  State<WeeksScreen> createState() => _WeeksScreenState();
}

class _WeeksScreenState extends State<WeeksScreen> {
  final _repo = FakeWeeklyDocsRepository();
  bool _loading = true;
  List<int> _weeks = [];
  Map<int, WeekProgress> _progress = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final weeks = await _repo.getWeeks();
      final progressMap = <int, WeekProgress>{};
      for (final w in weeks) {
        progressMap[w] = await _repo.getWeekProgress(w);
      }
      if (mounted) {
        setState(() {
          _weeks = weeks;
          _progress = progressMap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải dữ liệu: $e';
          _loading = false;
        });
      }
    }
  }

  void _openWeek(int week) async {
    final docs = await _repo.getDocsForWeek(week);
    if (docs.isEmpty || !mounted) return;
    context.push('/weekly/doc/${docs.first.id}');
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
          Text(
            'Tài liệu theo tuần',
            style: DocFonts.title(size: isMobile ? 22 : 28),
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn tuần để bắt đầu học',
            style: DocFonts.body(size: isMobile ? 13 : 14)
                .copyWith(color: Brand.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Expanded(child: Center(child: DragonLoader()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(
                  _error!,
                  style: DocFonts.body().copyWith(color: Brand.error),
                ),
              ),
            )
          else if (_weeks.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Brand.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có tài liệu',
                      style: DocFonts.body(size: 15).copyWith(color: Brand.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _weeks.length,
                itemBuilder: (context, i) => _WeekCard(
                  week: _weeks[i],
                  progress: _progress[_weeks[i]],
                  onTap: () => _openWeek(_weeks[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final int week;
  final WeekProgress? progress;
  final VoidCallback onTap;

  const _WeekCard({
    required this.week,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = progress?.completed ?? 0;
    final total = progress?.total ?? 0;
    final isComplete = total > 0 && done >= total;
    final progressFrac = total > 0 ? done / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete ? Brand.gold : Brand.border,
          width: isComplete ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? Brand.gold.withOpacity(0.15)
                        : Brand.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$week',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isComplete ? Brand.goldDark : Brand.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tuần $week',
                        style: DocFonts.title(size: 16),
                      ),
                      const SizedBox(height: 4),
                      if (total > 0) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressFrac,
                            minHeight: 6,
                            backgroundColor: Brand.border,
                            valueColor: AlwaysStoppedAnimation(
                              isComplete ? Brand.gold : Brand.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$done / $total tài liệu',
                          style: DocFonts.body(size: 12)
                              .copyWith(color: Brand.textSecondary),
                        ),
                      ] else
                        Text(
                          'Đang chuẩn bị…',
                          style: DocFonts.body(size: 12)
                              .copyWith(color: Brand.textSecondary),
                        ),
                    ],
                  ),
                ),
                Icon(
                  isComplete ? Icons.check_circle : Icons.chevron_right,
                  color: isComplete ? Brand.gold : Brand.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
