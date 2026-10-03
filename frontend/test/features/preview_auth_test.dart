import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/preview_auth.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineApi extends ApiClient {
  int calls = 0;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    calls++;
    throw StateError('Backend is offline');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'mock enters Home session and logs out without contacting backend',
    () async {
      final api = _OfflineApi();
      final storage = TokenStorage();
      final bloc = AuthBloc(apiClient: api, tokenStorage: storage);
      addTearDown(bloc.close);
      final success = bloc.stream.firstWhere((state) => state is AuthSuccess);
      bloc.add(LoginWithAccessKey(key: ' mock '));
      await success;
      expect(api.calls, 0);
      expect(await storage.isLoggedIn(), isTrue);
      expect(await storage.getRole(), PreviewAuth.role);
      final loggedOut = bloc.stream.firstWhere((state) => state is AuthInitial);
      bloc.add(Logout());
      await loggedOut;
      expect(api.calls, 0);
      expect(await storage.isLoggedIn(), isFalse);
    },
  );

  test('normal keys still require backend authentication', () async {
    final api = _OfflineApi();
    final storage = TokenStorage();
    final bloc = AuthBloc(apiClient: api, tokenStorage: storage);
    addTearDown(bloc.close);
    final failure = bloc.stream.firstWhere((state) => state is AuthFailure);
    bloc.add(LoginWithAccessKey(key: 'normal-key'));
    await failure;
    expect(api.calls, 1);
    expect(await storage.isLoggedIn(), isFalse);
  });
}
