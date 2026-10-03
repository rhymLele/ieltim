import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/learning_results.dart';
import '../repositories/weekly_docs_repository.dart';

class AnswerQuizUseCase {
  AnswerQuizUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Lưu lựa chọn [option] cho câu trắc nghiệm [blockKey]; trả đúng / sai và giải thích.
  Future<Result<QuizFeedback>> execute(String id, {required String blockKey, required int option}) => _repository.answerQuiz(id, blockKey: blockKey, option: option);
}
