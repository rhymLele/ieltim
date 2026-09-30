import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/wordbook/presentation/bloc/wordbook_bloc.dart';

const _primaryDark = Color(0xFF152238);
const _textSecondary = Color(0xFF4A5670);
const _inputBg = Color(0xFFF5F7F6);
const _border = Color(0x24152238);
const _delete = Color(0xFFD14840);
const _blueTag = Color(0xFF2451C7);
const _blueTagBg = Color(0xFFE8EEFB);

class WordbookPage extends StatefulWidget {
  const WordbookPage({super.key});

  @override
  State<WordbookPage> createState() => _WordbookPageState();
}

class _WordbookPageState extends State<WordbookPage> {
  final _wordController = TextEditingController();
  final _meaningController = TextEditingController();
  final _exampleController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedTag = 'general';
  String? _editingId;

  static const _tags = ['general', 'noun', 'verb', 'adjective', 'adverb', 'collocation', 'phrasal', 'idiom', 'academic'];

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addOrSaveWord() {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word is required'), backgroundColor: _delete),
      );
      return;
    }

    final bloc = context.read<WordbookBloc>();
    final now = DateTime.now();

    if (_editingId != null) {
      final existing = bloc.state.items.firstWhere((i) => i.id == _editingId);
      final updated = LocalWordbookItem(
        id: existing.id,
        word: word,
        meaning: _meaningController.text.trim().isEmpty ? null : _meaningController.text.trim(),
        example: _exampleController.text.trim().isEmpty ? null : _exampleController.text.trim(),
        tag: _selectedTag,
        sourceReferenceId: existing.sourceReferenceId,
        sourceReferenceType: existing.sourceReferenceType,
        collocations: existing.collocations,
        note: existing.note,
        level: existing.level,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
      bloc.add(AddWord(updated));
      _cancelEdit();
    } else {
      final item = LocalWordbookItem(
        id: '${now.microsecondsSinceEpoch}',
        word: word,
        meaning: _meaningController.text.trim().isEmpty ? null : _meaningController.text.trim(),
        example: _exampleController.text.trim().isEmpty ? null : _exampleController.text.trim(),
        tag: _selectedTag,
        sourceReferenceType: SourceType.manual,
        createdAt: now,
        updatedAt: now,
      );
      bloc.add(AddWord(item));
      _clearForm();
    }
  }

  void _clearForm() {
    _wordController.clear();
    _meaningController.clear();
    _exampleController.clear();
    _selectedTag = 'general';
  }

  void _cancelEdit() {
    setState(() => _editingId = null);
    _clearForm();
  }

  void _startEdit(LocalWordbookItem item) {
    setState(() {
      _editingId = item.id;
      _wordController.text = item.word;
      _meaningController.text = item.meaning ?? '';
      _exampleController.text = item.example ?? '';
      _selectedTag = item.tag ?? 'general';
    });
  }

  void _confirmDelete(LocalWordbookItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${item.word}"?', style: const TextStyle(color: _primaryDark, fontWeight: FontWeight.w600)),
        content: const Text('This will permanently remove the word from your wordbook.', style: TextStyle(color: _textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<WordbookBloc>().add(DeleteWord(item.id));
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: _delete, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJson() async {
    final items = context.read<WordbookBloc>().state.items;
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    final data = Uint8List.fromList(utf8.encode(json));
    await Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _importJson() async {
    final result = await fp.FilePicker.pickFiles();
    if (result.isEmpty) return;

    try {
      final file = result.single;
      final content = await file.xFile.readAsString();
      final list = jsonDecode(content) as List;
      final bloc = context.read<WordbookBloc>();
      final existing = bloc.state.items;
      int imported = 0;

      for (final e in list) {
        final item = LocalWordbookItem.fromJson(e as Map<String, dynamic>);
        if (!existing.any((x) => x.id == item.id) && !existing.any((x) => x.word == item.word)) {
          bloc.add(AddWord(item));
          imported++;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$imported words imported'), duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid JSON file'), backgroundColor: _delete),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildFormCard(),
            const SizedBox(height: 32),
            _buildSearchToolbar(),
            const SizedBox(height: 24),
            _buildWordList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sổ từ của tôi',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 52,
            fontWeight: FontWeight.w800,
            color: _primaryDark,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your personal wordbook — add any word you meet, from any source.',
          style: GoogleFonts.instrumentSans(
            fontSize: 16,
            color: _textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
            const SizedBox(width: 6),
            Text(
              'Saved in this browser (localStorage) — your words stay on this device.',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 12,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildField(
                  label: 'WORD / PHRASE *',
                  controller: _wordController,
                  placeholder: 'e.g. albeit',
                  isLarge: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('TAG'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTag,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          borderRadius: BorderRadius.circular(10),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          iconSize: 18,
                          style: const TextStyle(fontSize: 14, color: _primaryDark),
                          items: _tags
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedTag = v ?? 'general'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildField(
            label: 'MEANING / DEFINITION',
            controller: _meaningController,
            placeholder: 'English or Vietnamese — your choice',
          ),
          const SizedBox(height: 20),
          _buildField(
            label: 'EXAMPLE SENTENCE',
            controller: _exampleController,
            placeholder: 'Write your own example sentence...',
            isMultiline: true,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _PillButton(
                label: _editingId != null ? 'Save changes' : 'Add word',
                onPressed: _addOrSaveWord,
              ),
              if (_editingId != null) ...[
                const SizedBox(width: 12),
              ],
              if (_editingId != null)
                _PillOutlineButton(
                  label: 'Cancel edit',
                  onPressed: _cancelEdit,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool isMultiline = false,
    bool isLarge = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 0),
        _FieldLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: TextField(
            controller: controller,
            maxLines: isMultiline ? 3 : 1,
            style: GoogleFonts.instrumentSans(
              fontSize: isLarge ? 18 : 14,
              color: _primaryDark,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.instrumentSans(color: _textSecondary.withOpacity(0.6), fontSize: isLarge ? 16 : 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isLarge ? 16 : 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchToolbar() {
    return BlocBuilder<WordbookBloc, WordbookState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.instrumentSans(fontSize: 14, color: _primaryDark),
                  decoration: InputDecoration(
                    hintText: 'Search your words...',
                    hintStyle: GoogleFonts.instrumentSans(color: _textSecondary.withOpacity(0.6), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 18, color: _textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onChanged: (v) => context.read<WordbookBloc>().add(SearchWords(v)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _PillOutlineButton(label: 'Export JSON', onPressed: _exportJson),
            const SizedBox(width: 8),
            _PillOutlineButton(label: 'Import JSON', onPressed: _importJson),
            const SizedBox(width: 16),
            Text(
              '${state.items.length} / ${state.items.length} words',
              style: GoogleFonts.ibmPlexMono(fontSize: 12, color: _textSecondary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWordList() {
    return BlocBuilder<WordbookBloc, WordbookState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'No words yet. Add your first word above.',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
            ),
          );
        }
        return Column(
          children: state.items
              .map((item) => _WordCard(
                    item: item,
                    onEdit: () => _startEdit(item),
                    onDelete: () => _confirmDelete(item),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.ibmPlexMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PillButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _primaryDark,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: GoogleFonts.instrumentSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PillOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PillOutlineButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Text(
          label,
          style: GoogleFonts.instrumentSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _primaryDark,
          ),
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final LocalWordbookItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WordCard({required this.item, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.word,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primaryDark,
                      ),
                    ),
                    if (item.tag != null && item.tag!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _blueTagBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.tag!.toUpperCase(),
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _blueTag,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.meaning != null && item.meaning!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.meaning!,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      color: _textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                if (item.example != null && item.example!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.example!,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 13,
                      color: _textSecondary.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'added $dateStr',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: _textSecondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              _PillOutlineButton(label: 'Edit', onPressed: onEdit),
              const SizedBox(height: 8),
              _PillDeleteButton(label: 'Delete', onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillDeleteButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PillDeleteButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _delete.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.instrumentSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _delete,
          ),
        ),
      ),
    );
  }
}
