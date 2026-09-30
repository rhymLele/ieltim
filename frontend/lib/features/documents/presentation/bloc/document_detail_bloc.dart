import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:frontend/core/network/api_client.dart';

class DocumentDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDocument extends DocumentDetailEvent {
  final String id;
  LoadDocument({required this.id});
  @override
  List<Object?> get props => [id];
}

class DocumentDetailState extends Equatable {
  final bool loading;
  final String? error;
  final Map<String, dynamic> document;
  final List<Map<String, dynamic>> blocks;

  const DocumentDetailState({
    this.loading = false,
    this.error,
    this.document = const {},
    this.blocks = const [],
  });

  DocumentDetailState copyWith({
    bool? loading,
    String? error,
    Map<String, dynamic>? document,
    List<Map<String, dynamic>>? blocks,
    bool clearError = false,
  }) =>
      DocumentDetailState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        document: document ?? this.document,
        blocks: blocks ?? this.blocks,
      );

  @override
  List<Object?> get props => [loading, error, document, blocks];
}

class DocumentDetailBloc extends Bloc<DocumentDetailEvent, DocumentDetailState> {
  final ApiClient _api = ApiClient();

  DocumentDetailBloc() : super(const DocumentDetailState()) {
    on<LoadDocument>(_onLoad);
  }

  Future<void> _onLoad(LoadDocument event, Emitter<DocumentDetailState> emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final docRes = await _api.get('/documents/${event.id}');
      final blocksRes = await _api.get('/documents/${event.id}/blocks');

      final doc = Map<String, dynamic>.from(docRes.data);
      final blocksData = blocksRes.data;
      List<Map<String, dynamic>> blocks;
      if (blocksData is Map && blocksData['data'] is List) {
        blocks = (blocksData['data'] as List).map((b) => Map<String, dynamic>.from(b as Map)).toList();
      } else if (blocksData is List) {
        blocks = blocksData.map((b) => Map<String, dynamic>.from(b as Map)).toList();
      } else {
        blocks = [];
      }

      emit(state.copyWith(loading: false, document: doc, blocks: blocks));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Failed to load document'));
    }
  }
}
