import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/vocab_entry.dart';
import '../../domain/repositories/vocab_repository.dart';
import '../datasources/vocab_remote_datasource.dart';
import '../models/vocab_models.dart';

/// Sổ từ trên BE. Lỗi thành [Failure]; không ghi nội dung từ vựng ra log.
class VocabRepositoryImpl implements VocabRepository {
  VocabRepositoryImpl({VocabRemoteDataSource? remote, LoggerService? logger})
      : _remote = remote ?? VocabRemoteDataSource(),
        _logger = logger ?? getSingleton<LoggerService>();

  final VocabRemoteDataSource _remote;
  final LoggerService _logger;

  @override
  Future<Result<List<VocabEntry>>> list({String? deck, String? query}) =>
      _guard('tải sổ từ', () async => [for (final m in await _remote.list(deck: deck, query: query)) m.toEntity()]);

  @override
  Future<Result<VocabEntry>> add(NewVocab vocab) => _guard('thêm từ', () async => (await _remote.add(NewVocabRequest.of(vocab))).toEntity());

  @override
  Future<Result<VocabEntry>> update(String id, {String? text, String? meaning, String? example, String? deck, String? partOfSpeech}) => _guard(
        'sửa từ',
        () async =>
            (await _remote.update(id, UpdateVocabRequest(text: text, meaning: meaning, example: example, deck: deck, partOfSpeech: partOfSpeech))).toEntity(),
      );

  @override
  Future<Result<void>> delete(String id) => _guard('xoá từ', () => _remote.delete(id));

  @override
  Future<Result<bool>> exists(String text) => _guard('kiểm tra từ', () => _remote.exists(text));

  @override
  Future<Result<List<String>>> decks() => _guard('tải danh sách sổ', _remote.decks);

  Future<Result<T>> _guard<T>(String action, Future<T> Function() call) async {
    try {
      return Success(await call());
    } on AppException catch (e) {
      _logger.warning('vocab: $action thất bại — ${e is ServerException ? e.code : e.runtimeType}');
      return Failure(e);
    } on Object catch (e, stackTrace) {
      _logger.error('vocab: $action gặp lỗi không xác định', e, stackTrace);
      return const Failure(UnknownException());
    }
  }
}
