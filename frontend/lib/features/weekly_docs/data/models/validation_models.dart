import 'package:json_annotation/json_annotation.dart';

import '../../domain/rules/doc_validator.dart';

part 'validation_models.g.dart';

@JsonSerializable(createToJson: false)
class ValidationIssueModel {
  const ValidationIssueModel({required this.path, required this.message});

  factory ValidationIssueModel.fromJson(Map<String, dynamic> json) => _$ValidationIssueModelFromJson(json);

  final String path;
  final String message;

  ValidationIssue toEntity() => ValidationIssue(path, message);
}

/// Dữ liệu kèm lỗi 422 `DOC_INVALID_CONTENT`.
@JsonSerializable(createToJson: false)
class ValidationResultModel {
  const ValidationResultModel({required this.errors, required this.warnings});

  factory ValidationResultModel.fromJson(Map<String, dynamic> json) => _$ValidationResultModelFromJson(json);

  @JsonKey(defaultValue: <ValidationIssueModel>[])
  final List<ValidationIssueModel> errors;
  @JsonKey(defaultValue: <ValidationIssueModel>[])
  final List<ValidationIssueModel> warnings;

  ValidationResult toEntity() => ValidationResult(
        errors: [for (final e in errors) e.toEntity()],
        warnings: [for (final w in warnings) w.toEntity()],
      );
}
