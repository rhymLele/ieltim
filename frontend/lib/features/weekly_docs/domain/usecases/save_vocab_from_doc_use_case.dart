import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/learning_results.dart';
import '../repositories/weekly_docs_repository.dart';

class SaveVocabFromDocUseCase {
  SaveVocabFromDocUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Lưu từ vựng của tài liệu [id] vào Sổ từ, bỏ trùng.
  Future<Result<VocabSaveResult>> execute(String id) => _repository.saveVocabFromDoc(id);
}
