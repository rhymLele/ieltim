import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/vocab_entry.dart';
import '../repositories/vocab_repository.dart';

class ListVocabUseCase {
  ListVocabUseCase([VocabRepository? repository]) : _repository = repository ?? getSingleton<VocabRepository>();

  final VocabRepository _repository;

  /// Các từ đã lưu, mới nhất trước; lọc theo sổ và từ khoá nếu có.
  Future<Result<List<VocabEntry>>> execute({String? deck, String? query}) => _repository.list(deck: deck, query: query);
}
