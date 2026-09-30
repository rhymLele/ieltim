import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:frontend/core/network/api_client.dart';

class AdminDocumentsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAdminDocuments extends AdminDocumentsEvent {}

class AdminDocumentsState extends Equatable {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> documents;

  const AdminDocumentsState({
    this.loading = false,
    this.error,
    this.documents = const [],
  });

  AdminDocumentsState copyWith({
    bool? loading,
    String? error,
    List<Map<String, dynamic>>? documents,
    bool clearError = false,
  }) =>
      AdminDocumentsState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        documents: documents ?? this.documents,
      );

  @override
  List<Object?> get props => [loading, error, documents];
}

class AdminDocumentsBloc extends Bloc<AdminDocumentsEvent, AdminDocumentsState> {
  final ApiClient _api = ApiClient();

  AdminDocumentsBloc() : super(const AdminDocumentsState()) {
    on<LoadAdminDocuments>(_onLoad);
  }

  Future<void> _onLoad(LoadAdminDocuments event, Emitter<AdminDocumentsState> emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final res = await _api.get('/documents');
      final data = res.data;
      final docs = (data['data'] as List? ?? []).cast<Map<String, dynamic>>();
      emit(state.copyWith(loading: false, documents: docs));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Failed to load documents'));
    }
  }
}
