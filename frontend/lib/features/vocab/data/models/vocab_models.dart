import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/vocab_entry.dart';

part 'vocab_models.g.dart';

/// Một từ trong `/me/vocab`.
@JsonSerializable(createToJson: false)
class VocabEntryModel {
  const VocabEntryModel({
    required this.id,
    required this.text,
    required this.meaning,
    required this.deck,
    required this.createdAt,
    this.ipa,
    this.example,
    this.partOfSpeech,
    this.sourceDocId,
    this.sourceBlockKey,
  });

  factory VocabEntryModel.fromJson(Map<String, dynamic> json) => _$VocabEntryModelFromJson(json);

  final String id;
  final String text;
  @JsonKey(defaultValue: '')
  final String meaning;
  @JsonKey(defaultValue: defaultVocabDeck)
  final String deck;
  final DateTime createdAt;
  final String? ipa;
  final String? example;
  final String? partOfSpeech;
  final String? sourceDocId;
  final String? sourceBlockKey;

  VocabEntry toEntity() => VocabEntry(
        id: id,
        text: text,
        meaning: meaning,
        ipa: ipa,
        example: example,
        partOfSpeech: partOfSpeech,
        deck: deck,
        sourceDocId: sourceDocId,
        sourceBlockKey: sourceBlockKey,
        createdAt: createdAt.toLocal(),
      );
}

/// `POST /me/vocab`.
@JsonSerializable(createFactory: false, includeIfNull: false)
class NewVocabRequest {
  const NewVocabRequest({
    required this.text,
    required this.meaning,
    required this.deck,
    this.ipa,
    this.example,
    this.partOfSpeech,
    this.sourceDocId,
    this.sourceBlockKey,
  });

  factory NewVocabRequest.of(NewVocab v) => NewVocabRequest(
        text: v.text,
        meaning: v.meaning,
        deck: v.deck,
        ipa: v.ipa,
        example: v.example,
        partOfSpeech: v.partOfSpeech,
        sourceDocId: v.sourceDocId,
        sourceBlockKey: v.sourceBlockKey,
      );

  final String text;
  final String meaning;
  final String deck;
  final String? ipa;
  final String? example;
  final String? partOfSpeech;
  final String? sourceDocId;
  final String? sourceBlockKey;

  Map<String, dynamic> toJson() => _$NewVocabRequestToJson(this);
}

/// `PATCH /me/vocab/:id`: chỉ gửi trường đổi.
@JsonSerializable(createFactory: false, includeIfNull: false)
class UpdateVocabRequest {
  const UpdateVocabRequest({this.text, this.meaning, this.example, this.deck, this.partOfSpeech});

  final String? text;
  final String? meaning;
  final String? example;
  final String? deck;
  final String? partOfSpeech;

  Map<String, dynamic> toJson() => _$UpdateVocabRequestToJson(this);
}
