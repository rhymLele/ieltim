import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/doc_json.dart';
import 'doc_json_converter.dart';

part 'request_models.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class ProgressRequest {
  const ProgressRequest({required this.sectionIndex, this.viewMode});
  final int sectionIndex;
  final String? viewMode;
  Map<String, dynamic> toJson() => _$ProgressRequestToJson(this);
}

@JsonSerializable(createFactory: false)
class QuizAnswerRequest {
  const QuizAnswerRequest({required this.blockKey, required this.option});
  final String blockKey;
  final int option;
  Map<String, dynamic> toJson() => _$QuizAnswerRequestToJson(this);
}

@JsonSerializable(createFactory: false)
class VocabFromDocRequest {
  const VocabFromDocRequest({required this.documentId});
  final String documentId;
  Map<String, dynamic> toJson() => _$VocabFromDocRequestToJson(this);
}

@JsonSerializable(createFactory: false)
class CreateDraftRequest {
  const CreateDraftRequest({required this.week, required this.order, required this.category, required this.content});
  final int week;
  final int order;

  /// `lesson` | `homework`.
  final String category;
  @DocJsonConverter()
  final DocJson content;
  Map<String, dynamic> toJson() => _$CreateDraftRequestToJson(this);
}

@JsonSerializable(createFactory: false)
class SaveDraftRequest {
  const SaveDraftRequest({required this.content, required this.version});
  @DocJsonConverter()
  final DocJson content;
  final int version;
  Map<String, dynamic> toJson() => _$SaveDraftRequestToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class PublishRequest {
  const PublishRequest({this.publishAt});

  /// Có giá trị = hẹn giờ (UTC, ISO 8601).
  final DateTime? publishAt;
  Map<String, dynamic> toJson() => _$PublishRequestToJson(this);
}

@JsonSerializable(createFactory: false)
class DuplicateRequest {
  const DuplicateRequest({required this.targetWeek});
  final int targetWeek;
  Map<String, dynamic> toJson() => _$DuplicateRequestToJson(this);
}
