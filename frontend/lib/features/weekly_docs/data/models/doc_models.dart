import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/admin_doc.dart';
import '../../domain/entities/doc_json.dart';
import '../../domain/entities/doc_progress.dart';
import '../../domain/entities/doc_status.dart';
import '../../domain/entities/doc_summary.dart';
import '../../domain/entities/learner_doc.dart';
import '../../domain/entities/weekly_doc.dart';
import 'doc_json_converter.dart';

part 'doc_models.g.dart';

/// Lựa chọn trắc nghiệm đã lưu.
@JsonSerializable(createToJson: false)
class QuizAnswerModel {
  const QuizAnswerModel({required this.option, required this.firstCorrect});

  factory QuizAnswerModel.fromJson(Map<String, dynamic> json) => _$QuizAnswerModelFromJson(json);

  final int option;
  @JsonKey(defaultValue: false)
  final bool firstCorrect;
}

/// Tiến độ của tôi (`progress` trong danh sách tuần / chi tiết tài liệu, response của PUT progress).
@JsonSerializable(createToJson: false)
class ProgressModel {
  const ProgressModel({
    required this.lastSection,
    required this.seenSections,
    required this.completed,
    required this.quizAnswers,
    this.viewMode,
    this.completedAt,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) => _$ProgressModelFromJson(json);

  @JsonKey(defaultValue: 0)
  final int lastSection;
  @JsonKey(defaultValue: <int>[])
  final List<int> seenSections;
  @JsonKey(defaultValue: false)
  final bool completed;
  @JsonKey(defaultValue: <String, QuizAnswerModel>{})
  final Map<String, QuizAnswerModel> quizAnswers;
  final String? viewMode;
  final DateTime? completedAt;

  DocProgress toEntity() => DocProgress(
        seenSections: seenSections.toSet(),
        lastSection: lastSection,
        completed: completed,
        completedAt: completedAt?.toLocal(),
        answers: {for (final e in quizAnswers.entries) e.key: e.value.option},
        lastView: viewMode == null ? null : DocViewMode.parse(viewMode),
      );
}

/// Một tài liệu từ API: danh sách (không có `content`) hoặc chi tiết (có `content`, người học có `progress`).
@JsonSerializable(createToJson: false)
class DocModel {
  const DocModel({
    required this.id,
    required this.week,
    required this.order,
    required this.category,
    required this.title,
    required this.skill,
    required this.template,
    required this.defaultView,
    required this.allowedViews,
    required this.sectionCount,
    required this.estimatedMinutes,
    required this.version,
    required this.hasRevisionDraft,
    required this.htmlSize,
    this.status,
    this.publishAt,
    this.publishedAt,
    this.updatedAt,
    this.updatedBy,
    this.htmlFileName,
    this.progress,
    this.content,
  });

  factory DocModel.fromJson(Map<String, dynamic> json) => _$DocModelFromJson(json);

  final String id;
  final int week;
  final int order;

  /// `lesson` | `homework`; BE cũ không trả thì coi như tài liệu thường.
  @JsonKey(defaultValue: 'lesson')
  final String category;
  final String title;
  final String skill;
  final String template;
  final String defaultView;
  final List<String> allowedViews;
  final int sectionCount;
  final int estimatedMinutes;
  final int version;
  @JsonKey(defaultValue: false)
  final bool hasRevisionDraft;
  @JsonKey(defaultValue: 0)
  final int htmlSize;

  /// Chỉ API admin trả; API người học chỉ có tài liệu đã xuất bản.
  final String? status;
  final DateTime? publishAt;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final String? updatedBy;
  final String? htmlFileName;
  final ProgressModel? progress;
  @DocJsonConverter()
  final DocJson? content;

  DocSummary toSummary() => DocSummary(
        id: id,
        week: week,
        order: order,
        category: DocCategory.parse(category),
        title: title,
        skill: skill,
        template: template,
        defaultView: DocViewMode.parse(defaultView),
        allowedViews: [for (final v in allowedViews) DocViewMode.parse(v)],
        sectionCount: sectionCount,
        estimatedMinutes: estimatedMinutes,
        version: version,
        status: status == null ? DocStatus.published : DocStatus.parse(status),
        publishAt: publishAt?.toLocal(),
        publishedAt: publishedAt?.toLocal(),
        updatedAt: updatedAt?.toLocal(),
        updatedBy: updatedBy ?? '',
        hasRevisionDraft: hasRevisionDraft,
        htmlFileName: htmlFileName,
        htmlSize: htmlSize,
      );

  DocProgress get _progress => progress?.toEntity() ?? const DocProgress();

  /// Chi tiết admin: API luôn trả `content`; thiếu thì coi như tài liệu rỗng.
  AdminDoc toAdminDoc() => AdminDoc(summary: toSummary(), content: content ?? const DocJson({}));

  LearnerDoc toLearnerDoc() => LearnerDoc(
        summary: toSummary(),
        doc: (content ?? const DocJson({})).toDoc(),
        progress: _progress,
      );

  WeekDocEntry toWeekEntry() => WeekDocEntry(summary: toSummary(), progress: _progress);
}

/// `GET /admin/weekly/documents`.
@JsonSerializable(createToJson: false)
class DocPageModel {
  const DocPageModel({required this.data});

  factory DocPageModel.fromJson(Map<String, dynamic> json) => _$DocPageModelFromJson(json);

  final List<DocModel> data;
}

/// Dữ liệu kèm lỗi 409 `DOC_VERSION_CONFLICT`.
@JsonSerializable(createToJson: false)
class VersionConflictModel {
  const VersionConflictModel({required this.current});

  factory VersionConflictModel.fromJson(Map<String, dynamic> json) => _$VersionConflictModelFromJson(json);

  final DocModel current;
}
