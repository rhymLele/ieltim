// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationIssueModel _$ValidationIssueModelFromJson(
  Map<String, dynamic> json,
) => ValidationIssueModel(
  path: json['path'] as String,
  message: json['message'] as String,
);

ValidationResultModel _$ValidationResultModelFromJson(
  Map<String, dynamic> json,
) => ValidationResultModel(
  errors:
      (json['errors'] as List<dynamic>?)
          ?.map((e) => ValidationIssueModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  warnings:
      (json['warnings'] as List<dynamic>?)
          ?.map((e) => ValidationIssueModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);
