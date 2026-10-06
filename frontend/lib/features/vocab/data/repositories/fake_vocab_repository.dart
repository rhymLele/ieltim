import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/uuid.dart';
import '../../domain/entities/vocab_entry.dart';
import '../../domain/repositories/vocab_repository.dart';

/// Sổ từ giả trong bộ nhớ (`--dart-define=WEEKLY_DOCS_FAKE=true`, test). Trùng từ trong cùng sổ trả lỗi như BE.
class FakeVocabRepository implements VocabRepository {
  final entries = <VocabEntry>[];

  static String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  VocabEntry? _find(String text, String deck, {String? exceptId}) {
    for (final e in entries) {
      if (e.id != exceptId && e.deck == deck && _norm(e.text) == _norm(text)) return e;
    }
    return null;
  }

  @override
  Future<Result<List<VocabEntry>>> list({String? deck, String? query}) async {
    final q = query?.trim().toLowerCase() ?? '';
    return Success([
      for (final e in entries.reversed)
        if ((deck == null || e.deck == deck) && (q.isEmpty || e.text.toLowerCase().contains(q) || e.meaning.toLowerCase().contains(q))) e,
    ]);
  }

  @override
  Future<Result<VocabEntry>> add(NewVocab v) async {
    final existing = _find(v.text, v.deck);
    if (existing != null) return Failure(VocabExistsException('Từ này đã có trong sổ.', existing: existing));
    final entry = VocabEntry(
      id: uuidV4(), // như BE: Sổ từ dựa vào id dạng UUID để biết từ đã lên máy chủ
      text: v.text.trim(),
      meaning: v.meaning,
      ipa: v.ipa,
      example: v.example,
      partOfSpeech: v.partOfSpeech,
      deck: v.deck,
      sourceDocId: v.sourceDocId,
      sourceBlockKey: v.sourceBlockKey,
      createdAt: DateTime.now(),
    );
    entries.add(entry);
    return Success(entry);
  }

  @override
  Future<Result<VocabEntry>> update(String id, {String? text, String? meaning, String? example, String? deck, String? partOfSpeech}) async {
    final i = entries.indexWhere((e) => e.id == id);
    if (i < 0) return const Failure(ServerException('Không tìm thấy từ này.', code: 'VOCAB_NOT_FOUND', statusCode: 404));
    final old = entries[i];
    final next = VocabEntry(
      id: id,
      text: text ?? old.text,
      meaning: meaning ?? old.meaning,
      ipa: old.ipa,
      example: example ?? old.example,
      partOfSpeech: partOfSpeech ?? old.partOfSpeech,
      deck: deck ?? old.deck,
      sourceDocId: old.sourceDocId,
      sourceBlockKey: old.sourceBlockKey,
      createdAt: old.createdAt,
    );
    final clash = _find(next.text, next.deck, exceptId: id);
    if (clash != null) return Failure(VocabExistsException('Từ này đã có trong sổ.', existing: clash));
    entries[i] = next;
    return Success(next);
  }

  @override
  Future<Result<void>> delete(String id) async {
    entries.removeWhere((e) => e.id == id);
    return const Success(null);
  }

  @override
  Future<Result<bool>> exists(String text) async => Success(entries.any((e) => _norm(e.text) == _norm(text)));

  @override
  Future<Result<List<String>>> decks() async => Success({for (final e in entries.reversed) e.deck, defaultVocabDeck}.toList());
}
