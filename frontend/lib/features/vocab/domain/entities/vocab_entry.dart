import '../../../../core/errors/app_exception.dart';

/// Sổ mặc định khi người học không chọn sổ nào.
const defaultVocabDeck = 'Sổ chung';

/// Một từ / cụm từ trong Sổ từ của tôi (lưu trên BE, đồng bộ mọi máy).
class VocabEntry {
  const VocabEntry({
    required this.id,
    required this.text,
    this.meaning = '',
    this.ipa,
    this.example,
    this.partOfSpeech,
    this.deck = defaultVocabDeck,
    this.sourceDocId,
    this.sourceBlockKey,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String meaning;
  final String? ipa;

  /// Câu ví dụ, thường là câu chứa từ trong bài.
  final String? example;
  final String? partOfSpeech;
  final String deck;

  /// Tài liệu theo tuần lưu từ này (để mở lại đúng chỗ).
  final String? sourceDocId;
  final String? sourceBlockKey;
  final DateTime createdAt;
}

/// Từ cần thêm vào Sổ từ.
class NewVocab {
  const NewVocab({
    required this.text,
    this.meaning = '',
    this.ipa,
    this.example,
    this.partOfSpeech,
    this.deck = defaultVocabDeck,
    this.sourceDocId,
    this.sourceBlockKey,
  });

  final String text;
  final String meaning;
  final String? ipa;
  final String? example;
  final String? partOfSpeech;
  final String deck;
  final String? sourceDocId;
  final String? sourceBlockKey;
}

/// 409 `VOCAB_EXISTS`: từ đã có trong sổ này; [existing] là bản đã lưu.
class VocabExistsException extends ServerException {
  const VocabExistsException(super.message, {required this.existing}) : super(code: 'VOCAB_EXISTS', statusCode: 409);

  final VocabEntry existing;
}
