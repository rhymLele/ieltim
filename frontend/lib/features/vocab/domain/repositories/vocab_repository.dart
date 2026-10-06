import '../../../../core/errors/result.dart';
import '../entities/vocab_entry.dart';

/// Sổ từ của tôi trên BE (`/me/vocab`). Mọi hàm trả [Result], không ném exception.
abstract interface class VocabRepository {
  /// Các từ đã lưu, mới nhất trước; lọc theo [deck] và [query] (từ hoặc nghĩa) nếu có.
  Future<Result<List<VocabEntry>>> list({String? deck, String? query});

  /// Thêm từ. Trùng từ trong cùng sổ → `VocabExistsException` kèm bản đã lưu.
  Future<Result<VocabEntry>> add(NewVocab vocab);

  /// Sửa từ / nghĩa / câu ví dụ / sổ / từ loại. Trùng với từ khác trong sổ đích → `VocabExistsException`.
  Future<Result<VocabEntry>> update(String id, {String? text, String? meaning, String? example, String? deck, String? partOfSpeech});

  Future<Result<void>> delete(String id);

  /// Từ đã có trong sổ nào chưa (để hiện "Đã có trong sổ").
  Future<Result<bool>> exists(String text);

  /// Các sổ của tôi, dùng gần đây trước; luôn có "Sổ chung".
  Future<Result<List<String>>> decks();
}
