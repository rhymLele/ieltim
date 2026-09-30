import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:frontend/core/network/api_client.dart';

class WebResource {
  final String id;
  final String title;
  final String url;
  final String? domain;
  final String? description;
  final String? imageUrl;
  final String? faviconUrl;
  final String? category;
  final String? tags;
  final bool isFavorite;
  final String? status;
  final String? createdAt;

  WebResource({
    required this.id,
    required this.title,
    required this.url,
    this.domain,
    this.description,
    this.imageUrl,
    this.faviconUrl,
    this.category,
    this.tags,
    this.isFavorite = false,
    this.status,
    this.createdAt,
  });

  factory WebResource.fromJson(Map<String, dynamic> json) => WebResource(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        url: json['url'] ?? '',
        domain: json['domain'],
        description: json['description'],
        imageUrl: json['imageUrl'],
        faviconUrl: json['faviconUrl'],
        category: json['category'],
        tags: json['tags'],
        isFavorite: json['isFavorite'] ?? false,
        status: json['status'],
        createdAt: json['createdAt']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'domain': domain,
        'description': description,
        'imageUrl': imageUrl,
        'faviconUrl': faviconUrl,
        'category': category,
        'tags': tags,
        'isFavorite': isFavorite,
        'status': status,
        'createdAt': createdAt,
      };
}

class WebResourcesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadResources extends WebResourcesEvent {}

class ToggleFavorite extends WebResourcesEvent {
  final String id;
  ToggleFavorite(this.id);
  @override
  List<Object?> get props => [id];
}

class DeleteResource extends WebResourcesEvent {
  final String id;
  DeleteResource(this.id);
  @override
  List<Object?> get props => [id];
}

class WebResourcesState extends Equatable {
  final bool loading;
  final String? error;
  final List<WebResource> resources;

  const WebResourcesState({
    this.loading = false,
    this.error,
    this.resources = const [],
  });

  WebResourcesState copyWith({
    bool? loading,
    String? error,
    List<WebResource>? resources,
    bool clearError = false,
  }) =>
      WebResourcesState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        resources: resources ?? this.resources,
      );

  @override
  List<Object?> get props => [loading, error, resources];
}

class WebResourcesBloc extends Bloc<WebResourcesEvent, WebResourcesState> {
  final ApiClient _api = ApiClient();

  WebResourcesBloc() : super(const WebResourcesState()) {
    on<LoadResources>(_onLoad);
    on<ToggleFavorite>(_onToggleFavorite);
    on<DeleteResource>(_onDelete);
  }

  Future<void> _onLoad(
    LoadResources event,
    Emitter<WebResourcesState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final res = await _api.get('/web-resources');
      final list = (res.data['data'] as List? ?? []);
      final resources = list
          .map((e) => WebResource.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(loading: false, resources: resources));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Failed to load resources'));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<WebResourcesState> emit,
  ) async {
    final resource =
        state.resources.where((r) => r.id == event.id).firstOrNull;
    if (resource == null) return;

    final newFavorite = !resource.isFavorite;
    final updated = state.resources
        .map((r) =>
            r.id == event.id ? WebResource.fromJson({
              ...r.toJson(),
              'isFavorite': newFavorite
            }) : r)
        .toList();
    emit(state.copyWith(resources: updated));

    try {
      await _api.patch('/web-resources/${event.id}', data: {
        'isFavorite': newFavorite
      });
    } catch (_) {
      emit(state.copyWith(resources: state.resources));
    }
  }

  Future<void> _onDelete(
    DeleteResource event,
    Emitter<WebResourcesState> emit,
  ) async {
    try {
      await _api.delete('/web-resources/${event.id}');
      emit(state.copyWith(
        resources: state.resources.where((r) => r.id != event.id).toList(),
      ));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to delete'));
    }
  }

  Future<Map<String, dynamic>> fetchLinkPreview(String url) async {
    final res = await _api.get('/web-resources/link-preview',
        queryParameters: {'url': url});
    return res.data as Map<String, dynamic>;
  }

  Future<void> createResource(Map<String, dynamic> data) async {
    await _api.post('/web-resources', data: data);
  }

  Future<void> updateResource(String id, Map<String, dynamic> data) async {
    await _api.patch('/web-resources/$id', data: data);
  }
}
