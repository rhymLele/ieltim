import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../../../core/widgets/dragon_loader.dart';
import '../../../bloc/doc_creator_bloc.dart';
import '../../../data/fake_weekly_docs_repository.dart';
import '../../doc_theme.dart';
import 'steps/step_metadata.dart';
import 'steps/step_content.dart';
import 'steps/step_publish.dart';

/// Màn A2: wizard 3 bước tạo/sửa tài liệu.
///
/// Bước 1: Metadata (title, week, order, skill, template)
/// Bước 2: Content (block editor theo section)
/// Bước 3: Publish (view mode, allowedViews, validation)
class DocCreatorScreen extends StatelessWidget {
  const DocCreatorScreen({super.key, this.docId, this.initialWeek});

  /// Nếu có `docId` → chế độ sửa. Nếu không → chế độ tạo mới.
  final String? docId;
  final int? initialWeek;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DocCreatorBloc(repo: FakeWeeklyDocsRepository())
        ..add(docId != null
            ? InitEdit(docId: docId!)
            : InitCreate(initialWeek: initialWeek)),
      child: const _CreatorBody(),
    );
  }
}

class _CreatorBody extends StatelessWidget {
  const _CreatorBody();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Brand.background,
      appBar: AppBar(
        backgroundColor: Brand.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Brand.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.select<DocCreatorBloc, bool>((s) => s.isNew)
              ? 'Tạo tài liệu'
              : 'Sửa tài liệu',
          style: DocFonts.title(size: 16),
        ),
        actions: [
          BlocBuilder<DocCreatorBloc, DocCreatorState>(
            builder: (context, state) {
              if (state.error != null)
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Brand.error, fontSize: 12),
                    ),
                  ),
                );
              if (state.publishResult != null)
                return const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '✓ Đã xuất bản',
                      style: TextStyle(
                          color: Brand.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<DocCreatorBloc, DocCreatorState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: DragonLoader());
          }
          if (state.doc == null) {
            return Center(
              child: Text(
                state.error ?? 'Không có dữ liệu',
                style: DocFonts.body().copyWith(color: Brand.textSecondary),
              ),
            );
          }

          return Column(
            children: [
              // Step indicator
              _StepIndicator(current: state.step),
              const Divider(height: 1, color: Brand.border),
              // Step content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  child: switch (state.step) {
                    1 => const StepMetadata(),
                    2 => const StepContent(),
                    _ => const StepPublish(),
                  },
                ),
              ),
              // Bottom bar
              _BottomBar(isMobile: isMobile),
            ],
          );
        },
      ),
    );
  }
}

// ─── Step Indicator ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  static const _labels = ['Thông tin', 'Nội dung', 'Xuất bản'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final step = i + 1;
          final isActive = step == current;
          final isDone = step < current;
          final color = isDone
              ? Brand.success
              : isActive
                  ? Brand.primary
                  : Brand.disabled;

          return Row(
            children: [
              if (i > 0)
                Container(
                  width: 40,
                  height: 2,
                  color: isDone || isActive ? Brand.primary : Brand.border,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
              GestureDetector(
                onTap: step < current
                    ? () => context
                        .read<DocCreatorBloc>()
                        .add(GoToStep(step: step))
                    : null,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive || isDone ? color : Brand.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isActive || isDone
                            ? color
                            : Brand.border,
                        width: 2),
                  ),
                  alignment: Alignment.center,
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$step',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive || isDone
                                ? Colors.white
                                : Brand.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                  color: isActive ? Brand.primary : Brand.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Bottom Bar ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool isMobile;
  const _BottomBar({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Brand.surface,
      padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 32, 12, isMobile ? 16 : 32, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back
          BlocBuilder<DocCreatorBloc, DocCreatorState>(
            builder: (context, state) {
              if (state.step == 1) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context
                    .read<DocCreatorBloc>()
                    .add(GoToStep(step: state.step - 1)),
                child: const Text('Quay lại'),
              );
            },
          ),
          // Next / Save / Publish
          BlocBuilder<DocCreatorBloc, DocCreatorState>(
            builder: (context, state) {
              if (state.step < 3) {
                return FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Brand.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: state.canGoNext
                      ? () {
                          if (state.step == 1) {
                            context
                                .read<DocCreatorBloc>()
                                .add(const SaveAndProceed());
                          } else {
                            context
                                .read<DocCreatorBloc>()
                                .add(GoToStep(step: state.step + 1));
                          }
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Tiếp tục'),
                );
              }
              // Step 3: publish
              final hasErrors = state.validations
                  .any((v) => v.level == IssueLevel.error);
              return FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: hasErrors
                      ? Brand.disabled
                      : Brand.success,
                  foregroundColor: Colors.white,
                ),
                onPressed: hasErrors
                    ? null
                    : () => context
                        .read<DocCreatorBloc>()
                        .add(const PublishDoc()),
                icon: const Icon(Icons.publish, size: 18),
                label: Text(
                    hasErrors ? 'Có lỗi' : 'Xuất bản',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              );
            },
          ),
        ],
      ),
    );
  }
}
