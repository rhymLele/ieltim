import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/vocab_entry.dart';
import '../repositories/vocab_repository.dart';

class UpdateVocabUseCase {
  UpdateVocabUseCase([VocabRepository? repository]) : _repository = repository ?? getSingleton<VocabRepository>();

  final VocabRepository _repository;

  /// Sửa từ / nghĩa / câu ví dụ / sổ / từ loại.
  Future<Result<VocabEntry>> execute(String id, {String? text, String? meaning, String? example, String? deck, String? partOfSpeech}) =>
      _repository.update(id, text: text, meaning: meaning, example: example, deck: deck, partOfSpeech: partOfSpeech);
}
