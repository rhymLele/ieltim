import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/admin_doc.dart';
import '../entities/doc_category.dart';
import '../entities/doc_json.dart';
import '../repositories/weekly_docs_repository.dart';

class CreateDraftUseCase {
  CreateDraftUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Tạo nháp loại [category] ở tuần [week], số [order] từ [content]. Trùng số cùng loại → `DOC_ORDER_TAKEN`.
  Future<Result<AdminDoc>> execute({required int week, required int order, required DocCategory category, required DocJson content}) =>
      _repository.createDraft(week: week, order: order, category: category, content: content);
}
