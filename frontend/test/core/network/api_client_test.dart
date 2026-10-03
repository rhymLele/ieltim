import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  Object? body = {'status': 'success', 'data': <String, dynamic>{}};
  int statusCode = 200;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      statusCode == 204 ? '' : jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _BrokenStorage extends TokenStorage {
  @override
  Future<String?> getToken() async => throw StateError('Storage unavailable');
}

void main() {
  late ApiClient client;
  late _Adapter adapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = ApiClient(baseUrl: 'https://example.test/api');
    adapter = _Adapter();
    client.dio.httpClientAdapter = adapter;
  });

  tearDown(() => client.close(force: true));

  test(
    'unwraps the backend envelope once, preserving nested pagination',
    () async {
      final payload = {
        'data': [
          {'id': 'doc-1'},
        ],
        'currentWeek': 2,
      };
      adapter.body = {'status': 'success', 'data': payload};
      final response = await client.get<Map<String, dynamic>>('/weekly/weeks');
      expect(response.data, payload);
      expect(response.statusCode, 200);
    },
  );

  test('preserves domain status fields and accepts empty responses', () async {
    adapter.body = {'status': 'draft', 'title': 'Lesson'};
    expect((await client.get<dynamic>('/document')).data, adapter.body);
    adapter.body = {'status': 'success'};
    expect((await client.get<dynamic>('/health')).data, adapter.body);
    adapter.body = {'status': 'success', 'data': null};
    expect((await client.get<dynamic>('/optional')).data, isNull);
    adapter.statusCode = 204;
    expect((await client.delete<dynamic>('/document')).statusCode, 204);
  });

  test(
    'reads current tokens for each request and honors explicit auth',
    () async {
      final storage = TokenStorage();
      await client.get<dynamic>('/public');
      expect(adapter.requests.last.headers['Authorization'], isNull);
      await storage.saveToken('first', 'USER', '1');
      await client.get<dynamic>('/me');
      expect(adapter.requests.last.headers['Authorization'], 'Bearer first');
      await storage.saveToken('second', 'USER', '1');
      await client.get<dynamic>('/me');
      expect(adapter.requests.last.headers['Authorization'], 'Bearer second');
      await client.get<dynamic>(
        '/me',
        options: Options(headers: {'Authorization': 'Bearer explicit'}),
      );
      expect(adapter.requests.last.headers['Authorization'], 'Bearer explicit');
    },
  );

  test(
    '401 clears the session and preserves the original error body',
    () async {
      final storage = TokenStorage();
      await storage.saveToken('expired', 'USER', '1');
      adapter.statusCode = 401;
      adapter.body = {'message': 'Expired', 'error': 'UNAUTHORIZED'};
      await expectLater(
        client.get<dynamic>('/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.data,
            'body',
            adapter.body,
          ),
        ),
      );
      expect(await storage.getToken(), isNull);
      expect(await storage.getRole(), isNull);
      expect(await storage.getUserId(), isNull);
    },
  );

  test('409 preserves conflict details and the current session', () async {
    final storage = TokenStorage();
    await storage.saveToken('valid', 'USER', '1');
    adapter.statusCode = 409;
    adapter.body = {
      'error': 'DOC_VERSION_CONFLICT',
      'data': {
        'current': {'version': 3},
      },
    };
    await expectLater(
      client.put<dynamic>('/document', data: {'version': 2}),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.data,
          'body',
          adapter.body,
        ),
      ),
    );
    expect(await storage.getToken(), 'valid');
  });

  test('request options do not leak into subsequent calls', () async {
    final options = Options(
      method: 'GET',
      receiveTimeout: const Duration(seconds: 30),
      headers: {'X-Custom': 'one'},
    );
    await client.post<dynamic>(
      '/documents',
      data: {'title': 'Lesson'},
      queryParameters: {'preview': true},
      options: options,
    );
    final request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(
      request.uri.toString(),
      'https://example.test/api/documents?preview=true',
    );
    expect(request.data, {'title': 'Lesson'});
    expect(request.receiveTimeout, const Duration(seconds: 30));
    expect(request.headers['X-Custom'], 'one');
    expect(options.method, 'GET');
    await client.get<dynamic>('/documents');
    expect(adapter.requests.last.receiveTimeout, const Duration(seconds: 10));
    expect(adapter.requests.last.headers.containsKey('X-Custom'), isFalse);
  });

  test('cancelled requests remain cancellation errors', () async {
    final token = CancelToken()..cancel('Screen closed');
    await expectLater(
      client.get<dynamic>('/documents', cancelToken: token),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
  });

  test('storage failures complete with an error instead of hanging', () async {
    final broken = ApiClient(tokenStorage: _BrokenStorage());
    broken.dio.httpClientAdapter = adapter;
    addTearDown(() => broken.close(force: true));
    await expectLater(
      broken.get<dynamic>('/me'),
      throwsA(
        isA<DioException>().having((e) => e.error, 'cause', isA<StateError>()),
      ),
    );
    expect(adapter.requests, isEmpty);
  });
}
