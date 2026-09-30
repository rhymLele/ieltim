import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SourceType { lesson, vocabulary, sentencePattern, theory, external, manual }

class LocalWordbookItem {
  final String id;
  final String word;
  final String? meaning;
  final String? definition;
  final String? example;
  final String? tag;
  final String? topic;
  final String? sourceReferenceId;
  final SourceType? sourceReferenceType;
  final String? collocations;
  final String? note;
  final String? level;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalWordbookItem({
    required this.id,
    required this.word,
    this.meaning,
    this.definition,
    this.example,
    this.tag,
    this.topic,
    this.sourceReferenceId,
    this.sourceReferenceType,
    this.collocations,
    this.note,
    this.level,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocalWordbookItem.fromJson(Map<String, dynamic> json) => LocalWordbookItem(
        id: json['id'] ?? '',
        word: json['word'] ?? '',
        meaning: json['meaning'],
        definition: json['definition'],
        example: json['example'],
        tag: json['tag'],
        topic: json['topic'],
        sourceReferenceId: json['sourceReferenceId'],
        sourceReferenceType: json['sourceReferenceType'] != null
            ? SourceType.values.firstWhere(
                (e) => e.name == json['sourceReferenceType'],
                orElse: () => SourceType.manual,
              )
            : null,
        collocations: json['collocations'],
        note: json['note'],
        level: json['level'],
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'meaning': meaning,
        'definition': definition,
        'example': example,
        'tag': tag,
        'topic': topic,
        'sourceReferenceId': sourceReferenceId,
        'sourceReferenceType': sourceReferenceType?.name,
        'collocations': collocations,
        'note': note,
        'level': level,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class WordbookRepository {
  static const _key = 'local_wordbook_items';

  Future<List<LocalWordbookItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    return list.map((e) => LocalWordbookItem.fromJson(e)).toList();
  }

  Future<void> save(LocalWordbookItem item) async {
    final items = await getAll();
    final index = items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await _persist(items);
  }

  Future<void> delete(String id) async {
    final items = await getAll();
    items.removeWhere((i) => i.id == id);
    await _persist(items);
  }

  Future<List<LocalWordbookItem>> search(String query) async {
    final items = await getAll();
    final q = query.toLowerCase();
    return items
        .where((i) =>
            i.word.toLowerCase().contains(q) ||
            (i.meaning?.toLowerCase().contains(q) ?? false) ||
            (i.definition?.toLowerCase().contains(q) ?? false) ||
            (i.topic?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<void> _persist(List<LocalWordbookItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}

// BLOC

class WordbookEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadWordbook extends WordbookEvent {}

class AddWord extends WordbookEvent {
  final LocalWordbookItem item;
  AddWord(this.item);
  @override
  List<Object?> get props => [item];
}

class DeleteWord extends WordbookEvent {
  final String id;
  DeleteWord(this.id);
  @override
  List<Object?> get props => [id];
}

class SearchWords extends WordbookEvent {
  final String query;
  SearchWords(this.query);
  @override
  List<Object?> get props => [query];
}

class WordbookState extends Equatable {
  final bool loading;
  final List<LocalWordbookItem> items;
  final String searchQuery;

  const WordbookState({
    this.loading = false,
    this.items = const [],
    this.searchQuery = '',
  });

  WordbookState copyWith({
    bool? loading,
    List<LocalWordbookItem>? items,
    String? searchQuery,
  }) =>
      WordbookState(
        loading: loading ?? this.loading,
        items: items ?? this.items,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  @override
  List<Object?> get props => [loading, items, searchQuery];
}

class WordbookBloc extends Bloc<WordbookEvent, WordbookState> {
  final WordbookRepository _repo = WordbookRepository();

  WordbookBloc() : super(const WordbookState()) {
    on<LoadWordbook>(_onLoad);
    on<AddWord>(_onAdd);
    on<DeleteWord>(_onDelete);
    on<SearchWords>(_onSearch);
  }

  Future<void> _onLoad(LoadWordbook event, Emitter<WordbookState> emit) async {
    emit(state.copyWith(loading: true));
    final items = await _repo.getAll();
    emit(state.copyWith(loading: false, items: items));
  }

  Future<void> _onAdd(AddWord event, Emitter<WordbookState> emit) async {
    await _repo.save(event.item);
    final items = await _repo.getAll();
    emit(state.copyWith(items: items));
  }

  Future<void> _onDelete(DeleteWord event, Emitter<WordbookState> emit) async {
    await _repo.delete(event.id);
    final items = await _repo.getAll();
    emit(state.copyWith(items: items));
  }

  Future<void> _onSearch(SearchWords event, Emitter<WordbookState> emit) async {
    emit(state.copyWith(searchQuery: event.query));
    if (event.query.isEmpty) {
      final items = await _repo.getAll();
      emit(state.copyWith(items: items));
    } else {
      final items = await _repo.search(event.query);
      emit(state.copyWith(items: items));
    }
  }
}
