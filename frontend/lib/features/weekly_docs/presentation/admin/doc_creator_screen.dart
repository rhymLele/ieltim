// doc_creator_screen.dart — A2: tạo / sửa tài liệu, wizard 3 bước + cột xem trước.
// Bố cục: file 6 mục A2 · Nghiệp vụ: file 7 UC-D02, D03, D05, D12.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_tokens.dart';
import '../../data/weekly_docs_repository.dart';
import '../../domain/doc_templates.dart';
import '../../domain/doc_validator.dart';
import '../../domain/html_file.dart';
import '../../domain/weekly_doc.dart';
import '../widgets/common_widgets.dart';
import '../widgets/html_frame.dart';
import 'block_editor_panel.dart';
import 'html_upload_dialog.dart';
import 'preview_pane.dart';

enum _SaveState { idle, saving, saved, error }

class DocCreatorScreen extends StatefulWidget {
  const DocCreatorScreen({super.key, required this.repo, this.docId, required this.initialWeek});

  final WeeklyDocsRepository repo;

  /// null = tạo mới; có giá trị = sửa (mở ở bước 2).
  final String? docId;
  final int initialWeek;

  @override
  State<DocCreatorScreen> createState() => _DocCreatorScreenState();
}

class _DocCreatorScreenState extends State<DocCreatorScreen> {
  WeeklyDocsRepository get repo => widget.repo;

  int _step = 1;
  DocRecord? _record;
  late Map<String, dynamic> _json;
  int _version = 1;

  // Bước 1
  final _titleCtl = TextEditingController();
  late final _weekCtl = TextEditingController(text: '${widget.initialWeek}');
  late final _orderCtl = TextEditingController(text: '${repo.nextOrder(widget.initialWeek)}');
  String _skill = 'reading';
  String _templateId = 'reading-lesson';
  String? _titleError;
  String? _orderError;

  // Bước 2
  int _selS = 0;
  int _selB = 0;
  bool _jsonMode = false;
  int _epoch = 0; // tăng khi nội dung bị thay từ ngoài → làm mới ô nhập
  final _jsonCtl = TextEditingController();
  ValidationResult? _jsonCheck;

  // Xem trước
  DocViewMode _pv = DocViewMode.slide;
  int _pvIndex = 0;

  // Bước 3
  DocViewMode _defaultView = DocViewMode.slide;
  bool _allowSwitch = true;
  DateTime? _scheduleAt;
  bool _scheduleMode = false;
  bool _published = false;
  bool _publishing = false;

  // Lưu nháp
  Timer? _saveTimer;
  Future<bool>? _inflightSave;
  _SaveState _saveState = _SaveState.idle;
  DateTime? _savedAt;
  bool _dirtyRelease = false; // tài liệu đang phát hành có thay đổi chưa áp dụng

  // Mở để sửa: tải bản đầy đủ từ máy chủ trước khi dựng màn.
  bool _loadingRecord = false;
  String? _loadError;

  bool get _isEdit => _record != null;
  bool get _isPublishedDoc => _record?.status == DocStatus.published;

  @override
  void initState() {
    super.initState();
    final id = widget.docId;
    if (id != null) {
      _loadingRecord = true;
      _loadRecord(id);
    } else {
      _json = buildDocJson(week: widget.initialWeek, order: repo.nextOrder(widget.initialWeek), title: '', templateId: _templateId, skill: _skill);
      _primeNewDoc();
    }
  }

  Future<void> _loadRecord(String id) async {
    try {
      final r = await repo.loadAdminDoc(id);
      if (!mounted) return;
      setState(() {
        _applyRecord(r);
        _loadingRecord = false;
      });
    } on RepoException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loadingRecord = false;
      });
    }
  }

  /// Tạo mới: tải tuần + danh sách tài liệu để gợi ý tuần hiện tại và số thứ tự tiếp theo.
  Future<void> _primeNewDoc() async {
    final suggestedOrder = _orderCtl.text;
    try {
      await Future.wait<void>([if (repo.weeks.isEmpty) repo.loadWeeks(), repo.loadAdminDocs()]);
    } on RepoException {
      return; // Không tải được thì vẫn soạn được; BE kiểm tra lại khi tạo nháp.
    }
    if (!mounted || _record != null) return;
    setState(() {
      if ((int.tryParse(_weekCtl.text) ?? 0) < 1) _weekCtl.text = '${repo.currentWeekNumber}';
      if (_orderCtl.text == suggestedOrder) _orderCtl.text = '${repo.nextOrder(int.tryParse(_weekCtl.text) ?? 0)}';
    });
  }

  void _applyRecord(DocRecord r) {
    _record = r;
    _json = deepCopyJson(r.json);
    _version = r.version;
    _step = 2;
    _titleCtl.text = r.title;
    _weekCtl.text = '${r.week}';
    _orderCtl.text = '${r.order}';
    final doc = r.doc;
    _skill = doc.meta.skill;
    _templateId = doc.template;
    _defaultView = doc.meta.defaultView;
    _allowSwitch = doc.meta.canSwitch;
    _pv = _defaultView;
  }

  @override
  void dispose() {
    // Rời màn khi còn thay đổi đang chờ lưu: lưu ngay (không setState).
    if (_saveTimer?.isActive == true && _record != null && !_isPublishedDoc) {
      repo.saveDraft(_record!.id, _json, expectedVersion: _version).ignore();
    }
    _saveTimer?.cancel();
    _titleCtl.dispose();
    _weekCtl.dispose();
    _orderCtl.dispose();
    _jsonCtl.dispose();
    super.dispose();
  }

  // ───────────────────────────── Dữ liệu ─────────────────────────────

  List<dynamic> get _sections => _json['sections'] as List<dynamic>;
  Map<String, dynamic> _section(int i) => _sections[i] as Map<String, dynamic>;
  List<dynamic> _blocks(int si) => _section(si)['blocks'] as List<dynamic>;

  Map<String, dynamic>? get _selectedBlock {
    if (_sections.isEmpty) return null;
    final bl = _blocks(_selS.clamp(0, _sections.length - 1));
    if (bl.isEmpty) return null;
    return bl[_selB.clamp(0, bl.length - 1)] as Map<String, dynamic>;
  }

  WeeklyDoc get _doc => WeeklyDoc.fromJson(_json);

  /// Tài liệu HTML (file 9): không có section/khối, chỉ có chuỗi html.
  bool get _isHtmlDoc => _json['template'] == 'html';
  String get _html => _json['html'] as String? ?? '';
  String get _htmlFileName => _json['htmlFileName'] as String? ?? 'tai_lieu.html';

  (String, int)? _htmlSizeMemo; // chuỗi có thể tới 5 MB: chỉ đếm lại khi đổi file
  int get _htmlSize {
    final html = _html;
    final m = _htmlSizeMemo;
    if (m != null && identical(m.$1, html)) return m.$2;
    final n = utf8Length(html);
    _htmlSizeMemo = (html, n);
    return n;
  }

  void _mutate(VoidCallback fn) {
    setState(fn);
    _scheduleSave();
  }

  void _scheduleSave() {
    if (_record == null) return;
    if (_isPublishedDoc) {
      setState(() => _dirtyRelease = true);
      return; // tài liệu đang phát hành: chỉ áp dụng khi bấm "Cập nhật bản phát hành"
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1500), _saveNow);
  }

  /// Lưu ngay, tuần tự: hai request cùng expectedVersion chạy song song sẽ báo xung đột giả.
  Future<bool> _saveNow() async {
    await _awaitInflightSave();
    final save = _save();
    _inflightSave = save;
    try {
      return await save;
    } finally {
      _inflightSave = null;
    }
  }

  Future<void> _awaitInflightSave() async {
    while (_inflightSave != null) {
      await _inflightSave;
    }
  }

  Future<bool> _save() async {
    final r = _record;
    if (r == null) return true;
    _saveTimer?.cancel();
    setState(() => _saveState = _SaveState.saving);
    try {
      final saved = await repo.saveDraft(r.id, _json, expectedVersion: _version);
      if (!mounted) return false;
      setState(() {
        _version = saved.version;
        _saveState = _SaveState.saved;
        _savedAt = DateTime.now();
      });
      return true;
    } on RepoException catch (e) {
      if (!mounted) return false;
      setState(() => _saveState = _SaveState.error);
      if (e.code == 'DOC_VERSION_CONFLICT') await _showConflict(e.message);
      return false;
    }
  }

  Future<void> _showConflict(String message) async {
    final reload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Tài liệu vừa được sửa', style: AppText.heading),
        content: Text(message, style: AppText.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ghi đè bằng bản của tôi')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tải bản mới')),
        ],
      ),
    );
    final r = _record!;
    if (reload ?? true) {
      setState(() {
        _json = deepCopyJson(r.json);
        _version = r.version;
        _epoch++;
        _saveState = _SaveState.idle;
      });
    } else {
      _version = r.version;
      await _save(); // đang ở trong _saveNow: gọi thẳng, không đợi chính mình
    }
  }

  // ───────────────────────────── Bước 1 ─────────────────────────────

  Future<bool> _commitStep1() async {
    final title = _titleCtl.text.trim();
    final week = int.tryParse(_weekCtl.text) ?? 0;
    final order = int.tryParse(_orderCtl.text) ?? 0;
    final tpl = templateById(_templateId);
    setState(() {
      _titleError = tpl.isImport || (title.length >= 3 && title.length <= 200) ? null : 'Tên tài liệu cần từ 3 đến 200 ký tự';
      _orderError = order < 1
          ? 'Số thứ tự phải từ 1'
          : (repo.orderTaken(week, order, exceptId: _record?.id) ? 'Tuần $week đã có Tài liệu $order' : null);
    });
    if (_titleError != null || _orderError != null) return false;

    if (_record == null) {
      _json
        ..['title'] = title.isEmpty ? 'Tài liệu mới' : title
        ..['week'] = week
        ..['order'] = order;
      (_json['meta'] as Map<String, dynamic>)['skill'] = _skill;
      try {
        final r = await repo.createDraft(_json);
        if (!mounted) return false;
        setState(() {
          _record = r;
          _version = r.version;
          _json = deepCopyJson(r.json);
          _jsonMode = tpl.isImport;
          if (_jsonMode) _jsonCtl.text = _prettyJson();
        });
      } on RepoException catch (e) {
        setState(() => _orderError = e.message);
        return false;
      }
    } else {
      _mutate(() {
        _json['title'] = title;
        (_json['meta'] as Map<String, dynamic>)['skill'] = _skill;
      });
    }
    return true;
  }

  Future<void> _pickTemplate(DocTemplate t) async {
    if (t.isHtml) return _pickHtmlFile();
    if (_isEdit && t.id != _templateId) {
      final ok = await _confirm('Đổi template?', 'Đổi template sẽ thay toàn bộ nội dung hiện tại bằng khung mới. Tiếp tục?', 'Đổi template');
      if (!ok) return;
    }
    _mutate(() {
      _templateId = t.id;
      _skill = t.skill;
      _json['sections'] = deepCopyJson(t.sections);
      _json['template'] = t.isImport ? 'custom' : t.id;
      _json
        ..remove('html')
        ..remove('htmlFileName');
      _selS = 0;
      _selB = 0;
      _pvIndex = 0;
      _epoch++;
    });
  }

  /// Popup tải file HTML: bước 1 bấm thẻ "Tải lên file HTML", bước 2 bấm "Đổi file".
  Future<void> _pickHtmlFile() async {
    final f = await showHtmlUploadDialog(context);
    if (f == null || !mounted) return; // Huỷ: giữ nguyên template đang chọn
    if (_isEdit && !_isHtmlDoc) {
      final ok = await _confirm('Đổi template?', 'Đổi sang file HTML sẽ thay toàn bộ nội dung hiện tại. Tiếp tục?', 'Đổi template');
      if (!ok) return;
    }
    final title = f.title;
    _mutate(() {
      _templateId = 'html';
      _json
        ..['template'] = 'html'
        ..['sections'] = <dynamic>[]
        ..['html'] = f.html
        ..['htmlFileName'] = f.name;
      if (_titleCtl.text.trim().isEmpty && title != null) {
        _titleCtl.text = title.length > 200 ? title.substring(0, 200) : title;
        _titleError = null;
      }
      _jsonMode = false;
      _selS = 0;
      _selB = 0;
      _pvIndex = 0;
      _epoch++;
    });
  }

  // ───────────────────────────── Bước 2 ─────────────────────────────

  void _select(int s, int b) {
    setState(() {
      _selS = s;
      _selB = b;
      final slides = buildSlides(_doc);
      final i = slides.indexWhere((p) => p.sectionIndex == s && (p.blocks.any((e) => e.$1 == b) || p.blocks.isEmpty));
      if (i >= 0) _pvIndex = i;
    });
  }

  void _addBlock(String type) {
    final at = _blocks(_selS).isEmpty ? 0 : _selB + 1;
    _mutate(() => _blocks(_selS).insert(at, deepCopyJson(newBlockJson(type))));
    _select(_selS, at);
  }

  void _addSection() {
    _mutate(() => _sections.add(deepCopyJson({
          'title': 'SECTION ${_sections.length + 1}',
          'blocks': [newBlockJson('heading')],
        })));
    _select(_sections.length - 1, 0);
  }

  void _deleteBlock() {
    final bl = _blocks(_selS);
    _mutate(() {
      if (bl.length > 1) {
        bl.removeAt(_selB);
        _selB = (_selB - 1).clamp(0, bl.length - 1);
      } else if (_sections.length > 1) {
        _sections.removeAt(_selS);
        _selS = (_selS - 1).clamp(0, _sections.length - 1);
        _selB = 0;
      }
      _epoch++;
    });
  }

  void _move(int delta) {
    final bl = _blocks(_selS);
    final to = _selB + delta;
    if (to < 0 || to >= bl.length) return;
    _mutate(() {
      final x = bl.removeAt(_selB);
      bl.insert(to, x);
      _selB = to;
      _epoch++;
    });
  }

  /// JSON đầy đủ kèm cài đặt hiển thị ở bước 3.
  Map<String, dynamic> _fullJson() {
    final full = deepCopyJson(_json) as Map<String, dynamic>;
    final meta = full['meta'] as Map<String, dynamic>;
    meta['defaultView'] = _defaultView.name;
    meta['allowedViews'] = _allowSwitch ? ['slide', 'doc'] : [_defaultView.name];
    return full;
  }

  String _prettyJson() => const JsonEncoder.withIndent('  ').convert(_fullJson());

  void _setJsonMode(bool on) {
    setState(() {
      _jsonMode = on;
      if (on) {
        _jsonCtl.text = _prettyJson();
        _jsonCheck = null;
      }
    });
  }

  void _checkAndApplyJson() {
    final res = validateDocText(_jsonCtl.text);
    setState(() => _jsonCheck = res);
    if (!res.isValid) return;
    final parsed = deepCopyJson(asJsonMap(jsonDecode(_jsonCtl.text)));
    final meta = DocMeta.fromJson(parsed['meta']);
    final isHtml = parsed['template'] == 'html';
    _mutate(() {
      // Giữ id / tuần / số thứ tự của bản ghi; lấy nội dung từ file.
      _json
        ..['title'] = parsed['title']
        ..['template'] = parsed['template'] ?? 'custom'
        ..['sections'] = parsed['sections'] is List ? parsed['sections'] : <dynamic>[]
        ..['meta'] = meta.toJson();
      if (isHtml) {
        _json
          ..['html'] = parsed['html']
          ..['htmlFileName'] = parsed['htmlFileName'];
        _templateId = 'html';
        _jsonMode = false; // tài liệu HTML không có tab JSON
      } else {
        _json
          ..remove('html')
          ..remove('htmlFileName');
      }
      _titleCtl.text = parsed['title'] as String? ?? '';
      _skill = meta.skill;
      _defaultView = meta.defaultView;
      _allowSwitch = meta.canSwitch;
      _selS = 0;
      _selB = 0;
      _pvIndex = 0;
      _epoch++;
    });
  }

  Future<void> _pasteJson() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    setState(() {
      _jsonCtl.text = data!.text!;
      _jsonCheck = null;
    });
  }

  void _jumpToIssue(ValidationIssue issue) {
    final loc = issue.location;
    if (loc == null) return;
    final (s, b) = loc;
    if (s >= _sections.length) return;
    setState(() => _jsonMode = false);
    _select(s, b ?? 0);
  }

  // ───────────────────────────── Bước 3 ─────────────────────────────

  Future<void> _publish() async {
    final r = _record;
    if (r == null) return;
    setState(() => _publishing = true);
    final meta = _json['meta'] as Map<String, dynamic>;
    meta['defaultView'] = _defaultView.name;
    meta['allowedViews'] = _allowSwitch ? ['slide', 'doc'] : [_defaultView.name];
    try {
      _saveTimer?.cancel();
      await _awaitInflightSave();
      final saved = await repo.saveDraft(r.id, _json, expectedVersion: _version);
      _version = saved.version;
      if (r.status == DocStatus.published) {
        // Tài liệu đang phát hành: bản vừa lưu là bản nháp sửa đổi, áp dụng cho người dùng.
        _version = (await repo.release(r.id)).version;
      } else {
        await repo.publish(r.id, at: _scheduleMode ? _scheduleAt : null);
      }
      if (!mounted) return;
      setState(() {
        _published = true;
        _publishing = false;
        _dirtyRelease = false;
      });
    } on RepoException catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 365)), initialDate: _scheduleAt ?? now);
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 6, minute: 0));
    if (t == null) return;
    setState(() => _scheduleAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  // ───────────────────────────── Điều hướng ─────────────────────────────

  Future<void> _forward() async {
    if (_step == 1) {
      if (await _commitStep1()) setState(() => _step = 2);
    } else if (_step == 2) {
      if (_jsonMode && _jsonCheck == null) _checkAndApplyJson();
      if (!_isPublishedDoc) await _saveNow();
      setState(() {
        _step = 3;
        _pv = _defaultView;
      });
    } else {
      await _publish();
    }
  }

  void _back() => setState(() => _step = (_step - 1).clamp(1, 3));

  Future<bool> _confirm(String title, String body, String ok) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppText.heading),
        content: Text(body, style: AppText.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
        ],
      ),
    );
    return r ?? false;
  }

  // ───────────────────────────── build ─────────────────────────────

  Widget _loadingScaffold() => Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: 'Đóng', icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).maybePop()),
          title: const Text('Sửa tài liệu', style: AppText.heading),
        ),
        body: _loadError == null
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                isError: true,
                message: _loadError!,
                actionLabel: 'Thử lại',
                onAction: () {
                  setState(() {
                    _loadError = null;
                    _loadingRecord = true;
                  });
                  _loadRecord(widget.docId!);
                },
              ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loadingRecord || _loadError != null) return _loadingScaffold();
    final validation = validateDocJson(_fullJson());
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= AppBreakpoints.adminWide;
      return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _header(wide),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _workArea(validation, wide)),
                      if (wide)
                        Container(
                          width: 500,
                          decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.border))),
                          child: _preview(),
                        ),
                    ],
                  ),
                ),
                _footer(validation),
              ],
            ),
          ),
      );
    });
  }

  String? get _highlightKey {
    if (_step != 2 || _jsonMode) return null;
    final doc = _doc;
    if (_selS < 0 || _selS >= doc.sections.length) return null;
    final blocks = doc.sections[_selS].blocks;
    if (_selB < 0 || _selB >= blocks.length) return null;
    return blockKey(_selS, _selB, blocks[_selB]);
  }

  /// [sheetSetState]: khi xem trước trong bottom sheet (màn hẹp) cần dựng lại cả sheet.
  Widget _preview([StateSetter? sheetSetState]) => PreviewPane(
        doc: _doc,
        view: _pv,
        slideIndex: _pvIndex,
        onViewChanged: (v) {
          setState(() => _pv = v);
          sheetSetState?.call(() {});
        },
        onSlideChanged: (i) {
          setState(() => _pvIndex = i);
          sheetSetState?.call(() {});
        },
        highlightKey: _highlightKey,
      );

  Widget _header(bool wide) {
    final fileName = '${_json['id'] ?? 'w${_weekCtl.text}-doc${_orderCtl.text}'}.json';
    final saveText = switch (_saveState) {
      _SaveState.saving => 'Đang lưu…',
      _SaveState.saved => 'Đã lưu nháp · ${_savedAt!.hour.toString().padLeft(2, '0')}:${_savedAt!.minute.toString().padLeft(2, '0')}',
      _SaveState.error => 'Chưa lưu được',
      _SaveState.idle => _dirtyRelease ? 'Có thay đổi chưa phát hành' : '',
    };
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          IconButton(tooltip: 'Đóng', icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(width: 4),
          SizedBox(
            width: wide ? 230 : 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin › Theo tuần', style: AppText.caption),
                Text(_isEdit && widget.docId != null ? 'Sửa tài liệu' : 'Tạo tài liệu mới', style: AppText.heading),
              ],
            ),
          ),
          Expanded(child: wide ? _stepper() : Center(child: Text('Bước $_step/3 · ${_stepLabels[_step - 1]}', style: AppText.label))),
          if (!wide)
            TextButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.previewBg,
                builder: (_) => FractionallySizedBox(heightFactor: 0.9, child: StatefulBuilder(builder: (ctx, setSheet) => _preview(setSheet))),
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Xem trước'),
            ),
          if (saveText.isNotEmpty) ...[
            Text(saveText, style: AppText.caption.copyWith(color: _saveState == _SaveState.error ? AppColors.primary : AppColors.textMuted)),
            if (_saveState == _SaveState.error) TextButton(onPressed: _saveNow, child: const Text('Thử lại')),
            const SizedBox(width: AppSpace.md),
          ],
          if (wide)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)),
              child: Text(fileName, style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  static const _stepLabels = ['Chọn template', 'Soạn nội dung', 'Xuất bản'];

  Widget _stepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          _stepDot(i + 1),
          if (i < 2) Container(width: 48, height: 2, margin: const EdgeInsets.symmetric(horizontal: 10), color: i + 1 < _step ? AppColors.primary : AppColors.borderStrong),
        ],
      ],
    );
  }

  Widget _stepDot(int n) {
    final done = n < _step || (n == 3 && _published);
    final active = n == _step && !done;
    final canTap = _isEdit && !_published && n != _step;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: canTap
          ? () async {
              if (n == 3 && _step == 2 && !_isPublishedDoc) await _saveNow();
              setState(() => _step = n);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primary : AppColors.surface,
                border: Border.all(color: done || active ? AppColors.primary : AppColors.borderStrong, width: 1.5),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary)
                  : Text('$n', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: active ? AppColors.primary : AppColors.textDisabled)),
            ),
            const SizedBox(width: 10),
            Text(_stepLabels[n - 1], style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: active || done ? AppColors.text : AppColors.textDisabled)),
          ],
        ),
      ),
    );
  }

  Widget _footer(ValidationResult v) {
    final hints = [
      'Template chỉ là khung: mọi section và khối đều sửa, thêm, xoá được ở bước sau.',
      _isHtmlDoc
          ? 'Bấm "Đổi file" để thay nội dung; khung "Hiển thị thử" chạy nguyên file.'
          : (_jsonMode ? 'Dán JSON rồi bấm "Kiểm tra & áp dụng".' : 'Chọn khối bên trái để sửa; khung xem trước tô vàng khối đang sửa.'),
      v.isValid ? 'Kiểm tra xong, có thể xuất bản.' : 'Sửa các lỗi đỏ trước khi xuất bản.',
    ];
    final last = _step == 3;
    final fwdLabel = !last ? 'Tiếp tục →' : (_isPublishedDoc ? 'Cập nhật bản phát hành' : (_scheduleMode ? 'Hẹn giờ xuất bản' : 'Xuất bản'));
    final canForward = !last || (v.isValid && !_publishing && (!_scheduleMode || _scheduleAt != null));
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Visibility(
            visible: _step > 1 && !_published,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: OutlinedButton(onPressed: _back, style: OutlinedButton.styleFrom(foregroundColor: AppColors.text), child: const Text('← Quay lại')),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(hints[_step - 1], maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 13))),
          const SizedBox(width: AppSpace.md),
          if (!_published)
            FilledButton(
              onPressed: canForward ? _forward : null,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22)),
              child: _publishing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary)) : Text(fwdLabel),
            ),
        ],
      ),
    );
  }

  Widget _workArea(ValidationResult v, bool wide) {
    return switch (_step) {
      1 => _step1(wide),
      2 => _step2(),
      _ => _step3(v),
    };
  }

  // ── Bước 1 ──

  Widget _step1(bool wide) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.xxl),
      children: [
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.md,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: wide ? 340 : double.infinity,
              child: _labeled('Tên tài liệu', TextField(controller: _titleCtl, decoration: InputDecoration(hintText: 'Ví dụ: Reading: Matching Headings', errorText: _titleError))),
            ),
            SizedBox(
              width: 120,
              child: _labeled(
                'Tuần',
                TextField(
                  controller: _weekCtl,
                  enabled: !_isEdit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    final w = int.tryParse(v);
                    if (w != null && !_isEdit) _orderCtl.text = '${repo.nextOrder(w)}';
                  },
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: _labeled(
                'Tài liệu số',
                TextField(
                  controller: _orderCtl,
                  enabled: !_isEdit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(errorText: _orderError, errorMaxLines: 2),
                ),
              ),
            ),
            _labeled(
              'Kỹ năng',
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in skillLabels.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: _skill == e.key,
                      onSelected: (_) => setState(() => _skill = e.key),
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: _skill == e.key ? AppColors.primary : AppColors.borderStrong),
                      shape: const StadiumBorder(),
                      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _skill == e.key ? AppColors.onPrimary : AppColors.text),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_isEdit) ...[
          const SizedBox(height: 6),
          const Text('Tuần và số thứ tự không đổi được sau khi tạo. Muốn chuyển tuần, hãy dùng "Nhân bản".', style: AppText.caption),
        ],
        const SizedBox(height: AppSpace.xl),
        const Eyebrow('Chọn template'),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 700 ? 3 : (c.maxWidth >= 420 ? 2 : 1);
          const gap = 14.0;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (final t in docTemplates) SizedBox(width: w, child: _templateCard(t))],
          );
        }),
      ],
    );
  }

  Widget _labeled(String label, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [Text(label, style: AppText.label), const SizedBox(height: 6), child],
      );

  Widget _templateCard(DocTemplate t) {
    final on = _templateId == t.id;
    final code = t.isImport || t.isHtml;
    final thumbBg = code ? AppColors.codeBg : (on ? AppColors.primary : AppColors.sidebar);
    final thumbFg = code ? AppColors.codeText : (on ? AppColors.onPrimary : AppColors.textMuted);
    final bar = code ? AppColors.gold : (on ? AppColors.onPrimary.withAlpha(128) : AppColors.borderStrong);
    final description = on && t.isHtml && _isHtmlDoc ? 'Đã chọn: $_htmlFileName · ${formatFileSize(_htmlSize)}' : t.description;
    return Semantics(
      selected: on,
      button: true,
      label: 'Template ${t.name}${on ? ', đang chọn' : ''}',
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card), side: BorderSide(color: on ? AppColors.primary : AppColors.border, width: 1.5)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _pickTemplate(t),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 96,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: thumbBg, borderRadius: BorderRadius.circular(AppRadius.md)),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.isImport ? '{ JSON }' : (t.isHtml ? '</> HTML' : t.id.toUpperCase()), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, height: 1.2, color: thumbFg)),
                      const SizedBox(height: 2),
                      for (final o in t.outline.take(4))
                        Row(
                          children: [
                            Container(width: 14, height: 4, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 6),
                            Flexible(child: Text(o, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, height: 1.3, color: thumbFg))),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text(t.name, style: AppText.label.copyWith(fontSize: 14, fontWeight: FontWeight.w800))),
                    if (on) const Text('ĐANG CHỌN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(height: 1.45)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bước 2 ──

  Widget _step2() {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isPublishedDoc)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpace.md),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AppColors.tipBg, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: const Text(
                'Tài liệu đang hiển thị cho người dùng. Thay đổi chỉ được áp dụng khi bạn bấm "Cập nhật bản phát hành" ở bước 3.',
                style: TextStyle(fontSize: 13, color: AppColors.warnText, fontWeight: FontWeight.w600),
              ),
            ),
          if (_isHtmlDoc)
            Expanded(child: _htmlTab())
          else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: AppColors.sidebar, borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _modeButton('Soạn theo form', !_jsonMode, () => _setJsonMode(false)),
                      _modeButton('Nhập JSON', _jsonMode, () => _setJsonMode(true)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    _jsonMode ? 'Hệ thống đọc các key: schemaVersion, title, sections[].title, sections[].blocks[].type …' : 'Mọi thay đổi được ghi vào JSON, xem trước cập nhật ngay.',
                    style: AppText.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(child: _jsonMode ? _jsonTab() : _formTab()),
          ],
        ],
      ),
    );
  }

  Widget _modeButton(String label, bool on, VoidCallback onTap) => Material(
        color: on ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: on ? AppColors.onPrimary : AppColors.textMuted)),
          ),
        ),
      );

  Widget _formTab() {
    // Template rỗng (vd. 'html' có sections: []) → clamp(0, -1) sẽ ném lỗi.
    if (_sections.isEmpty) {
      return AppCard(child: EmptyState(message: 'Tài liệu chưa có section nào', actionLabel: '+ Thêm section', onAction: _addSection));
    }
    final selS = _selS.clamp(0, _sections.length - 1);
    final block = _selectedBlock;
    return LayoutBuilder(builder: (context, c) {
      final outline = AppCard(padding: EdgeInsets.zero, child: _outline());
      final editor = AppCard(
        padding: EdgeInsets.zero,
        child: BlockEditorPanel(
          section: _section(selS),
          block: block,
          fieldKeyPrefix: '$selS-$_selB-$_epoch',
          onChanged: () => _mutate(() {}),
          onAddBlock: _addBlock,
          onMoveUp: _selB > 0 ? () => _move(-1) : null,
          onMoveDown: _selB < _blocks(selS).length - 1 ? () => _move(1) : null,
          onDelete: _deleteBlock,
        ),
      );
      if (c.maxWidth < 640) {
        return Column(children: [SizedBox(height: 220, child: outline), const SizedBox(height: 14), Expanded(child: editor)]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [SizedBox(width: 290, child: outline), const SizedBox(width: 14), Expanded(child: editor)],
      );
    });
  }

  Widget _outline() {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        for (var si = 0; si < _sections.length; si++) ...[
          Material(
            color: si == _selS ? AppColors.sidebar : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: () => _select(si, 0),
              child: SizedBox(
                height: 32,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SectionLabel(number: si + 1, title: (_section(si)['title'] as String?)?.isNotEmpty == true ? _section(si)['title'] as String : '(chưa đặt tên)', size: 20, fontSize: 11),
                ),
              ),
            ),
          ),
          for (var bi = 0; bi < _blocks(si).length; bi++) _outlineRow(si, bi),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: _addSection,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          child: const Text('+ Thêm section (slide mới)'),
        ),
      ],
    );
  }

  Widget _outlineRow(int si, int bi) {
    final b = asJsonMap(_blocks(si)[bi]);
    final type = b['type'] as String? ?? '';
    final items = b['items'];
    final first = items is List && items.isNotEmpty ? items.first : null;
    final snip = (b['text'] ?? b['question'] ?? b['structure'] ?? (first is Map ? first['word'] : first) ?? b['url'] ?? '').toString().replaceAll('**', '');
    final on = si == _selS && bi == _selB;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Material(
        color: on ? AppColors.surface : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm), side: on ? const BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          hoverColor: AppColors.hover,
          onTap: () => _select(si, bi),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 7, 10, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(blockTypeLabels[type] ?? type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                if (snip.isNotEmpty) Text(snip, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.text)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bước 2 của tài liệu HTML: thẻ file + khung "Hiển thị thử" chạy nguyên file.
  Widget _htmlTab() {
    final html = _html;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const HtmlFileBadge(),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_htmlFileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(html.isEmpty ? 'Chưa tải file' : formatFileSize(_htmlSize), style: AppText.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              OutlinedButton.icon(onPressed: _pickHtmlFile, icon: const Icon(Icons.swap_horiz_rounded, size: 18), label: const Text('Đổi file')),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        const Eyebrow('Hiển thị thử'),
        const SizedBox(height: AppSpace.sm),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
            clipBehavior: Clip.antiAlias,
            child: html.isEmpty ? EmptyState(message: 'Chưa tải file HTML', actionLabel: 'Tải file', onAction: _pickHtmlFile) : HtmlFrame(html: html),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        const Text('File tự lo trình chiếu và điều hướng. Bấm vào khung rồi dùng phím hoặc nút của file để thử.', style: AppText.caption),
      ],
    );
  }

  Widget _jsonTab() {
    final check = _jsonCheck;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Tải file .json: dùng package file_picker ở tầng app rồi gán nội dung vào _jsonCtl.
            OutlinedButton.icon(onPressed: _pasteJson, icon: const Icon(Icons.content_paste_rounded, size: 18), label: const Text('Dán từ clipboard')),
            FilledButton(onPressed: _checkAndApplyJson, child: const Text('Kiểm tra & áp dụng')),
            OutlinedButton(
              onPressed: () {
                final t = templateById(_templateId == 'import' ? 'blank' : _templateId);
                _mutate(() {
                  _json['sections'] = deepCopyJson(t.sections);
                  _epoch++;
                });
                setState(() {
                  _jsonCtl.text = _prettyJson();
                  _jsonCheck = null;
                });
              },
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textMuted),
              child: const Text('Lấy lại từ template'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: AppColors.codeBg, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.codeBorder)),
            child: TextField(
              controller: _jsonCtl,
              expands: true,
              maxLines: null,
              minLines: null,
              autocorrect: false,
              enableSuggestions: false,
              style: AppText.mono,
              cursorColor: AppColors.goldLight,
              onChanged: (_) {
                if (_jsonCheck != null) setState(() => _jsonCheck = null);
              },
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
                hintText: 'Dán nội dung JSON vào đây',
              ),
            ),
          ),
        ),
        if (check != null) ...[
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: check.isValid ? AppColors.successBg : AppColors.errorBg, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    check.isValid ? 'Hợp lệ, đã dựng tài liệu từ JSON${check.warnings.isEmpty ? '' : ' (có lưu ý)'}' : 'JSON chưa hợp lệ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: check.isValid ? AppColors.success : AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  for (final i in [...check.errors, ...check.warnings])
                    InkWell(
                      onTap: i.location == null ? null : () => _jumpToIssue(i),
                      child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• $i', style: const TextStyle(fontSize: 12.5, color: AppColors.text))),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Bước 3 ──

  Widget _step3(ValidationResult v) {
    final doc = _doc;
    if (_published) return _successCard(doc);
    final blocks = doc.sections.fold<int>(0, (n, s) => n + s.blocks.length);
    final issues = [...v.errors, ...v.warnings];
    final (bg, fg, title) = !v.isValid
        ? (AppColors.errorBg, AppColors.primary, '${v.errors.length} lỗi cần sửa')
        : (v.warnings.isNotEmpty ? (AppColors.tipBg, AppColors.warnText, 'Hợp lệ, nhưng còn lưu ý') : (AppColors.successBg, AppColors.success, 'Hợp lệ, sẵn sàng xuất bản'));
    return ListView(
      padding: const EdgeInsets.all(AppSpace.xxl),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hiển thị cho người dùng', style: AppText.heading),
                    const SizedBox(height: 14),
                    if (_isHtmlDoc) ...[
                      const Text('Tài liệu HTML hiển thị nguyên file, file tự lo trình chiếu. Không có Slide / Doc.', style: AppText.body),
                      const SizedBox(height: 10),
                    ] else ...[
                      const Text('Kiểu mặc định', style: AppText.label),
                      const SizedBox(height: 6),
                      Wrap(spacing: 8, children: [
                        _choiceButton('Slide', _defaultView == DocViewMode.slide, () => setState(() => _pv = _defaultView = DocViewMode.slide)),
                        _choiceButton('Doc', _defaultView == DocViewMode.doc, () => setState(() => _pv = _defaultView = DocViewMode.doc)),
                      ]),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _allowSwitch,
                        activeColor: AppColors.primary,
                        onChanged: (x) => setState(() => _allowSwitch = x),
                        title: const Text('Cho phép người dùng tự đổi giữa Slide và Doc', style: AppText.label),
                      ),
                    ],
                    if (!_isPublishedDoc) ...[
                      const SizedBox(height: 4),
                      const Text('Thời điểm', style: AppText.label),
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        value: false,
                        groupValue: _scheduleMode,
                        activeColor: AppColors.primary,
                        onChanged: (x) => setState(() => _scheduleMode = false),
                        title: const Text('Xuất bản ngay', style: AppText.body),
                      ),
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        value: true,
                        groupValue: _scheduleMode,
                        activeColor: AppColors.primary,
                        onChanged: (x) => setState(() => _scheduleMode = true),
                        title: const Text('Hẹn giờ', style: AppText.body),
                        subtitle: _scheduleMode
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _pickSchedule,
                                  icon: const Icon(Icons.event_outlined, size: 18),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                  label: Text(_scheduleAt == null
                                      ? 'Chọn ngày giờ'
                                      : '${_scheduleAt!.day}/${_scheduleAt!.month}/${_scheduleAt!.year} ${_scheduleAt!.hour.toString().padLeft(2, '0')}:${_scheduleAt!.minute.toString().padLeft(2, '0')}'),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.card)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                    const SizedBox(height: 6),
                    if (issues.isEmpty)
                      Text(
                        _isHtmlDoc ? '$_htmlFileName · ${formatFileSize(_htmlSize)}' : '${doc.sections.length} section, $blocks khối',
                        style: AppText.body.copyWith(fontSize: 13),
                      ),
                    for (final i in issues)
                      InkWell(
                        onTap: i.location == null
                            ? null
                            : () {
                                setState(() => _step = 2);
                                _jumpToIssue(i);
                              },
                        child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• $i', style: AppText.body.copyWith(fontSize: 13))),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _choiceButton(String label, bool on, VoidCallback onTap) => SizedBox(
        height: 40,
        child: on
            ? FilledButton(onPressed: onTap, child: Text(label))
            : OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: AppColors.text), child: Text(label)),
      );

  Widget _successCard(WeeklyDoc doc) {
    final scheduled = _record?.status == DocStatus.scheduled;
    return ListView(
      padding: const EdgeInsets.all(AppSpace.xxl),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AppCard(
            radius: AppRadius.cardLg,
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.success, size: 28),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  scheduled ? 'Đã hẹn giờ Tài liệu ${doc.order} · Tuần ${doc.week}' : 'Đã xuất bản Tài liệu ${doc.order} vào Tuần ${doc.week}',
                  style: AppText.title.copyWith(fontSize: 22),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  _isHtmlDoc
                      ? 'Người dùng sẽ thấy tài liệu ở mục Theo tuần, hiển thị nguyên file HTML.'
                      : 'Người dùng sẽ thấy tài liệu ở mục Theo tuần, mặc định hiển thị dạng ${_defaultView == DocViewMode.slide ? 'Slide' : 'Doc'}.',
                  style: AppText.body.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpace.lg),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _prettyJson()));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã sao chép ${doc.id}.json')));
                      },
                      child: Text('Sao chép ${doc.id}.json'),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                        builder: (_) => DocCreatorScreen(repo: repo, initialWeek: doc.week),
                      )),
                      child: Text('Tạo tài liệu ${repo.nextOrder(doc.week)}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
