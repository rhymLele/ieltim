import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:frontend/core/network/api_client.dart';

class SearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PerformSearch extends SearchEvent {
  final String query;
  PerformSearch({required this.query});
  @override
  List<Object?> get props => [query];
}

class SearchState extends Equatable {
  final bool loading;
  final String? error;
  final String query;
  final List<Map<String, dynamic>> documents;
  final List<Map<String, dynamic>> vocabularies;
  final List<Map<String, dynamic>> sentencePatterns;
  final List<Map<String, dynamic>> webResources;

  const SearchState({
    this.loading = false,
    this.error,
    this.query = '',
    this.documents = const [],
    this.vocabularies = const [],
    this.sentencePatterns = const [],
    this.webResources = const [],
  });

  SearchState copyWith({
    bool? loading,
    String? error,
    String? query,
    List<Map<String, dynamic>>? documents,
    List<Map<String, dynamic>>? vocabularies,
    List<Map<String, dynamic>>? sentencePatterns,
    List<Map<String, dynamic>>? webResources,
    bool clearError = false,
  }) =>
      SearchState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        query: query ?? this.query,
        documents: documents ?? this.documents,
        vocabularies: vocabularies ?? this.vocabularies,
        sentencePatterns: sentencePatterns ?? this.sentencePatterns,
        webResources: webResources ?? this.webResources,
      );

  @override
  List<Object?> get props => [loading, error, query, documents, vocabularies, sentencePatterns, webResources];
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ApiClient _api = ApiClient();

  SearchBloc() : super(const SearchState()) {
    on<PerformSearch>(_onSearch);
  }

  Future<void> _onSearch(PerformSearch event, Emitter<SearchState> emit) async {
    if (event.query.trim().length < 2) return;
    emit(state.copyWith(loading: true, clearError: true, query: event.query));
    try {
      final res = await _api.get('/search', queryParameters: {'q': event.query});
      final data = res.data as Map<String, dynamic>;
      emit(state.copyWith(
        loading: false,
        documents: (data['documents'] as List? ?? []).cast<Map<String, dynamic>>(),
        vocabularies: (data['vocabularies'] as List? ?? []).cast<Map<String, dynamic>>(),
        sentencePatterns: (data['sentencePatterns'] as List? ?? []).cast<Map<String, dynamic>>(),
        webResources: (data['webResources'] as List? ?? []).cast<Map<String, dynamic>>(),
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Search failed'));
    }
  }
}
