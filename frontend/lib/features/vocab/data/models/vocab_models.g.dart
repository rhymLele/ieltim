// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocab_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VocabEntryModel _$VocabEntryModelFromJson(Map<String, dynamic> json) =>
    VocabEntryModel(
      id: json['id'] as String,
      text: json['text'] as String,
      meaning: json['meaning'] as String? ?? '',
      deck: json['deck'] as String? ?? 'Sổ chung',
      createdAt: DateTime.parse(json['createdAt'] as String),
      ipa: json['ipa'] as String?,
      example: json['example'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      sourceDocId: json['sourceDocId'] as String?,
      sourceBlockKey: json['sourceBlockKey'] as String?,
    );

Map<String, dynamic> _$NewVocabRequestToJson(NewVocabRequest instance) =>
    <String, dynamic>{
      'text': instance.text,
      'meaning': instance.meaning,
      'deck': instance.deck,
      'ipa': ?instance.ipa,
      'example': ?instance.example,
      'partOfSpeech': ?instance.partOfSpeech,
      'sourceDocId': ?instance.sourceDocId,
      'sourceBlockKey': ?instance.sourceBlockKey,
    };

Map<String, dynamic> _$UpdateVocabRequestToJson(UpdateVocabRequest instance) =>
    <String, dynamic>{
      'text': ?instance.text,
      'meaning': ?instance.meaning,
      'example': ?instance.example,
      'deck': ?instance.deck,
      'partOfSpeech': ?instance.partOfSpeech,
    };
