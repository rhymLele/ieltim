import 'models/weekly_doc.dart';

/// Parse tài liệu từ JSON thô.
///
/// Gặp `type` lạ → [DocBlock.unknown] (giữ nguyên JSON gốc), **không throw**.
/// Dữ liệu thiếu / lệch kiểu được gán giá trị an toàn (mặc định rỗng).
WeeklyDoc parseWeeklyDoc(Map<String, dynamic> json) {
  final metaJson = _asMap(json['meta']) ?? <String, dynamic>{};
  final sectionsJson = (json['sections'] as List? ?? const []);
  final sections = <DocSection>[];
  for (var i = 0; i < sectionsJson.length; i++) {
    final sj = _asMap(sectionsJson[i]) ?? <String, dynamic>{};
    final blocksJson = (sj['blocks'] as List? ?? const []);
    final blocks = <DocBlock>[];
    for (final b in blocksJson) {
      final bj = _asMap(b);
      if (bj == null) continue;
      blocks.add(parseDocBlock(bj));
    }
    sections.add(DocSection(
      id: sj['id']?.toString(),
      number: _int(sj['number']) ?? (i + 1),
      title: _text(sj['title']),
      blocks: blocks,
    ));
  }
  final id = json['id']?.toString() ?? metaJson['id']?.toString() ?? 'doc';
  return WeeklyDoc(id: id, meta: DocMeta.fromJson(metaJson), sections: sections);
}

/// Parse một khối. Type lạ → [DocBlock.unknown].
DocBlock parseDocBlock(Map<String, dynamic> json) {
  final type = _text(json['type']);
  final id = json['id']?.toString();
  switch (type) {
    case 'heading':
      return DocBlock.heading(id: id, text: _text(json['text']));
    case 'paragraph':
      return DocBlock.paragraph(id: id, text: _text(json['text']));
    case 'callout':
      return DocBlock.callout(id: id, text: _text(json['text']));
    case 'steps':
      return DocBlock.steps(
          id: id,
          items:
              _strList(json['items']) ?? _strList(json['steps']) ?? const []);
    case 'passage':
      return DocBlock.passage(
          id: id, label: _text(json['label']), text: _text(json['text']));
    case 'quiz':
      return DocBlock.quiz(
        id: id,
        question: _text(json['question']),
        options:
            _strList(json['options']) ?? _strList(json['answers']) ?? const [],
        correctIndex:
            _int(json['correctIndex']) ?? _int(json['correct']) ?? 0,
        explanation: _text(json['explanation']),
      );
    case 'vocab':
      return DocBlock.vocab(id: id, items: _vocabList(json['items']));
    case 'pattern':
      return DocBlock.pattern(id: id, text: _text(json['text']));
    case 'image':
      return DocBlock.image(
          id: id, url: _text(json['url']), alt: _text(json['alt']));
    case 'slideBreak':
      return DocBlock.slideBreak(id: id);
    default:
      return DocBlock.unknown(
          id: id, type: type, raw: Map<String, dynamic>.from(json));
  }
}

// ─── toMap (admin lưu / export) ─────────────────────────────────────────────

Map<String, dynamic> weeklyDocToMap(WeeklyDoc doc) => {
      'id': doc.id,
      'meta': docMetaToMap(doc.meta),
      'sections': doc.sections.map(docSectionToMap).toList(),
    };

Map<String, dynamic> docMetaToMap(DocMeta m) => {
      'title': m.title,
      'week': m.week,
      'order': m.order,
      'skills': m.skills,
      'estimatedMinutes': m.estimatedMinutes,
      'status': m.status.name,
      'defaultView': m.defaultView.name,
      'allowedViews': m.allowedViews.map((e) => e.name).toList(),
      'allowUserSwitchView': m.allowUserSwitchView,
      'publishAt': m.publishAt,
      'id': m.id,
      'version': m.version,
      'createdAt': m.createdAt,
      'updatedAt': m.updatedAt,
    };

Map<String, dynamic> docSectionToMap(DocSection s) => {
      'id': s.id,
      'number': s.number,
      'title': s.title,
      'blocks': s.blocks.map(blockToMap).toList(),
    };

Map<String, dynamic> blockToMap(DocBlock b) => b.when(
      heading: (id, text) => _omitNull({'type': 'heading', 'id': id, 'text': text}),
      paragraph: (id, text) => _omitNull({'type': 'paragraph', 'id': id, 'text': text}),
      callout: (id, text) => _omitNull({'type': 'callout', 'id': id, 'text': text}),
      steps: (id, items) => _omitNull({'type': 'steps', 'id': id, 'items': items}),
      passage: (id, label, text) =>
          _omitNull({'type': 'passage', 'id': id, 'label': label, 'text': text}),
      quiz: (id, question, options, correctIndex, explanation) => _omitNull({
        'type': 'quiz',
        'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      }),
      vocab: (id, items) => _omitNull({
        'type': 'vocab',
        'id': id,
        'items': items.map(vocabItemToMap).toList(),
      }),
      pattern: (id, text) => _omitNull({'type': 'pattern', 'id': id, 'text': text}),
      image: (id, url, alt) => _omitNull({'type': 'image', 'id': id, 'url': url, 'alt': alt}),
      slideBreak: (id) => _omitNull({'type': 'slideBreak', 'id': id}),
      // UnknownBlock giữ nguyên JSON gốc.
      unknown: (id, type, raw) => {...raw, 'id': id},
    );

Map<String, dynamic> vocabItemToMap(VocabItem v) => {
      'word': v.word,
      'partOfSpeech': v.partOfSpeech,
      'ipa': v.ipa,
      'meaning': v.meaning,
    };

// ─── helpers ────────────────────────────────────────────────────────────────

Map<String, dynamic>? _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

String _text(dynamic v) => v?.toString() ?? '';

int? _int(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

List<String>? _strList(dynamic v) {
  if (v is! List) return null;
  final out = <String>[];
  for (final e in v) {
    final s = e?.toString() ?? '';
    if (s.trim().isNotEmpty) out.add(s);
  }
  return out;
}

List<VocabItem> _vocabList(dynamic v) {
  if (v is! List) return const [];
  final out = <VocabItem>[];
  for (final e in v) {
    final m = _asMap(e);
    if (m == null) continue;
    out.add(VocabItem(
      word: _text(m['word']),
      partOfSpeech: _text(m['partOfSpeech']),
      ipa: _text(m['ipa']),
      meaning: _text(m['meaning']),
    ));
  }
  return out;
}

Map<String, dynamic> _omitNull(Map<String, dynamic> m) {
  m.removeWhere((_, v) => v == null);
  return m;
}
