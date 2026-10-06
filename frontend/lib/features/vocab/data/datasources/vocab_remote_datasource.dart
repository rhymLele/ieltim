import 'package:dio/dio.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/vocab_entry.dart';
import '../models/vocab_models.dart';

/// Gọi API Sổ từ (`/me/vocab`, backend/src/annotations/README.md). Ném [AppException] đã phân loại.
class VocabRemoteDataSource {
  VocabRemoteDataSource([Dio? dio]) : _dio = dio ?? getSingleton<ApiClient>().dio;

  final Dio _dio;

  static const _base = '/me/vocab';

  Future<List<VocabEntryModel>> list({String? deck, String? query}) async {
    final data = await _send(() => _dio.get(_base, queryParameters: {
          if (deck != null && deck.isNotEmpty) 'deck': deck,
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        }));
    if (data is! List) throw const UnknownException('Máy chủ trả dữ liệu không đúng định dạng.');
    return [for (final item in data.whereType<Map<String, dynamic>>()) VocabEntryModel.fromJson(item)];
  }

  Future<VocabEntryModel> add(NewVocabRequest body) async => VocabEntryModel.fromJson(await _map(() => _dio.post(_base, data: body.toJson())));

  Future<VocabEntryModel> update(String id, UpdateVocabRequest body) async =>
      VocabEntryModel.fromJson(await _map(() => _dio.patch('$_base/$id', data: body.toJson())));

  Future<void> delete(String id) => _send(() => _dio.delete('$_base/$id'));

  Future<bool> exists(String text) async => await _send(() => _dio.get('$_base/exists', queryParameters: {'text': text})) == true;

  Future<List<String>> decks() async {
    final data = await _send(() => _dio.get('$_base/decks'));
    return data is List ? data.whereType<String>().toList() : const [defaultVocabDeck];
  }

  Future<Map<String, dynamic>> _map(Future<Response<Object?>> Function() call) async {
    final data = await _send(call);
    if (data is Map<String, dynamic>) return data;
    throw const UnknownException('Máy chủ trả dữ liệu không đúng định dạng.');
  }

  Future<Object?> _send(Future<Response<Object?>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw mapDioException(e, special: (error) {
        final existing = error.data;
        if (error.code == 'VOCAB_EXISTS' && existing is Map<String, dynamic>) {
          return VocabExistsException(error.message, existing: VocabEntryModel.fromJson(existing).toEntity());
        }
        return null;
      });
    }
  }
}
