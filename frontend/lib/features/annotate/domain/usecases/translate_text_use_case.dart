import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/widgets/annotate/models.dart';
import '../repositories/annotate_repository.dart';

class TranslateTextUseCase {
  TranslateTextUseCase([AnnotateRepository? repository]) : _repository = repository ?? getSingleton<AnnotateRepository>();

  final AnnotateRepository _repository;

  /// Dịch nghĩa [text] theo ngữ cảnh câu [sentence].
  Future<Result<TranslationResult>> execute(String text, {String? sentence}) => _repository.translate(text, sentence: sentence);
}
