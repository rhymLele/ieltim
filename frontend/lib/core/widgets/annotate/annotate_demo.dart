// annotate_demo.dart — Chạy thử:
//   import 'annotate/annotate_demo.dart';
//   void main() => runApp(const AnnotateDemoApp());
// Dữ liệu và dịch nghĩa là GIẢ, chỉ để xem UI. Logic thật: xem 11_prompt_logic_boi_den_ghi_chu.md
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'annotate.dart';

class AnnotateDemoApp extends StatelessWidget {
  const AnnotateDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: AnnColors.primary, scaffoldBackgroundColor: AnnColors.background),
        home: const _DemoReader(),
      );
}

const _paras = [
  'Cities are often several degrees warmer than the surrounding countryside, a phenomenon known as the urban heat island effect. Dark roofs and roads absorb sunlight during the day and release it slowly at night.',
  'To mitigate this problem, planners are turning to green roofs, reflective pavements and more trees. These measures not only lower temperatures but also reduce carbon emissions from air conditioning.',
  'However, critics argue that such projects are expensive and benefit wealthy neighbourhoods first. An unprecedented heatwave in 2023 showed that poorer districts remain the most vulnerable.',
];

const _dict = {
  'mitigate': ('/ˈmɪtɪɡeɪt/', 'động từ', 'giảm nhẹ, làm dịu bớt'),
  'carbon emissions': ('/ˈkɑːbən ɪˈmɪʃnz/', 'cụm danh từ', 'khí thải carbon'),
  'urban heat island effect': ('/ˈɜːbən hiːt ˈaɪlənd ɪˈfekt/', 'cụm danh từ', 'hiệu ứng đảo nhiệt đô thị'),
  'unprecedented': ('/ʌnˈpresɪdentɪd/', 'tính từ', 'chưa từng có'),
  'vulnerable': ('/ˈvʌlnərəbl/', 'tính từ', 'dễ bị tổn thương'),
};

class _DemoReader extends StatefulWidget {
  const _DemoReader();
  @override
  State<_DemoReader> createState() => _DemoReaderState();
}

class _DemoReaderState extends State<_DemoReader> {
  bool _slide = false;
  final _vocab = <VocabDraft>[];
  final _highlights = <TextHighlight>[
    const TextHighlight(id: 'h1', blockKey: 'p0', quote: 'urban heat island effect', color: HighlightColor.yellow),
  ];
  late final _ann = AnnotationController(
    onChanged: (d) => debugPrint('TODO lưu ghi chú slide: ${d.toJson()}'),
    initial: SlideAnnotations(
      ellipses: [EllipseMark(id: 'e1', rect: const Rect.fromLTWH(0.33, 0.3, 0.34, 0.36), color: kPenColors[1])],
      pins: [PinNote(id: 'p1', at: const Offset(0.83, 0.6), text: 'deplete ≈ use up', createdAt: DateTime.now())],
    ),
  )..tool = AnnotationTool.pen;

  @override
  void dispose() {
    _ann.dispose();
    super.dispose();
  }

  String _clean(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z\s-]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  ({int para, int start})? _locate(String quote) {
    for (var i = 0; i < _paras.length; i++) {
      final k = _paras[i].indexOf(quote);
      if (k >= 0) return (para: i, start: k);
    }
    return null;
  }

  String? _sentenceOf(String quote) {
    final loc = _locate(quote);
    if (loc == null) return null;
    final sentences = RegExp(r'[^.!?]+[.!?]').allMatches(_paras[loc.para]).map((m) => m.group(0)!.trim());
    return sentences.firstWhere((s) => s.contains(quote), orElse: () => _paras[loc.para]);
  }

  TextHighlight? _existing(String quote) {
    for (final h in _highlights) {
      if (h.quote == quote) return h;
    }
    return null;
  }

  void _highlight(String quote, HighlightColor color, VoidCallback close) {
    final loc = _locate(quote);
    if (loc == null) {
      close();
      return;
    }
    final p = _paras[loc.para];
    setState(() {
      _highlights.removeWhere((h) => h.quote == quote);
      _highlights.add(TextHighlight(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        blockKey: 'p${loc.para}',
        quote: quote,
        prefix: p.substring((loc.start - 30).clamp(0, p.length), loc.start),
        suffix: p.substring(loc.start + quote.length, (loc.start + quote.length + 30).clamp(0, p.length)),
        start: loc.start,
        end: loc.start + quote.length,
        color: color,
      ));
    });
    close();
  }

  Future<void> _addVocab(String text, VoidCallback close) async {
    close();
    final d = _dict[_clean(text)];
    final draft = await showVocabSheet(
      context,
      text: text,
      ipa: d?.$1,
      suggestedMeaning: d?.$3,
      example: _sentenceOf(text),
      decks: const ['Tuần 12', 'Môi trường', 'Sổ chung'],
    );
    if (draft == null || !mounted) return;
    setState(() => _vocab.insert(0, draft));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm "${draft.text}" vào Sổ từ · ${draft.deck}')));
  }

  Widget _card(BuildContext context, String text, VoidCallback close) {
    final existing = _existing(text);
    return SelectionActionsCard(
      text: text,
      alreadyInVocab: _vocab.any((v) => _clean(v.text) == _clean(text)),
      currentHighlight: existing?.color,
      onAddVocab: () => _addVocab(text, close),
      onTranslate: () async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final d = _dict[_clean(text)];
        return TranslationResult(
          text: text,
          ipa: d?.$1,
          partOfSpeech: d?.$2,
          meaning: d?.$3 ?? '(Bản thật: gọi API dịch)',
          sentenceTranslation: 'Bản dịch cả câu do API / AI trả về.',
        );
      },
      onHighlight: (c) => _highlight(text, c, close),
      onRemoveHighlight: existing == null
          ? null
          : () {
              setState(() => _highlights.remove(existing));
              close();
            },
      onSpeak: () => debugPrint('TODO: TTS "$text"'),
      onCopy: () {
        Clipboard.setData(ClipboardData(text: text));
        close();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading: Climate & the City'),
        actions: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Doc'), icon: Icon(Icons.article_outlined)),
              ButtonSegment(value: true, label: Text('Slide'), icon: Icon(Icons.slideshow_outlined)),
            ],
            selected: {_slide},
            onSelectionChanged: (s) => setState(() => _slide = s.first),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          Expanded(child: _slide ? _slideView(wide) : _docView()),
          if (wide)
            SizedBox(
              width: 320,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: AnnColors.border))),
                child: _slide ? NotesPanel(controller: _ann) : _sidePanel(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _docView() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: AnnotatableSelectionArea(
            cardBuilder: _card,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Can cities cool themselves?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                for (var i = 0; i < _paras.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: HighlightedText(
                      _paras[i],
                      highlights: _highlights.where((h) => h.blockKey == 'p$i').toList(),
                      style: const TextStyle(fontFamily: 'Georgia', fontSize: 18, height: 1.8, color: AnnColors.text),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _sidePanel() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('HIGHLIGHT · ${_highlights.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AnnColors.textMuted)),
          for (final h in _highlights)
            ListTile(dense: true, leading: CircleAvatar(radius: 6, backgroundColor: h.color.color), title: Text(h.quote)),
          const SizedBox(height: 12),
          Text('SỔ TỪ · ${_vocab.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AnnColors.textMuted)),
          for (final v in _vocab) ListTile(dense: true, title: Text(v.text), subtitle: Text('${v.meaning} · ${v.deck}')),
        ],
      );

  Widget _slideView(bool wide) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: Center(child: AnnotationToolbar(controller: _ann, compact: !wide))),
                if (!wide)
                  IconButton(
                    tooltip: 'Ghi chú',
                    icon: const Icon(Icons.sticky_note_2_outlined),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => SizedBox(height: MediaQuery.sizeOf(context).height * 0.6, child: NotesPanel(controller: _ann)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AnnotationLayer(controller: _ann, child: const _DemoSlide()),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _DemoSlide extends StatelessWidget {
  const _DemoSlide();

  @override
  Widget build(BuildContext context) => Container(
        color: AnnColors.background,
        padding: const EdgeInsets.all(28),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NHÓM 1 · ĐỘNG TỪ + DANH TỪ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: AnnColors.textMuted)),
            SizedBox(height: 8),
            Text('Hành động với môi trường', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Card('curb emissions', 'Governments must curb emissions from heavy industry.'),
                  SizedBox(width: 12),
                  _Card('deplete resources', 'Overfishing has depleted marine resources.'),
                  SizedBox(width: 12),
                  _Card('raise awareness', 'Campaigns can raise awareness of plastic waste.'),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card(this.phrase, this.example);
  final String phrase;
  final String example;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AnnColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AnnColors.primary, borderRadius: BorderRadius.circular(99)),
                child: Text(phrase, style: const TextStyle(color: AnnColors.onPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              const SizedBox(height: 8),
              Text(example, style: const TextStyle(fontSize: 13, height: 1.5, fontStyle: FontStyle.italic, color: AnnColors.textMuted)),
            ],
          ),
        ),
      );
}
