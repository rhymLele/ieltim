// example_usage.dart — ví dụ ghép 3 phần vào app IELTS Hub (có thể xoá file này).

import 'package:flutter/material.dart';

import 'dragon_loader.dart';
import 'fx_common.dart';
import 'vu_mon_progress.dart';
import 'your_pond_card.dart';

/// Màn loading: tải dữ liệu thật, xong thì cá hóa rồng rồi vào Home.
class BootScreen extends StatefulWidget {
  const BootScreen({super.key});
  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Thay bằng các bước tải thật của bạn.
    for (final step in [0.2, 0.5, 0.8, 1.0]) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _progress = step);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DragonLoader(
          progress: _progress,
          onFinished: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const HomeShell()),
          ),
        ),
      ),
    );
  }
}

/// Home: sidebar có thác Vũ Môn + card "Ao của bạn".
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FxColors.background,
      body: Row(
        children: [
          Container(
            width: 240,
            color: FxColors.sidebar,
            child: Column(
              children: [
                const SizedBox(height: 72), // logo + menu của bạn ở đây
                // ... NavigationItems ...
                Expanded(
                  child: LayoutBuilder(builder: (context, c) {
                    if (c.maxHeight < 280) return const SizedBox.shrink();
                    return const Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: VuMonProgress(completed: 3, total: 5),
                      ),
                    );
                  }),
                ),
                // ... khối User / Logout ...
              ],
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ... tiêu đề + 3 card của bạn ...
                  SizedBox(height: 22),
                  Expanded(child: YourPondCard(streakDays: 5, savedWords: 128)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
