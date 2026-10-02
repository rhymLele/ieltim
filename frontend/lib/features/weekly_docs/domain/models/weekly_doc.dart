import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_doc.freezed.dart';
part 'weekly_doc.g.dart';

/// Trạng thái vòng đời tài liệu.
@JsonEnum(fieldRename: FieldRename.none)
enum DocStatus { draft, published, archived }

/// Kiểu xem của tài liệu.
@JsonEnum(fieldRename: FieldRename.none)
enum DocViewMode { slide, doc }

/// Một từ vựng trong khối [DocBlock.vocab].
@freezed
abstract class VocabItem with _$VocabItem {
  const factory VocabItem({
    required String word,
    @Default('') String partOfSpeech,
    @Default('') String ipa,
    @Default('') String meaning,
  }) = _VocabItem;

  factory VocabItem.fromJson(Map<String, dynamic> json) =>
      _$VocabItemFromJson(json);
}

/// Metadata của một tài liệu theo tuần.
@freezed
abstract class DocMeta with _$DocMeta {
  const factory DocMeta({
    @Default('') String title,
    @Default(1) int week,
    @Default(1) int order,
    @Default([]) List<String> skills,
    @Default(10) int estimatedMinutes,
    @Default(DocStatus.draft) DocStatus status,
    @Default(DocViewMode.slide) DocViewMode defaultView,
    @Default([DocViewMode.slide, DocViewMode.doc]) List<DocViewMode> allowedViews,
    @Default(true) bool allowUserSwitchView,
    String? publishAt,
    String? id,
    @Default(1) int version,
    String? createdAt,
    String? updatedAt,
  }) = _DocMeta;

  const DocMeta._();

  factory DocMeta.fromJson(Map<String, dynamic> json) => _$DocMetaFromJson(json);

  /// Skill đầu tiên (dùng làm kicker "Tài liệu n · Skill").
  String? get skill => skills.isNotEmpty ? skills.first : null;

  /// Người dùng có thể tự chuyển Slide/Doc không (cần cả 2 view + công tắc bật).
  bool get allowsSwitch =>
      allowUserSwitchView &&
      allowedViews.contains(DocViewMode.slide) &&
      allowedViews.contains(DocViewMode.doc);
}

/// Một section trong tài liệu.
@freezed
abstract class DocSection with _$DocSection {
  const factory DocSection({
    @Default(null) String? id,
    @Default(null) int? number,
    @Default('') String title,
    @Default([]) List<DocBlock> blocks,
  }) = _DocSection;
}

/// Tài liệu theo tuần (root).
@freezed
abstract class WeeklyDoc with _$WeeklyDoc {
  const factory WeeklyDoc({
    required String id,
    required DocMeta meta,
    @Default([]) List<DocSection> sections,
  }) = _WeeklyDoc;

  const WeeklyDoc._();

  int get partsCount => sections.length;
  int get totalBlocks =>
      sections.fold<int>(0, (sum, s) => sum + s.blocks.length);
  String? get skill => meta.skill;
  int get version => meta.version;
}

/// Khối nội dung trong tài liệu.
///
/// sealed + freezed. Parse thủ công theo [type] (không dùng fromJson sinh tự
/// động) để đảm bảo gặp type lạ thì rơi về [UnknownBlock] mà **không throw**.
@Freezed(fromJson: false, toJson: false)
sealed class DocBlock with _$DocBlock {
  const DocBlock._();

  const factory DocBlock.heading({
    @Default(null) String? id,
    required String text,
  }) = HeadingBlock;

  const factory DocBlock.paragraph({
    @Default(null) String? id,
    required String text,
  }) = ParagraphBlock;

  const factory DocBlock.callout({
    @Default(null) String? id,
    required String text,
  }) = CalloutBlock;

  const factory DocBlock.steps({
    @Default(null) String? id,
    @Default([]) List<String> items,
  }) = StepsBlock;

  const factory DocBlock.passage({
    @Default(null) String? id,
    @Default('') String label,
    required String text,
  }) = PassageBlock;

  const factory DocBlock.quiz({
    @Default(null) String? id,
    required String question,
    @Default([]) List<String> options,
    @Default(0) int correctIndex,
    @Default('') String explanation,
  }) = QuizBlock;

  const factory DocBlock.vocab({
    @Default(null) String? id,
    @Default([]) List<VocabItem> items,
  }) = VocabBlock;

  const factory DocBlock.pattern({
    @Default(null) String? id,
    required String text,
  }) = PatternBlock;

  const factory DocBlock.image({
    @Default(null) String? id,
    required String url,
    @Default('') String alt,
  }) = ImageBlock;

  const factory DocBlock.slideBreak({
    @Default(null) String? id,
  }) = SlideBreakBlock;

  /// Khối chưa hỗ trợ. Giữ nguyên JSON gốc trong [raw].
  const factory DocBlock.unknown({
    @Default(null) String? id,
    required String type,
    required Map<String, dynamic> raw,
  }) = UnknownBlock;

  /// `id` của khối (null nếu JSON không có).
  String? get idOrNull => when(
        heading: (id, text) => id,
        paragraph: (id, text) => id,
        callout: (id, text) => id,
        steps: (id, items) => id,
        passage: (id, label, text) => id,
        quiz: (id, question, options, correctIndex, explanation) => id,
        vocab: (id, items) => id,
        pattern: (id, text) => id,
        image: (id, url, alt) => id,
        slideBreak: (id) => id,
        unknown: (id, type, raw) => id,
      );

  /// Type string (khớp giá trị `type` trong JSON) — dùng cho admin/preview.
  String get typeLabel => when(
        heading: (id, text) => 'heading',
        paragraph: (id, text) => 'paragraph',
        callout: (id, text) => 'callout',
        steps: (id, items) => 'steps',
        passage: (id, label, text) => 'passage',
        quiz: (id, question, options, correctIndex, explanation) => 'quiz',
        vocab: (id, items) => 'vocab',
        pattern: (id, text) => 'pattern',
        image: (id, url, alt) => 'image',
        slideBreak: (id) => 'slideBreak',
        unknown: (id, type, raw) => type,
      );
}
