import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../repositories/vocab_repository.dart';

class GetVocabDecksUseCase {
  GetVocabDecksUseCase([VocabRepository? repository]) : _repository = repository ?? getSingleton<VocabRepository>();

  final VocabRepository _repository;

  /// Các sổ của tôi, dùng gần đây trước.
  Future<Result<List<String>>> execute() => _repository.decks();
}
