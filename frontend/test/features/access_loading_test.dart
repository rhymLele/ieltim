import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/dragon_loader.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/views/access_key_page.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LoginApi extends ApiClient {
  final response = Completer<Response<dynamic>>();

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final result = await response.future;
    return Response<T>(
      data: result.data as T?,
      requestOptions: result.requestOptions,
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> mount(WidgetTester tester, _LoginApi api) async {
    final bloc = AuthBloc(apiClient: api);
    final router = GoRouter(
      initialLocation: '/access',
      routes: [
        GoRoute(path: '/access', builder: (_, _) => const AccessKeyPage()),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home loaded')),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'test-key');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Response<dynamic> loginOk() => Response(
    requestOptions: RequestOptions(path: '/auth/access-key'),
    data: {
      'accessToken': 'test-token',
      'user': {'id': 'user-1', 'role': 'USER'},
    },
  );

  testWidgets('fast login still waits for the dragon to finish', (
    tester,
  ) async {
    final api = _LoginApi();
    await mount(tester, api);
    expect(find.byType(DragonLoader), findsOneWidget);
    api.response.complete(loginOk());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.byType(DragonLoader), findsOneWidget);
    expect(find.text('Home loaded'), findsNothing);
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.text('Home loaded'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('slow login navigates as soon as it succeeds after the dragon', (
    tester,
  ) async {
    final api = _LoginApi();
    await mount(tester, api);
    // The dragon plays once (7 s) while the server is still cold-starting.
    await tester.pump(const Duration(seconds: 8));
    expect(find.byType(DragonLoader), findsOneWidget);
    expect(find.text('Home loaded'), findsNothing);
    api.response.complete(loginOk());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
    expect(find.text('Home loaded'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed key restores the form and keeps the entered key', (
    tester,
  ) async {
    final api = _LoginApi();
    await mount(tester, api);
    api.response.completeError(
      DioException(
        requestOptions: RequestOptions(path: '/auth/access-key'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/access-key'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(DragonLoader), findsNothing);
    expect(find.text('Access key is invalid'), findsOneWidget);
    expect(find.text('test-key'), findsOneWidget);
    expect(find.text('Home loaded'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
