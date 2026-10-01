import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/constants/preview_auth.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthBloc({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage(),
      super(AuthInitial()) {
    on<LoginWithAccessKey>(_onLogin);
    on<Logout>(_onLogout);
  }

  Future<void> _onLogin(
    LoginWithAccessKey event,
    Emitter<AuthState> emit,
  ) async {
    if (event.key.trim().isEmpty) {
      emit(AuthFailure(message: 'Access key is required'));
      return;
    }

    emit(AuthLoading());

    try {
      if (PreviewAuth.enabled && event.key.trim() == PreviewAuth.accessKey) {
        await _tokenStorage.saveToken(
          PreviewAuth.token,
          PreviewAuth.role,
          PreviewAuth.userId,
        );
        emit(
          AuthSuccess(
            accessToken: PreviewAuth.token,
            role: PreviewAuth.role,
            userId: PreviewAuth.userId,
          ),
        );
        return;
      }

      final response = await _apiClient.post(
        '/auth/access-key',
        data: {'key': event.key},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['accessToken'] as String;
      final user = data['user'] as Map<String, dynamic>;
      final role = user['role'] as String;
      final userId = user['id'] as String;

      await _tokenStorage.saveToken(token, role, userId);

      emit(AuthSuccess(accessToken: token, role: role, userId: userId));
    } catch (e) {
      emit(AuthFailure(message: _extractError(e)));
    }
  }

  Future<void> _onLogout(Logout event, Emitter<AuthState> emit) async {
    try {
      if (await _tokenStorage.getToken() != PreviewAuth.token) {
        await _apiClient.post('/auth/logout');
      }
    } catch (_) {}
    await _tokenStorage.clear();
    emit(AuthInitial());
  }

  String _extractError(Object error) {
    final status = error is DioException ? error.response?.statusCode : null;
    if (status == 401) return 'Access key is invalid';
    if (status == 403) return 'Access key is disabled or expired';
    return 'Something went wrong. Please try again.';
  }
}
