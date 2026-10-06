// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ProgressRequestToJson(ProgressRequest instance) =>
    <String, dynamic>{
      'sectionIndex': instance.sectionIndex,
      'viewMode': ?instance.viewMode,
    };

Map<String, dynamic> _$QuizAnswerRequestToJson(QuizAnswerRequest instance) =>
    <String, dynamic>{'blockKey': instance.blockKey, 'option': instance.option};

Map<String, dynamic> _$VocabFromDocRequestToJson(
  VocabFromDocRequest instance,
) => <String, dynamic>{'documentId': instance.documentId};

Map<String, dynamic> _$CreateDraftRequestToJson(CreateDraftRequest instance) =>
    <String, dynamic>{
      'week': instance.week,
      'order': instance.order,
      'category': instance.category,
      'content': const DocJsonConverter().toJson(instance.content),
    };

Map<String, dynamic> _$SaveDraftRequestToJson(SaveDraftRequest instance) =>
    <String, dynamic>{
      'content': const DocJsonConverter().toJson(instance.content),
      'version': instance.version,
    };

Map<String, dynamic> _$PublishRequestToJson(PublishRequest instance) =>
    <String, dynamic>{'publishAt': ?instance.publishAt?.toIso8601String()};

Map<String, dynamic> _$DuplicateRequestToJson(DuplicateRequest instance) =>
    <String, dynamic>{'targetWeek': instance.targetWeek};
