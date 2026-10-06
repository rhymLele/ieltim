// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annotation_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlideStateModel _$SlideStateModelFromJson(Map<String, dynamic> json) =>
    SlideStateModel(
      data: json['data'] as Map<String, dynamic>? ?? {},
      rev: (json['rev'] as num?)?.toInt() ?? 0,
    );

DocAnnotationsModel _$DocAnnotationsModelFromJson(Map<String, dynamic> json) =>
    DocAnnotationsModel(
      highlights:
          (json['highlights'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      slides:
          (json['slides'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SlideStateModel.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          {},
    );

TranslationModel _$TranslationModelFromJson(Map<String, dynamic> json) =>
    TranslationModel(
      text: json['text'] as String,
      meaning: json['meaning'] as String? ?? '',
      ipa: json['ipa'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      sentenceTranslation: json['sentenceTranslation'] as String?,
    );

Map<String, dynamic> _$TranslateRequestToJson(TranslateRequest instance) =>
    <String, dynamic>{
      'text': instance.text,
      'sentence': ?instance.sentence,
      'from': instance.from,
      'to': instance.to,
    };

Map<String, dynamic> _$SlideSaveRequestToJson(SlideSaveRequest instance) =>
    <String, dynamic>{
      'data': instance.data,
      'rev': instance.rev,
      'docVersion': instance.docVersion,
    };
