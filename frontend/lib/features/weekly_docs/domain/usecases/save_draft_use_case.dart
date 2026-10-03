import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/admin_doc.dart';
import '../entities/doc_json.dart';
import '../repositories/weekly_docs_repository.dart';

class SaveDraftUseCase {
  SaveDraftUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Lưu nháp với [version] đang giữ. Sai version → `VersionConflictException` kèm bản hiện tại.
  Future<Result<AdminDoc>> execute(String id, {required DocJson content, required int version}) => _repository.saveDraft(id, content: content, version: version);
}
