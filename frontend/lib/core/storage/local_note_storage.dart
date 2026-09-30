import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNote {
  final int id;
  final String referenceId;
  final String referenceType;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalNote({
    required this.id,
    required this.referenceId,
    required this.referenceType,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'reference_id': referenceId,
        'reference_type': referenceType,
        'title': title,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory LocalNote.fromMap(Map<String, dynamic> map) => LocalNote(
        id: map['id'] as int,
        referenceId: map['reference_id'] as String? ?? '',
        referenceType: map['reference_type'] as String? ?? 'general',
        title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}

class LocalNoteStorage {
  static const _key = 'local_notes';
  static const _nextIdKey = 'local_notes_next_id';

  Future<List<LocalNote>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    return list
        .map(LocalNote.fromMap)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<LocalNote>> getNotesByReference(String referenceId) async {
    final all = await getAllNotes();
    return all.where((n) => n.referenceId == referenceId).toList();
  }

  Future<LocalNote> saveNote({
    required String referenceId,
    required String referenceType,
    required String title,
    required String content,
    int? id,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await _getNotesRaw(prefs);

    if (id != null) {
      final idx = notes.indexWhere((n) => n['id'] == id);
      if (idx != -1) {
        notes[idx]['title'] = title;
        notes[idx]['content'] = content;
        notes[idx]['updated_at'] = DateTime.now().toIso8601String();
        await prefs.setString(_key, jsonEncode(notes));
        return LocalNote.fromMap(notes[idx]);
      }
    }

    final nextId = prefs.getInt(_nextIdKey) ?? 1;
    final now = DateTime.now().toIso8601String();
    notes.add({
      'id': nextId,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'title': title,
      'content': content,
      'created_at': now,
      'updated_at': now,
    });
    await prefs.setInt(_nextIdKey, nextId + 1);
    await prefs.setString(_key, jsonEncode(notes));
    return LocalNote.fromMap(notes.last);
  }

  Future<void> deleteNote(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await _getNotesRaw(prefs);
    notes.removeWhere((n) => n['id'] == id);
    await prefs.setString(_key, jsonEncode(notes));
  }

  Future<List<Map<String, dynamic>>> _getNotesRaw(SharedPreferences prefs) async {
    final json = prefs.getString(_key);
    if (json == null) return [];
    return (jsonDecode(json) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
