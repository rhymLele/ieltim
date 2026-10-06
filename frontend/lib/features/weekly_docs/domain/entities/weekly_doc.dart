// weekly_doc.dart — Model tài liệu theo tuần (schemaVersion 1).
// Parse an toàn: type lạ → UnknownBlock, không bao giờ throw.

import 'doc_category.dart';

export 'doc_category.dart';

enum DocViewMode {
  slide,
  doc;

  static DocViewMode parse(Object? v) => v == 'doc' ? DocViewMode.doc : DocViewMode.slide;
}

String _s(Object? v) => v is String ? v : (v == null ? '' : v.toString());
String? _sOrNull(Object? v) => v is String && v.isNotEmpty ? v : null;
List<String> _strList(Object? v) => v is List ? v.map(_s).toList() : const <String>[];
Map<String, dynamic> asJsonMap(Object? v) =>
    v is Map ? v.map((k, val) => MapEntry(k.toString(), val)) : <String, dynamic>{};
int _int(Object? v, [int fallback = 0]) => v is int ? v : (v is num ? v.toInt() : int.tryParse(_s(v)) ?? fallback);

class DocMeta {
  const DocMeta({
    this.skill = 'reading',
    this.defaultView = DocViewMode.slide,
    this.allowedViews = const [DocViewMode.slide, DocViewMode.doc],
  });

  factory DocMeta.fromJson(Object? json) {
    final j = asJsonMap(json);
    final views = j['allowedViews'] is List ? (j['allowedViews'] as List).map(DocViewMode.parse).toSet().toList() : <DocViewMode>[];
    final def = DocViewMode.parse(j['defaultView']);
    return DocMeta(
      skill: _sOrNull(j['skill']) ?? 'reading',
      defaultView: def,
      allowedViews: views.isEmpty ? const [DocViewMode.slide, DocViewMode.doc] : views,
    );
  }

  final String skill;
  final DocViewMode defaultView;
  final List<DocViewMode> allowedViews;

  bool get canSwitch => allowedViews.contains(DocViewMode.slide) && allowedViews.contains(DocViewMode.doc);

  Map<String, dynamic> toJson() => {
        'skill': skill,
        'defaultView': defaultView.name,
        'allowedViews': allowedViews.map((v) => v.name).toList(),
      };
}

class WeeklyDoc {
  const WeeklyDoc({
    this.schemaVersion = 1,
    required this.id,
    required this.week,
    required this.order,
    this.category = DocCategory.lesson,
    required this.title,
    this.template = 'custom',
    this.meta = const DocMeta(),
    required this.sections,
    this.html,
    this.htmlFileName,
  });

  factory WeeklyDoc.fromJson(Object? json) {
    final j = asJsonMap(json);
    final sections = j['sections'] is List ? (j['sections'] as List).map(DocSection.fromJson).toList() : <DocSection>[];
    return WeeklyDoc(
      schemaVersion: _int(j['schemaVersion'], 1),
      id: _s(j['id']),
      week: _int(j['week']),
      order: _int(j['order']),
      category: DocCategory.parse(j['category']),
      title: _s(j['title']),
      template: _sOrNull(j['template']) ?? 'custom',
      meta: DocMeta.fromJson(j['meta']),
      sections: sections,
      html: _sOrNull(j['html']),
      htmlFileName: _sOrNull(j['htmlFileName']),
    );
  }

  final int schemaVersion;
  final String id;
  final int week;
  final int order;
  final DocCategory category;
  final String title;
  final String template;
  final DocMeta meta;
  final List<DocSection> sections;
  final String? html;
  final String? htmlFileName;

  bool get isHtml => template == 'html';

  /// "Tài liệu 1" / "Bài tập 1".
  String get numberLabel => '${category.label} $order';

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'week': week,
        'order': order,
        'category': category.name,
        'title': title,
        'template': template,
        'meta': meta.toJson(),
        'sections': sections.map((s) => s.toJson()).toList(),
        if (html != null) 'html': html,
        if (htmlFileName != null) 'htmlFileName': htmlFileName,
      };

  /// Số phút đọc ước tính: số từ / 180 + 1 phút mỗi quiz, tối thiểu 1.
  int get estimatedMinutes {
    var words = 0;
    var quizzes = 0;
    for (final s in sections) {
      for (final b in s.blocks) {
        words += b.plainText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        if (b is QuizBlock) quizzes++;
      }
    }
    final m = (words / 180).ceil() + quizzes;
    return m < 1 ? 1 : m;
  }

  List<VocabItem> get allVocab => [
        for (final s in sections)
          for (final b in s.blocks)
            if (b is VocabBlock) ...b.items,
      ];
}

class DocSection {
  const DocSection({required this.title, required this.blocks});

  factory DocSection.fromJson(Object? json) {
    final j = asJsonMap(json);
    final blocks = j['blocks'] is List ? (j['blocks'] as List).map((b) => DocBlock.fromJson(asJsonMap(b))).toList() : <DocBlock>[];
    return DocSection(title: _s(j['title']), blocks: blocks);
  }

  final String title;
  final List<DocBlock> blocks;

  Map<String, dynamic> toJson() => {'title': title, 'blocks': blocks.map((b) => b.toJson()).toList()};
}

// ───────────────────────────── Blocks ─────────────────────────────

sealed class DocBlock {
  const DocBlock({this.id});

  final String? id;

  String get type;

  /// Chữ thô để đếm từ / hiện đoạn trích.
  String get plainText;

  Map<String, dynamic> toJson();

  Map<String, dynamic> base() => {'type': type, if (id != null) 'id': id};

  static DocBlock fromJson(Map<String, dynamic> j) {
    final id = _sOrNull(j['id']);
    switch (j['type']) {
      case 'heading':
        return HeadingBlock(text: _s(j['text']), id: id);
      case 'paragraph':
        return ParagraphBlock(text: _s(j['text']), id: id);
      case 'callout':
        return CalloutBlock(text: _s(j['text']), tone: _sOrNull(j['tone']) ?? 'tip', id: id);
      case 'steps':
        return StepsBlock(items: _strList(j['items']), id: id);
      case 'passage':
        return PassageBlock(text: _s(j['text']), label: _sOrNull(j['label']), id: id);
      case 'quiz':
        return QuizBlock(
          question: _s(j['question']),
          options: _strList(j['options']),
          answer: _int(j['answer']),
          explain: _sOrNull(j['explain']),
          id: id,
        );
      case 'vocab':
        final items = j['items'] is List ? (j['items'] as List).map((e) => VocabItem.fromJson(asJsonMap(e))).toList() : <VocabItem>[];
        return VocabBlock(items: items, id: id);
      case 'pattern':
        return PatternBlock(structure: _s(j['structure']), example: _sOrNull(j['example']), id: id);
      case 'image':
        return ImageBlock(url: _s(j['url']), caption: _sOrNull(j['caption']), alt: _sOrNull(j['alt']), id: id);
      case 'slideBreak':
        return SlideBreakBlock(id: id);
      default:
        return UnknownBlock(raw: j, id: id);
    }
  }
}

class HeadingBlock extends DocBlock {
  const HeadingBlock({required this.text, super.id});
  final String text;
  @override
  String get type => 'heading';
  @override
  String get plainText => text;
  @override
  Map<String, dynamic> toJson() => {...base(), 'text': text};
}

class ParagraphBlock extends DocBlock {
  const ParagraphBlock({required this.text, super.id});
  final String text;
  @override
  String get type => 'paragraph';
  @override
  String get plainText => text.replaceAll('**', '').replaceAll('*', '');
  @override
  Map<String, dynamic> toJson() => {...base(), 'text': text};
}

class CalloutBlock extends DocBlock {
  const CalloutBlock({required this.text, this.tone = 'tip', super.id});
  final String text;
  final String tone;
  @override
  String get type => 'callout';
  @override
  String get plainText => text;
  @override
  Map<String, dynamic> toJson() => {...base(), 'tone': tone, 'text': text};
}

class StepsBlock extends DocBlock {
  const StepsBlock({required this.items, super.id});
  final List<String> items;
  @override
  String get type => 'steps';
  @override
  String get plainText => items.join(' ');
  @override
  Map<String, dynamic> toJson() => {...base(), 'items': items};
}

class PassageBlock extends DocBlock {
  const PassageBlock({required this.text, this.label, super.id});
  final String text;
  final String? label;
  @override
  String get type => 'passage';
  @override
  String get plainText => text;
  @override
  Map<String, dynamic> toJson() => {...base(), if (label != null) 'label': label, 'text': text};
}

class QuizBlock extends DocBlock {
  const QuizBlock({required this.question, required this.options, required this.answer, this.explain, super.id});
  final String question;
  final List<String> options;
  final int answer;
  final String? explain;
  @override
  String get type => 'quiz';
  @override
  String get plainText => [question, ...options].join(' ');
  @override
  Map<String, dynamic> toJson() => {...base(), 'question': question, 'options': options, 'answer': answer, if (explain != null) 'explain': explain};
}

class VocabItem {
  const VocabItem({required this.word, required this.meaning, this.pos, this.ipa, this.example});

  factory VocabItem.fromJson(Map<String, dynamic> j) => VocabItem(
        word: _s(j['word']),
        meaning: _s(j['meaning']),
        pos: _sOrNull(j['pos']),
        ipa: _sOrNull(j['ipa']),
        example: _sOrNull(j['example']),
      );

  final String word;
  final String meaning;
  final String? pos;
  final String? ipa;
  final String? example;

  Map<String, dynamic> toJson() => {
        'word': word,
        if (pos != null) 'pos': pos,
        if (ipa != null) 'ipa': ipa,
        'meaning': meaning,
        if (example != null) 'example': example,
      };
}

class VocabBlock extends DocBlock {
  const VocabBlock({required this.items, super.id});
  final List<VocabItem> items;
  @override
  String get type => 'vocab';
  @override
  String get plainText => items.map((i) => '${i.word} ${i.meaning}').join(' ');
  @override
  Map<String, dynamic> toJson() => {...base(), 'items': items.map((i) => i.toJson()).toList()};
}

class PatternBlock extends DocBlock {
  const PatternBlock({required this.structure, this.example, super.id});
  final String structure;
  final String? example;
  @override
  String get type => 'pattern';
  @override
  String get plainText => '$structure ${example ?? ''}';
  @override
  Map<String, dynamic> toJson() => {...base(), 'structure': structure, if (example != null) 'example': example};
}

class ImageBlock extends DocBlock {
  const ImageBlock({required this.url, this.caption, this.alt, super.id});
  final String url;
  final String? caption;
  final String? alt;
  @override
  String get type => 'image';
  @override
  String get plainText => caption ?? '';
  @override
  Map<String, dynamic> toJson() => {...base(), 'url': url, if (caption != null) 'caption': caption, if (alt != null) 'alt': alt};
}

class SlideBreakBlock extends DocBlock {
  const SlideBreakBlock({super.id});
  @override
  String get type => 'slideBreak';
  @override
  String get plainText => '';
  @override
  Map<String, dynamic> toJson() => base();
}

class UnknownBlock extends DocBlock {
  const UnknownBlock({required this.raw, super.id});
  final Map<String, dynamic> raw;
  @override
  String get type => _s(raw['type']);
  @override
  String get plainText => '';
  @override
  Map<String, dynamic> toJson() => raw;
}

// ───────────────────────────── Helpers ─────────────────────────────

/// Khoá ổn định của một khối: dùng `id` nếu có, không thì "section-block".
String blockKey(int sectionIndex, int blockIndex, DocBlock block) => block.id ?? '$sectionIndex-$blockIndex';

/// Một trang slide: thuộc section nào và gồm những khối nào (kèm chỉ số gốc).
class SlidePage {
  const SlidePage({required this.sectionIndex, required this.title, required this.blocks, required this.partIndex});
  final int sectionIndex;
  final String title;

  /// Phần thứ mấy của section khi bị tách bởi slideBreak (0 = phần đầu).
  final int partIndex;
  final List<(int, DocBlock)> blocks;
}

/// Tách tài liệu thành các slide: mỗi section một slide, cắt thêm tại `slideBreak`.
List<SlidePage> buildSlides(WeeklyDoc doc) {
  final pages = <SlidePage>[];
  for (var si = 0; si < doc.sections.length; si++) {
    final s = doc.sections[si];
    var part = 0;
    var current = <(int, DocBlock)>[];
    for (var bi = 0; bi < s.blocks.length; bi++) {
      final b = s.blocks[bi];
      if (b is SlideBreakBlock) {
        if (current.isNotEmpty) {
          pages.add(SlidePage(sectionIndex: si, title: s.title, blocks: current, partIndex: part++));
          current = <(int, DocBlock)>[];
        }
        continue;
      }
      current.add((bi, b));
    }
    if (current.isNotEmpty || part == 0) {
      pages.add(SlidePage(sectionIndex: si, title: s.title, blocks: current, partIndex: part));
    }
  }
  return pages;
}

const blockTypeLabels = <String, String>{
  'heading': 'Tiêu đề',
  'paragraph': 'Đoạn văn',
  'callout': 'Mẹo',
  'steps': 'Các bước',
  'passage': 'Đoạn đề',
  'quiz': 'Trắc nghiệm',
  'vocab': 'Từ vựng',
  'pattern': 'Mẫu câu',
  'image': 'Ảnh',
  'slideBreak': 'Ngắt slide',
};

const skillLabels = <String, String>{
  'reading': 'Reading',
  'listening': 'Listening',
  'writing': 'Writing',
  'speaking': 'Speaking',
  'vocabulary': 'Vocabulary',
};

const romanKeys = ['i', 'ii', 'iii', 'iv', 'v', 'vi'];
