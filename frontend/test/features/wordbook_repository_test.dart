import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/app_exception.dart';
import 'package:frontend/core/errors/result.dart';
import 'package:frontend/features/vocab/data/repositories/fake_vocab_repository.dart';
import 'package:frontend/features/vocab/domain/entities/vocab_entry.dart';
import 'package:frontend/features/vocab/domain/repositories/vocab_repository.dart';
import 'package:frontend/features/wordbook/presentation/bloc/wordbook_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BE Sổ từ giả, bật [offline] để giả lập mất mạng.
class _Remote implements VocabRepository {
  final fake = FakeVocabRepository();
  bool offline = false;
  int adds = 0;

  Result<T> _down<T>() => Failure<T>(const NetworkException());

  @override
  Future<Result<List<VocabEntry>>> list({String? deck, String? query}) async => offline ? _down() : fake.list(deck: deck, query: query);

  @override
  Future<Result<VocabEntry>> add(NewVocab vocab) async {
    if (offline) return _down();
    adds++;
    return fake.add(vocab);
  }

  @override
  Future<Result<VocabEntry>> update(String id, {String? text, String? meaning, String? example, String? deck, String? partOfSpeech}) async =>
      offline ? _down() : fake.update(id, text: text, meaning: meaning, example: example, deck: deck, partOfSpeech: partOfSpeech);

  @override
  Future<Result<void>> delete(String id) async => offline ? _down() : fake.delete(id);

  @override
  Future<Result<bool>> exists(String text) => fake.exists(text);

  @override
  Future<Result<List<String>>> decks() => fake.decks();
}

LocalWordbookItem _item(String id, String word, {String? tag, String? meaning}) => LocalWordbookItem(
      id: id,
      word: word,
      meaning: meaning,
      tag: tag,
      sourceReferenceType: SourceType.manual,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );

void main() {
  late _Remote remote;

  setUp(() {
    remote = _Remote();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> seedLegacy(List<LocalWordbookItem> items) async {
    SharedPreferences.setMockInitialValues({'local_wordbook_items': jsonEncode([for (final i in items) i.toJson()])});
  }

  test('từ cũ chỉ có trên máy được đẩy lên BE một lần (giữ từ loại)', () async {
    await seedLegacy([_item('1725000000000', 'mitigate', tag: 'verb', meaning: 'giảm nhẹ'), _item('1725000000001', 'yield')]);
    final repo = WordbookRepository(remote: remote);

    final items = await repo.getAll();
    expect(items.map((i) => i.word).toSet(), {'mitigate', 'yield'});
    expect(items.firstWhere((i) => i.word == 'mitigate').tag, 'verb');
    expect(items.every((i) => RegExp(r'^[0-9a-f-]{36}$').hasMatch(i.id)), isTrue, reason: 'id do BE cấp');
    expect(remote.fake.entries.firstWhere((e) => e.text == 'yield').deck, defaultVocabDeck);

    await repo.getAll();
    expect(remote.adds, 2, reason: 'không đẩy lại lần hai');
  });

  test('mất mạng khi đẩy từ cũ: giữ trên máy, lần sau đẩy tiếp', () async {
    await seedLegacy([_item('1725000000000', 'mitigate')]);
    remote.offline = true;
    final repo = WordbookRepository(remote: remote);
    expect((await repo.getAll()).single.word, 'mitigate');

    remote.offline = false;
    final items = await repo.getAll();
    expect(items.single.word, 'mitigate');
    expect(remote.fake.entries, hasLength(1));
  });

  test('thêm / sửa / xoá đi qua BE; mất mạng vẫn mở được bản đã tải', () async {
    final repo = WordbookRepository(remote: remote);
    await repo.save(_item('draft', 'vulnerable', tag: 'adjective', meaning: 'dễ tổn thương'));
    final saved = (await repo.getAll()).single;
    expect((saved.tag, saved.deck), ('adjective', defaultVocabDeck));

    await repo.save(_item(saved.id, 'vulnerable', tag: 'academic', meaning: 'dễ bị tổn thương'));
    final updated = (await repo.getAll()).single;
    expect((updated.id, updated.tag, updated.meaning), (saved.id, 'academic', 'dễ bị tổn thương'));

    remote.offline = true;
    expect((await repo.getAll()).single.word, 'vulnerable');
    expect((await repo.search('tổn')).single.word, 'vulnerable');
    await expectLater(repo.save(_item('draft2', 'yield')), throwsA(isA<NetworkException>()));

    remote.offline = false;
    await repo.delete(saved.id);
    expect(await repo.getAll(), isEmpty);
  });

  test('sửa từ không còn trên BE (xoá ở máy khác) → thêm mới', () async {
    final repo = WordbookRepository(remote: remote);
    await repo.save(_item('0e9c2a52-3f1d-4c5e-9a7b-2d1f0c8e4b6a', 'mitigate'));
    expect((await repo.getAll()).single.word, 'mitigate');
  });

  test('bloc: thêm từ trùng → báo "Từ này đã có trong Sổ từ"', () async {
    final bloc = WordbookBloc(repository: WordbookRepository(remote: remote));
    addTearDown(bloc.close);
    bloc.add(AddWord(_item('a', 'mitigate')));
    await bloc.stream.firstWhere((s) => s.items.length == 1);
    bloc.add(AddWord(_item('b', 'Mitigate')));
    final state = await bloc.stream.firstWhere((s) => s.error != null);
    expect(state.error, 'Từ này đã có trong Sổ từ');
    expect(state.errorId, 1);
  });

  test('chưa có BE (test / máy chưa cấu hình) → chỉ lưu trên máy như trước', () async {
    final repo = WordbookRepository();
    await repo.save(_item('local-1', 'yield'));
    expect((await repo.getAll()).single.id, 'local-1');
  });
}
