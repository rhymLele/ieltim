import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/doc_progress.dart';
import '../entities/weekly_doc.dart';
import '../repositories/weekly_docs_repository.dart';

class SaveProgressUseCase {
  SaveProgressUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Ghi đã xem section [sectionIndex] của tài liệu [id] (idempotent).
  Future<Result<DocProgress>> execute(String id, {required int sectionIndex, DocViewMode? view}) => _repository.saveProgress(id, sectionIndex: sectionIndex, view: view);
}
