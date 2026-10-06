import 'package:json_annotation/json_annotation.dart';

import '../../../../core/widgets/annotate/models.dart';
import '../../domain/entities/doc_annotations.dart';

part 'annotation_models.g.dart';

/// Ghi chú một slide trên BE kèm `rev` (tăng mỗi lần lưu, chống ghi đè).
@JsonSerializable(createToJson: false)
class SlideStateModel {
  const SlideStateModel({required this.data, required this.rev});

  factory SlideStateModel.fromJson(Map<String, dynamic> json) => _$SlideStateModelFromJson(json);

  /// 409 khi slide chưa có dòng nào trên máy chủ: `data` là null → coi như trống.
  @JsonKey(defaultValue: <String, dynamic>{})
  final Map<String, dynamic> data;
  @JsonKey(defaultValue: 0)
  final int rev;
}

/// `GET /me/docs/:docId/annotations`.
@JsonSerializable(createToJson: false)
class DocAnnotationsModel {
  const DocAnnotationsModel({required this.highlights, required this.slides});

  factory DocAnnotationsModel.fromJson(Map<String, dynamic> json) => _$DocAnnotationsModelFromJson(json);

  /// Đọc bằng `TextHighlight.fromJson` (model dùng chung với widget).
  @JsonKey(defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> highlights;
  @JsonKey(defaultValue: <String, SlideStateModel>{})
  final Map<String, SlideStateModel> slides;

  DocAnnotations toEntity() => DocAnnotations(
        highlights: [for (final h in highlights) TextHighlight.fromJson(h)],
        slides: {for (final e in slides.entries) e.key: SlideAnnotations.fromJson(e.value.data)},
      );
}

/// `POST /translate`.
@JsonSerializable(createToJson: false)
class TranslationModel {
  const TranslationModel({required this.text, required this.meaning, this.ipa, this.partOfSpeech, this.sentenceTranslation});

  factory TranslationModel.fromJson(Map<String, dynamic> json) => _$TranslationModelFromJson(json);

  final String text;
  @JsonKey(defaultValue: '')
  final String meaning;
  final String? ipa;
  final String? partOfSpeech;
  final String? sentenceTranslation;

  TranslationResult toEntity() =>
      TranslationResult(text: text, meaning: meaning, ipa: _orNull(ipa), partOfSpeech: _orNull(partOfSpeech), sentenceTranslation: _orNull(sentenceTranslation));

  static String? _orNull(String? v) => v == null || v.trim().isEmpty ? null : v;
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class TranslateRequest {
  const TranslateRequest({required this.text, this.sentence});

  final String text;
  final String? sentence;
  final String from = 'en';
  final String to = 'vi';

  Map<String, dynamic> toJson() => _$TranslateRequestToJson(this);
}

@JsonSerializable(createFactory: false)
class SlideSaveRequest {
  const SlideSaveRequest({required this.data, required this.rev, required this.docVersion});

  final Map<String, dynamic> data;
  final int rev;
  final int docVersion;

  Map<String, dynamic> toJson() => _$SlideSaveRequestToJson(this);
}
