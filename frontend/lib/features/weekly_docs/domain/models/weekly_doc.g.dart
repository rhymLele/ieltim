// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_doc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VocabItem _$VocabItemFromJson(Map<String, dynamic> json) => _VocabItem(
  word: json['word'] as String,
  partOfSpeech: json['partOfSpeech'] as String? ?? '',
  ipa: json['ipa'] as String? ?? '',
  meaning: json['meaning'] as String? ?? '',
);

Map<String, dynamic> _$VocabItemToJson(_VocabItem instance) =>
    <String, dynamic>{
      'word': instance.word,
      'partOfSpeech': instance.partOfSpeech,
      'ipa': instance.ipa,
      'meaning': instance.meaning,
    };

_DocMeta _$DocMetaFromJson(Map<String, dynamic> json) => _DocMeta(
  title: json['title'] as String? ?? '',
  week: (json['week'] as num?)?.toInt() ?? 1,
  order: (json['order'] as num?)?.toInt() ?? 1,
  skills:
      (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 10,
  status:
      $enumDecodeNullable(_$DocStatusEnumMap, json['status']) ??
      DocStatus.draft,
  defaultView:
      $enumDecodeNullable(_$DocViewModeEnumMap, json['defaultView']) ??
      DocViewMode.slide,
  allowedViews:
      (json['allowedViews'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$DocViewModeEnumMap, e))
          .toList() ??
      const [DocViewMode.slide, DocViewMode.doc],
  allowUserSwitchView: json['allowUserSwitchView'] as bool? ?? true,
  publishAt: json['publishAt'] as String?,
  id: json['id'] as String?,
  version: (json['version'] as num?)?.toInt() ?? 1,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$DocMetaToJson(_DocMeta instance) => <String, dynamic>{
  'title': instance.title,
  'week': instance.week,
  'order': instance.order,
  'skills': instance.skills,
  'estimatedMinutes': instance.estimatedMinutes,
  'status': _$DocStatusEnumMap[instance.status]!,
  'defaultView': _$DocViewModeEnumMap[instance.defaultView]!,
  'allowedViews': instance.allowedViews
      .map((e) => _$DocViewModeEnumMap[e]!)
      .toList(),
  'allowUserSwitchView': instance.allowUserSwitchView,
  'publishAt': instance.publishAt,
  'id': instance.id,
  'version': instance.version,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

const _$DocStatusEnumMap = {
  DocStatus.draft: 'draft',
  DocStatus.published: 'published',
  DocStatus.archived: 'archived',
};

const _$DocViewModeEnumMap = {
  DocViewMode.slide: 'slide',
  DocViewMode.doc: 'doc',
};
