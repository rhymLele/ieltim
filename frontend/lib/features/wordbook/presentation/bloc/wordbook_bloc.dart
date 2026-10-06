import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../../vocab/domain/entities/vocab_entry.dart';
import '../../../vocab/domain/repositories/vocab_repository.dart';

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

  /// Sổ trên BE ("Sổ chung", "Tuần 12"…).
  final String? deck;

  /// Tài liệu theo tuần lưu từ này: chạm để mở lại đúng khối.
  final String? sourceDocId;
  final String? sourceBlockKey;
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
    this.deck,
    this.sourceDocId,
    this.sourceBlockKey,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Từ trên BE. Từ loại hiện ở ô tag như trước.
  factory LocalWordbookItem.fromVocab(VocabEntry e) => LocalWordbookItem(
        id: e.id,
        word: e.text,
        meaning: e.meaning.isEmpty ? null : e.meaning,
        example: e.example,
        tag: e.partOfSpeech,
        deck: e.deck,
        sourceDocId: e.sourceDocId,
        sourceBlockKey: e.sourceBlockKey,
        sourceReferenceId: e.sourceDocId,
        sourceReferenceType: e.sourceDocId == null ? SourceType.manual : SourceType.lesson,
        createdAt: e.createdAt,
        updatedAt: e.createdAt,
      );

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
        deck: json['deck'],
        sourceDocId: json['sourceDocId'],
        sourceBlockKey: json['sourceBlockKey'],
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
        'deck': deck,
        'sourceDocId': sourceDocId,
        'sourceBlockKey': sourceBlockKey,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Sổ từ: BE (`/me/vocab`) là nguồn chính, đồng bộ mọi máy; bản trên máy là cache để mở khi offline.
/// Từ cũ chỉ lưu trên máy (trước khi có BE) được đẩy lên một lần. Chưa đăng ký BE (test) thì chỉ lưu trên máy.
class WordbookRepository {
  WordbookRepository({VocabRepository? remote}) : _remote = remote ?? maybeSingleton<VocabRepository>();

  final VocabRepository? _remote;

  static const _key = 'local_wordbook_items';
  static const _uploadedKey = 'local_wordbook_uploaded_v1';
  static final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

  /// Id do BE cấp (UUID); id khác là từ chỉ có trên máy.
  static bool _onServer(String id) => _uuid.hasMatch(id);

  Future<List<LocalWordbookItem>> getAll() async {
    final remote = _remote;
    if (remote == null) return _readLocal();
    final uploaded = await _uploadLegacy(remote);
    switch (await remote.list()) {
      case Success(:final data):
        final items = [for (final e in data) LocalWordbookItem.fromVocab(e)];
        if (!uploaded) {
          // Còn từ cũ chưa đẩy lên được (mất mạng): giữ lại để lần sau đẩy tiếp.
          items.addAll((await _readLocal()).where((i) => !_onServer(i.id)));
        }
        await _persist(items);
        return items;
      case Failure():
        return _readLocal(); // offline: bản lần trước
    }
  }

  /// Thêm / sửa. Lỗi (mất mạng, trùng từ) ném [AppException] để màn hình báo.
  Future<void> save(LocalWordbookItem item) async {
    final remote = _remote;
    if (remote == null) {
      final items = await _readLocal();
      final index = items.indexWhere((i) => i.id == item.id);
      if (index >= 0) {
        items[index] = item;
      } else {
        items.add(item);
      }
      await _persist(items);
      return;
    }
    var result = _onServer(item.id)
        ? await remote.update(item.id, text: item.word, meaning: item.meaning ?? '', example: item.example ?? '', partOfSpeech: item.tag)
        : await remote.add(_toNew(item));
    // Id không còn trên BE (đã xoá ở máy khác, file JSON nhập từ tài khoản khác): thêm mới.
    if (result case Failure(exception: ServerException(statusCode: 404))) result = await remote.add(_toNew(item));
    if (result case Failure(:final exception)) throw exception;
  }

  Future<void> delete(String id) async {
    final remote = _remote;
    if (remote != null && _onServer(id)) {
      if (await remote.delete(id) case Failure(:final exception)) throw exception;
    }
    final items = await _readLocal();
    items.removeWhere((i) => i.id == id);
    await _persist(items);
  }

  /// Tìm trong bản đã tải (không gọi BE mỗi lần gõ).
  Future<List<LocalWordbookItem>> search(String query) async {
    final items = await _readLocal();
    final q = query.toLowerCase();
    return items
        .where((i) =>
            i.word.toLowerCase().contains(q) ||
            (i.meaning?.toLowerCase().contains(q) ?? false) ||
            (i.definition?.toLowerCase().contains(q) ?? false) ||
            (i.topic?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  static NewVocab _toNew(LocalWordbookItem item) => NewVocab(
        text: item.word,
        meaning: item.meaning ?? item.definition ?? '',
        example: item.example,
        partOfSpeech: item.tag,
        deck: item.deck ?? defaultVocabDeck,
        sourceDocId: item.sourceDocId,
        sourceBlockKey: item.sourceBlockKey,
      );

  /// Đẩy từ cũ chỉ có trên máy lên BE (một lần). Trả true khi không còn từ nào chờ đẩy.
  Future<bool> _uploadLegacy(VocabRepository remote) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_uploadedKey) ?? false) return true;
    for (final item in (await _readLocal()).where((i) => !_onServer(i.id))) {
      final result = await remote.add(_toNew(item));
      if (result case Failure(:final exception) when exception is! VocabExistsException) return false;
    }
    await prefs.setBool(_uploadedKey, true);
    return true;
  }

  Future<List<LocalWordbookItem>> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    return list.map((e) => LocalWordbookItem.fromJson(e)).toList();
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

  /// Báo lỗi một lần (mất mạng, trùng từ). [errorId] tăng mỗi lần để màn hình biết có lỗi mới.
  final String? error;
  final int errorId;

  const WordbookState({
    this.loading = false,
    this.items = const [],
    this.searchQuery = '',
    this.error,
    this.errorId = 0,
  });

  WordbookState copyWith({
    bool? loading,
    List<LocalWordbookItem>? items,
    String? searchQuery,
    String? error,
  }) =>
      WordbookState(
        loading: loading ?? this.loading,
        items: items ?? this.items,
        searchQuery: searchQuery ?? this.searchQuery,
        error: error ?? this.error,
        errorId: error == null ? errorId : errorId + 1,
      );

  @override
  List<Object?> get props => [loading, items, searchQuery, error, errorId];
}

class WordbookBloc extends Bloc<WordbookEvent, WordbookState> {
  final WordbookRepository _repo;

  WordbookBloc({WordbookRepository? repository})
      : _repo = repository ?? WordbookRepository(),
        super(const WordbookState()) {
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
    try {
      await _repo.save(event.item);
    } on VocabExistsException {
      emit(state.copyWith(error: 'Từ này đã có trong Sổ từ'));
    } on AppException catch (e) {
      emit(state.copyWith(error: e.message));
      return;
    }
    final items = await _repo.getAll();
    emit(state.copyWith(items: items));
  }

  Future<void> _onDelete(DeleteWord event, Emitter<WordbookState> emit) async {
    try {
      await _repo.delete(event.id);
    } on AppException catch (e) {
      emit(state.copyWith(error: e.message));
      return;
    }
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
