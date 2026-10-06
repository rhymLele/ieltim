// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doc_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizAnswerModel _$QuizAnswerModelFromJson(Map<String, dynamic> json) =>
    QuizAnswerModel(
      option: (json['option'] as num).toInt(),
      firstCorrect: json['firstCorrect'] as bool? ?? false,
    );

ProgressModel _$ProgressModelFromJson(Map<String, dynamic> json) =>
    ProgressModel(
      lastSection: (json['lastSection'] as num?)?.toInt() ?? 0,
      seenSections:
          (json['seenSections'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      completed: json['completed'] as bool? ?? false,
      quizAnswers:
          (json['quizAnswers'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              QuizAnswerModel.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          {},
      viewMode: json['viewMode'] as String?,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

DocModel _$DocModelFromJson(Map<String, dynamic> json) => DocModel(
  id: json['id'] as String,
  week: (json['week'] as num).toInt(),
  order: (json['order'] as num).toInt(),
  category: json['category'] as String? ?? 'lesson',
  title: json['title'] as String,
  skill: json['skill'] as String,
  template: json['template'] as String,
  defaultView: json['defaultView'] as String,
  allowedViews: (json['allowedViews'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  sectionCount: (json['sectionCount'] as num).toInt(),
  estimatedMinutes: (json['estimatedMinutes'] as num).toInt(),
  version: (json['version'] as num).toInt(),
  hasRevisionDraft: json['hasRevisionDraft'] as bool? ?? false,
  htmlSize: (json['htmlSize'] as num?)?.toInt() ?? 0,
  status: json['status'] as String?,
  publishAt: json['publishAt'] == null
      ? null
      : DateTime.parse(json['publishAt'] as String),
  publishedAt: json['publishedAt'] == null
      ? null
      : DateTime.parse(json['publishedAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  updatedBy: json['updatedBy'] as String?,
  htmlFileName: json['htmlFileName'] as String?,
  progress: json['progress'] == null
      ? null
      : ProgressModel.fromJson(json['progress'] as Map<String, dynamic>),
  content: _$JsonConverterFromJson<Map<String, dynamic>, DocJson>(
    json['content'],
    const DocJsonConverter().fromJson,
  ),
);

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

DocPageModel _$DocPageModelFromJson(Map<String, dynamic> json) => DocPageModel(
  data: (json['data'] as List<dynamic>)
      .map((e) => DocModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

VersionConflictModel _$VersionConflictModelFromJson(
  Map<String, dynamic> json,
) => VersionConflictModel(
  current: DocModel.fromJson(json['current'] as Map<String, dynamic>),
);
