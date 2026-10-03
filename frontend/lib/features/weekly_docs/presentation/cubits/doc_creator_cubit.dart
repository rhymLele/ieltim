import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/admin_doc.dart';
import '../../domain/entities/doc_json.dart';
import '../../domain/entities/doc_status.dart';
import '../../domain/entities/doc_summary.dart';
import '../../domain/entities/week_info.dart';
import '../../domain/entities/weekly_doc.dart';
import '../../domain/entities/weekly_docs_exceptions.dart';
import '../../domain/rules/doc_templates.dart';
import '../../domain/rules/doc_validator.dart';
import '../../domain/rules/html_file.dart';
import '../../domain/usecases/create_draft_use_case.dart';
import '../../domain/usecases/get_admin_doc_use_case.dart';
import '../../domain/usecases/get_admin_docs_use_case.dart';
import '../../domain/usecases/get_weeks_use_case.dart';
import '../../domain/usecases/publish_doc_use_case.dart';
import '../../domain/usecases/release_doc_use_case.dart';
import '../../domain/usecases/save_draft_use_case.dart';
import 'ui_state.dart';

enum SaveState { idle, saving, saved, error }

class DocCreatorState {
  const DocCreatorState({
    required this.json,
    required this.doc,
    required this.validation,
    this.status = LoadStatus.ready,
    this.loadError,
    this.record,
    this.version = 1,
    this.revision = 0,
    this.epoch = 0,
    this.htmlSize = 0,
    this.step = 1,
    this.title = '',
    this.weekText = '',
    this.orderText = '',
    this.fieldsEpoch = 0,
    this.skill = 'reading',
    this.templateId = 'reading-lesson',
    this.titleError,
    this.orderError,
    this.selectedSection = 0,
    this.selectedBlock = 0,
    this.jsonMode = false,
    this.jsonCheck,
    this.previewView = DocViewMode.slide,
    this.previewIndex = 0,
    this.defaultView = DocViewMode.slide,
    this.allowSwitch = true,
    this.scheduleMode = false,
    this.scheduleAt,
    this.isPublishing = false,
    this.published = false,
    this.saveState = SaveState.idle,
    this.savedAt,
    this.dirtyRelease = false,
    this.conflictMessage,
    this.notice,
  });

  // Tải bản ghi (mở để sửa).
  final LoadStatus status;
  final String? loadError;

  /// Bản ghi trên máy chủ (null khi chưa tạo nháp) và version đang giữ để lưu.
  final AdminDoc? record;
  final int version;

  /// JSON đang soạn. Sửa tại chỗ (khung soạn khối ghi thẳng vào map); [revision] tăng mỗi lần đổi.
  final Map<String, dynamic> json;
  final WeeklyDoc doc;
  final ValidationResult validation;
  final int revision;

  /// Tăng khi nội dung bị thay từ ngoài (đổi template, áp dụng JSON, tải bản mới) → ô nhập dựng lại.
  final int epoch;
  final int htmlSize;

  final int step;

  // Bước 1. [fieldsEpoch] tăng khi cubit tự điền ô (gợi ý số thứ tự, tên từ file HTML).
  final String title;
  final String weekText;
  final String orderText;
  final int fieldsEpoch;
  final String skill;
  final String templateId;
  final String? titleError;
  final String? orderError;

  // Bước 2.
  final int selectedSection;
  final int selectedBlock;
  final bool jsonMode;
  final ValidationResult? jsonCheck;

  // Cột xem trước.
  final DocViewMode previewView;
  final int previewIndex;

  // Bước 3.
  final DocViewMode defaultView;
  final bool allowSwitch;
  final bool scheduleMode;
  final DateTime? scheduleAt;
  final bool isPublishing;
  final bool published;

  // Lưu nháp.
  final SaveState saveState;
  final DateTime? savedAt;

  /// Tài liệu đang phát hành có thay đổi chưa áp dụng.
  final bool dirtyRelease;

  /// Có giá trị = lưu bị 409, đang chờ admin chọn "Tải bản mới" / "Ghi đè".
  final String? conflictMessage;
  final UiNotice? notice;

  bool get isEdit => record != null;
  bool get isPublishedDoc => record?.status == DocStatus.published;
  bool get isHtmlDoc => json['template'] == 'html';
  String get html => json['html'] as String? ?? '';
  String get htmlFileName => json['htmlFileName'] as String? ?? 'tai_lieu.html';
  List<dynamic> get sections => json['sections'] is List<dynamic> ? json['sections'] as List<dynamic> : const [];
  /// Tên file JSON trên thanh trên: chưa tạo nháp thì theo tuần / số thứ tự đang nhập.
  String get fileName => '${record?.summary.id ?? 'w$weekText-doc$orderText'}.json';

  Map<String, dynamic>? get selectedSectionJson {
    if (sections.isEmpty) return null;
    return asJsonMap(sections[selectedSection.clamp(0, sections.length - 1)]);
  }

  List<dynamic> blocksOf(int sectionIndex) {
    final blocks = asJsonMap(sections[sectionIndex])['blocks'];
    return blocks is List<dynamic> ? blocks : const [];
  }

  Map<String, dynamic>? get selectedBlockJson {
    if (sections.isEmpty) return null;
    final blocks = blocksOf(selectedSection.clamp(0, sections.length - 1));
    if (blocks.isEmpty) return null;
    final block = blocks[selectedBlock.clamp(0, blocks.length - 1)];
    return block is Map<String, dynamic> ? block : null;
  }

  /// Khối đang sửa, để khung xem trước tô viền vàng.
  String? get highlightKey {
    if (step != 2 || jsonMode) return null;
    if (selectedSection < 0 || selectedSection >= doc.sections.length) return null;
    final blocks = doc.sections[selectedSection].blocks;
    if (selectedBlock < 0 || selectedBlock >= blocks.length) return null;
    return blockKey(selectedSection, selectedBlock, blocks[selectedBlock]);
  }

  bool get canForward => step != 3 || (validation.isValid && !isPublishing && (!scheduleMode || scheduleAt != null));

  DocCreatorState copyWith({
    LoadStatus? status,
    Object? loadError = keep,
    AdminDoc? record,
    int? version,
    Map<String, dynamic>? json,
    WeeklyDoc? doc,
    ValidationResult? validation,
    int? revision,
    int? epoch,
    int? htmlSize,
    int? step,
    String? title,
    String? weekText,
    String? orderText,
    int? fieldsEpoch,
    String? skill,
    String? templateId,
    Object? titleError = keep,
    Object? orderError = keep,
    int? selectedSection,
    int? selectedBlock,
    bool? jsonMode,
    Object? jsonCheck = keep,
    DocViewMode? previewView,
    int? previewIndex,
    DocViewMode? defaultView,
    bool? allowSwitch,
    bool? scheduleMode,
    DateTime? scheduleAt,
    bool? isPublishing,
    bool? published,
    SaveState? saveState,
    DateTime? savedAt,
    bool? dirtyRelease,
    Object? conflictMessage = keep,
    UiNotice? notice,
  }) =>
      DocCreatorState(
        status: status ?? this.status,
        loadError: identical(loadError, keep) ? this.loadError : loadError as String?,
        record: record ?? this.record,
        version: version ?? this.version,
        json: json ?? this.json,
        doc: doc ?? this.doc,
        validation: validation ?? this.validation,
        revision: revision ?? this.revision,
        epoch: epoch ?? this.epoch,
        htmlSize: htmlSize ?? this.htmlSize,
        step: step ?? this.step,
        title: title ?? this.title,
        weekText: weekText ?? this.weekText,
        orderText: orderText ?? this.orderText,
        fieldsEpoch: fieldsEpoch ?? this.fieldsEpoch,
        skill: skill ?? this.skill,
        templateId: templateId ?? this.templateId,
        titleError: identical(titleError, keep) ? this.titleError : titleError as String?,
        orderError: identical(orderError, keep) ? this.orderError : orderError as String?,
        selectedSection: selectedSection ?? this.selectedSection,
        selectedBlock: selectedBlock ?? this.selectedBlock,
        jsonMode: jsonMode ?? this.jsonMode,
        jsonCheck: identical(jsonCheck, keep) ? this.jsonCheck : jsonCheck as ValidationResult?,
        previewView: previewView ?? this.previewView,
        previewIndex: previewIndex ?? this.previewIndex,
        defaultView: defaultView ?? this.defaultView,
        allowSwitch: allowSwitch ?? this.allowSwitch,
        scheduleMode: scheduleMode ?? this.scheduleMode,
        scheduleAt: scheduleAt ?? this.scheduleAt,
        isPublishing: isPublishing ?? this.isPublishing,
        published: published ?? this.published,
        saveState: saveState ?? this.saveState,
        savedAt: savedAt ?? this.savedAt,
        dirtyRelease: dirtyRelease ?? this.dirtyRelease,
        conflictMessage: identical(conflictMessage, keep) ? this.conflictMessage : conflictMessage as String?,
        notice: notice ?? this.notice,
      );
}

/// Màn tạo / sửa tài liệu (A2): wizard 3 bước, tự lưu nháp, xuất bản (file 7 UC-D02, D03, D05, D12; file 9).
class DocCreatorCubit extends Cubit<DocCreatorState> {
  DocCreatorCubit({
    this.docId,
    required int initialWeek,
    this.autosaveDelay = const Duration(milliseconds: 1500),
    GetAdminDocUseCase? getAdminDoc,
    GetAdminDocsUseCase? getAdminDocs,
    GetWeeksUseCase? getWeeks,
    CreateDraftUseCase? createDraft,
    SaveDraftUseCase? saveDraft,
    PublishDocUseCase? publishDoc,
    ReleaseDocUseCase? releaseDoc,
  })  : _getAdminDoc = getAdminDoc ?? GetAdminDocUseCase(),
        _getAdminDocs = getAdminDocs ?? GetAdminDocsUseCase(),
        _getWeeks = getWeeks ?? GetWeeksUseCase(),
        _createDraft = createDraft ?? CreateDraftUseCase(),
        _saveDraft = saveDraft ?? SaveDraftUseCase(),
        _publishDoc = publishDoc ?? PublishDocUseCase(),
        _releaseDoc = releaseDoc ?? ReleaseDocUseCase(),
        super(_initialState(isEdit: docId != null, initialWeek: initialWeek));

  /// null = tạo mới; có giá trị = sửa (mở ở bước 2).
  final String? docId;
  final Duration autosaveDelay;
  final GetAdminDocUseCase _getAdminDoc;
  final GetAdminDocsUseCase _getAdminDocs;
  final GetWeeksUseCase _getWeeks;
  final CreateDraftUseCase _createDraft;
  final SaveDraftUseCase _saveDraft;
  final PublishDocUseCase _publishDoc;
  final ReleaseDocUseCase _releaseDoc;

  Timer? _saveTimer;
  Future<void>? _inflightSave;
  AdminDoc? _conflictCurrent;
  WeekList? _weekList;
  List<DocSummary> _existingDocs = const [];
  String? _sizedHtml;
  int _sizedBytes = 0;

  static DocCreatorState _initialState({required bool isEdit, required int initialWeek}) {
    final json = buildDocJson(week: initialWeek, order: 1, title: '', templateId: 'reading-lesson', skill: 'reading');
    return DocCreatorState(
      status: isEdit ? LoadStatus.loading : LoadStatus.ready,
      json: json,
      doc: WeeklyDoc.fromJson(json),
      validation: validateDocJson(json),
      weekText: '$initialWeek',
      orderText: '1',
    );
  }

  Future<void> start() => docId == null ? _primeNewDoc() : _loadRecord();

  Future<void> retryLoad() => _loadRecord();

  /// "Tạo tài liệu tiếp theo" sau khi xuất bản (màn tạo mới): soạn lại từ đầu ở tuần [week].
  /// Cùng URL nên router không dựng lại màn; cubit tự về trạng thái ban đầu.
  Future<void> startOver(int week) {
    _saveTimer?.cancel();
    final fresh = _initialState(isEdit: false, initialWeek: week);
    emit(fresh.copyWith(orderText: '${nextOrder(week)}', fieldsEpoch: state.fieldsEpoch + 1, epoch: state.epoch + 1, notice: state.notice));
    return _primeNewDoc();
  }

  /// Số thứ tự gợi ý trong tuần [week] (lớn nhất + 1).
  int nextOrder(int week) {
    final orders = _existingDocs.where((d) => d.week == week).map((d) => d.order);
    return orders.isEmpty ? 1 : orders.reduce((a, b) => a > b ? a : b) + 1;
  }

  // ───────────────────────────── Tải ─────────────────────────────

  Future<void> _loadRecord() async {
    final id = docId;
    if (id == null) return;
    emit(state.copyWith(status: LoadStatus.loading, loadError: null));
    final docs = _getAdminDocs.execute();
    final record = await _getAdminDoc.execute(id);
    // Danh sách chỉ để gợi ý số thứ tự cho "Tạo tài liệu tiếp theo"; lỗi thì bỏ qua.
    if (await docs case Success(:final data)) _existingDocs = data;
    if (isClosed) return;
    switch (record) {
      case Success(:final data):
        _applyRecord(data);
      case Failure(:final exception):
        emit(state.copyWith(status: LoadStatus.failure, loadError: exception.message));
    }
  }

  void _applyRecord(AdminDoc record) {
    final json = deepCopyJson(record.content.value) as Map<String, dynamic>;
    final meta = WeeklyDoc.fromJson(json).meta;
    _emitContent(
      state.copyWith(
        status: LoadStatus.ready,
        record: record,
        version: record.version,
        json: json,
        step: 2,
        title: record.summary.title,
        weekText: '${record.summary.week}',
        orderText: '${record.summary.order}',
        fieldsEpoch: state.fieldsEpoch + 1,
        skill: meta.skill,
        templateId: record.summary.template,
        defaultView: meta.defaultView,
        allowSwitch: meta.canSwitch,
        previewView: meta.defaultView,
      ),
      replaced: true,
      save: false,
    );
  }

  /// Tạo mới: tải tuần + danh sách tài liệu để gợi ý tuần hiện tại và số thứ tự tiếp theo.
  Future<void> _primeNewDoc() async {
    final suggestedOrder = state.orderText;
    final weeks = await _getWeeks.execute();
    final docs = await _getAdminDocs.execute();
    if (isClosed || state.record != null) return;
    if (weeks case Success(:final data)) _weekList = data;
    if (docs case Success(:final data)) _existingDocs = data;
    final typedWeek = int.tryParse(state.weekText) ?? 0;
    final week = typedWeek < 1 ? (_weekList?.currentWeekNumber ?? 0) : typedWeek;
    emit(state.copyWith(
      weekText: '$week',
      orderText: state.orderText == suggestedOrder ? '${nextOrder(week)}' : null,
      fieldsEpoch: state.fieldsEpoch + 1,
    ));
  }

  // ───────────────────────────── Bước 1 ─────────────────────────────

  void setTitle(String title) => emit(state.copyWith(title: title));

  /// Đổi tuần (khi tạo mới) thì gợi ý lại số thứ tự.
  void setWeekText(String text) {
    final week = int.tryParse(text);
    if (week == null || state.isEdit) {
      emit(state.copyWith(weekText: text));
      return;
    }
    emit(state.copyWith(weekText: text, orderText: '${nextOrder(week)}', fieldsEpoch: state.fieldsEpoch + 1));
  }

  void setOrderText(String text) => emit(state.copyWith(orderText: text));

  void setSkill(String skill) => emit(state.copyWith(skill: skill));

  /// Đổi template khi đang sửa sẽ thay toàn bộ nội dung → màn hình hỏi xác nhận trước.
  bool needsConfirmFor(DocTemplate template) =>
      template.isHtml ? state.isEdit && !state.isHtmlDoc : state.isEdit && template.id != state.templateId;

  void applyTemplate(DocTemplate template) {
    state.json
      ..['sections'] = deepCopyJson(template.sections)
      ..['template'] = template.isImport ? 'custom' : template.id
      ..remove('html')
      ..remove('htmlFileName');
    _emitContent(
      state.copyWith(templateId: template.id, skill: template.skill, selectedSection: 0, selectedBlock: 0, previewIndex: 0),
      replaced: true,
    );
  }

  /// Dùng file HTML vừa chọn (file 9): template `html`, `sections = []`; tên trống thì lấy `<title>` của file.
  void applyHtmlFile(HtmlFile file) {
    state.json
      ..['template'] = 'html'
      ..['sections'] = <dynamic>[]
      ..['html'] = file.html
      ..['htmlFileName'] = file.name;
    final fileTitle = file.title;
    final fillTitle = state.title.trim().isEmpty && fileTitle != null;
    _emitContent(
      state.copyWith(
        templateId: 'html',
        title: fillTitle ? (fileTitle.length > 200 ? fileTitle.substring(0, 200) : fileTitle) : null,
        titleError: fillTitle ? null : keep,
        fieldsEpoch: fillTitle ? state.fieldsEpoch + 1 : null,
        jsonMode: false,
        selectedSection: 0,
        selectedBlock: 0,
        previewIndex: 0,
      ),
      replaced: true,
    );
  }

  Future<bool> _commitStep1() async {
    final title = state.title.trim();
    final week = int.tryParse(state.weekText) ?? 0;
    final order = int.tryParse(state.orderText) ?? 0;
    final template = templateById(state.templateId);
    final titleError = template.isImport || (title.length >= 3 && title.length <= 200) ? null : 'Tên tài liệu cần từ 3 đến 200 ký tự';
    final orderError = order < 1 ? 'Số thứ tự phải từ 1' : (_orderTaken(week, order) ? 'Tuần $week đã có Tài liệu $order' : null);
    emit(state.copyWith(titleError: titleError, orderError: orderError));
    if (titleError != null || orderError != null) return false;

    if (state.record != null) {
      state.json['title'] = title;
      asJsonMap(state.json['meta'])['skill'] = state.skill;
      _emitContent(state);
      return true;
    }
    state.json
      ..['title'] = title.isEmpty ? 'Tài liệu mới' : title
      ..['week'] = week
      ..['order'] = order;
    (state.json['meta'] as Map<String, dynamic>)['skill'] = state.skill;
    final created = await _createDraft.execute(week: week, order: order, content: DocJson(state.json));
    if (isClosed) return false;
    switch (created) {
      case Success(:final data):
        _existingDocs = [..._existingDocs, data.summary];
        _emitContent(
          state.copyWith(record: data, version: data.version, json: deepCopyJson(data.content.value) as Map<String, dynamic>, jsonMode: template.isImport),
          replaced: true,
          save: false,
        );
        return true;
      case Failure(:final exception):
        emit(state.copyWith(orderError: exception.message));
        return false;
    }
  }

  bool _orderTaken(int week, int order) => _existingDocs.any((d) => d.week == week && d.order == order && d.id != state.record?.id);

  // ───────────────────────────── Bước 2 ─────────────────────────────

  /// Chọn khối để sửa; khung xem trước nhảy tới slide chứa khối đó.
  void select(int section, int block) {
    final slides = buildSlides(state.doc);
    final i = slides.indexWhere((p) => p.sectionIndex == section && (p.blocks.any((e) => e.$1 == block) || p.blocks.isEmpty));
    emit(state.copyWith(selectedSection: section, selectedBlock: block, previewIndex: i >= 0 ? i : null));
  }

  /// Khung soạn khối vừa sửa thẳng vào JSON.
  void contentEdited() => _emitContent(state);

  void addBlock(String type) {
    if (state.sections.isEmpty) return;
    final blocks = state.blocksOf(state.selectedSection);
    final at = blocks.isEmpty ? 0 : state.selectedBlock + 1;
    blocks.insert(at, deepCopyJson(newBlockJson(type)));
    _emitContent(state);
    select(state.selectedSection, at);
  }

  void addSection() {
    final sections = state.json['sections'] is List<dynamic> ? state.json['sections'] as List<dynamic> : (state.json['sections'] = <dynamic>[]);
    sections.add(deepCopyJson({
      'title': 'SECTION ${sections.length + 1}',
      'blocks': [newBlockJson('heading')],
    }));
    _emitContent(state);
    select(sections.length - 1, 0);
  }

  /// Xoá khối đang chọn; section chỉ còn một khối thì xoá cả section (giữ ít nhất một section).
  void deleteBlock() {
    final sections = state.sections;
    if (sections.isEmpty) return;
    final blocks = state.blocksOf(state.selectedSection);
    var section = state.selectedSection;
    var block = state.selectedBlock;
    if (blocks.length > 1) {
      blocks.removeAt(block);
      block = (block - 1).clamp(0, blocks.length - 1);
    } else if (sections.length > 1) {
      sections.removeAt(section);
      section = (section - 1).clamp(0, sections.length - 1);
      block = 0;
    }
    _emitContent(state.copyWith(selectedSection: section, selectedBlock: block), replaced: true);
  }

  void moveBlock(int delta) {
    final blocks = state.blocksOf(state.selectedSection);
    final to = state.selectedBlock + delta;
    if (to < 0 || to >= blocks.length) return;
    blocks.insert(to, blocks.removeAt(state.selectedBlock));
    _emitContent(state.copyWith(selectedBlock: to), replaced: true);
  }

  void setJsonMode({required bool on}) => emit(state.copyWith(jsonMode: on, jsonCheck: null));

  /// JSON đầy đủ (thụt lề 2) kèm cài đặt hiển thị ở bước 3, cho tab "Nhập JSON".
  String prettyJson() => const JsonEncoder.withIndent('  ').convert(_fullJson(state));

  void clearJsonCheck() {
    if (state.jsonCheck != null) emit(state.copyWith(jsonCheck: null));
  }

  /// "Kiểm tra & áp dụng": hợp lệ thì thay nội dung (giữ id / tuần / số thứ tự của bản ghi).
  bool applyJsonText(String text) {
    final check = validateDocText(text);
    emit(state.copyWith(jsonCheck: check));
    if (!check.isValid) return false;
    final parsed = deepCopyJson(asJsonMap(jsonDecode(text))) as Map<String, dynamic>;
    final meta = DocMeta.fromJson(parsed['meta']);
    final isHtml = parsed['template'] == 'html';
    state.json
      ..['title'] = parsed['title']
      ..['template'] = parsed['template'] ?? 'custom'
      ..['sections'] = parsed['sections'] is List ? parsed['sections'] : <dynamic>[]
      ..['meta'] = meta.toJson();
    if (isHtml) {
      state.json
        ..['html'] = parsed['html']
        ..['htmlFileName'] = parsed['htmlFileName'];
    } else {
      state.json
        ..remove('html')
        ..remove('htmlFileName');
    }
    _emitContent(
      state.copyWith(
        templateId: isHtml ? 'html' : null,
        jsonMode: isHtml ? false : null, // tài liệu HTML không có tab JSON
        title: parsed['title'] as String? ?? '',
        fieldsEpoch: state.fieldsEpoch + 1,
        skill: meta.skill,
        defaultView: meta.defaultView,
        allowSwitch: meta.canSwitch,
        selectedSection: 0,
        selectedBlock: 0,
        previewIndex: 0,
      ),
      replaced: true,
    );
    return true;
  }

  /// "Lấy lại từ template": thay các section bằng khung của template đang chọn.
  void resetFromTemplate() {
    final template = templateById(state.templateId == 'import' ? 'blank' : state.templateId);
    state.json['sections'] = deepCopyJson(template.sections);
    _emitContent(state.copyWith(jsonCheck: null), replaced: true);
  }

  /// Bấm vào một lỗi: về bước 2, tab Form, chọn đúng khối có lỗi.
  void jumpToIssue(ValidationIssue issue) {
    final location = issue.location;
    if (location == null) return;
    final (section, block) = location;
    if (section >= state.sections.length) return;
    emit(state.copyWith(step: 2, jsonMode: false));
    select(section, block ?? 0);
  }

  // ───────────────────────────── Xem trước, bước 3 ─────────────────────────────

  void setPreviewView(DocViewMode view) => emit(state.copyWith(previewView: view));

  void setPreviewIndex(int index) => emit(state.copyWith(previewIndex: index));

  void setDefaultView(DocViewMode view) => _emitContent(state.copyWith(defaultView: view, previewView: view), save: false);

  void setAllowSwitch({required bool allow}) => _emitContent(state.copyWith(allowSwitch: allow), save: false);

  void setScheduleMode({required bool scheduled}) => emit(state.copyWith(scheduleMode: scheduled));

  void setScheduleAt(DateTime at) => emit(state.copyWith(scheduleAt: at));

  // ───────────────────────────── Điều hướng bước ─────────────────────────────

  /// "Tiếp tục" / "Xuất bản". [jsonText]: nội dung tab JSON nếu đang ở tab đó mà chưa bấm "Kiểm tra & áp dụng".
  Future<void> forward({String? jsonText}) async {
    switch (state.step) {
      case 1:
        if (await _commitStep1()) emit(state.copyWith(step: 2));
      case 2:
        if (state.jsonMode && state.jsonCheck == null && jsonText != null) applyJsonText(jsonText);
        if (!state.isPublishedDoc) await saveNow();
        emit(state.copyWith(step: 3, previewView: state.defaultView));
      default:
        await publish();
    }
  }

  void back() => emit(state.copyWith(step: (state.step - 1).clamp(1, 3)));

  /// Bấm thẳng vào một bước trên thanh bước (khi đang sửa).
  Future<void> goToStep(int step) async {
    if (step == 3 && state.step == 2 && !state.isPublishedDoc) await saveNow();
    emit(state.copyWith(step: step));
  }

  // ───────────────────────────── Lưu nháp ─────────────────────────────

  /// Lưu ngay, tuần tự: hai request cùng version chạy song song sẽ báo xung đột giả.
  Future<void> saveNow() async {
    while (_inflightSave != null) {
      await _inflightSave;
    }
    final save = _save();
    _inflightSave = save;
    try {
      await save;
    } finally {
      _inflightSave = null;
    }
  }

  /// Admin chọn ở hộp thoại xung đột: tải bản mới, hoặc ghi đè bằng bản của mình.
  Future<void> resolveConflict({required bool reload}) async {
    final current = _conflictCurrent;
    emit(state.copyWith(conflictMessage: null));
    if (current == null) return;
    _conflictCurrent = null;
    if (reload) {
      _emitContent(
        state.copyWith(json: deepCopyJson(current.content.value) as Map<String, dynamic>, version: current.version, saveState: SaveState.idle),
        replaced: true,
        save: false,
      );
      return;
    }
    emit(state.copyWith(version: current.version));
    await saveNow();
  }

  Future<void> _save() async {
    final record = state.record;
    if (record == null) return;
    _saveTimer?.cancel();
    emit(state.copyWith(saveState: SaveState.saving));
    final result = await _saveDraft.execute(record.id, content: DocJson(state.json), version: state.version);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(record: data, version: data.version, saveState: SaveState.saved, savedAt: DateTime.now()));
      case Failure(exception: final VersionConflictException conflict):
        _conflictCurrent = conflict.current;
        emit(state.copyWith(record: conflict.current, saveState: SaveState.error, conflictMessage: conflict.message));
      case Failure():
        emit(state.copyWith(saveState: SaveState.error));
    }
  }

  /// Tự lưu sau khi ngừng sửa [autosaveDelay]. Tài liệu đang phát hành: chỉ đánh dấu có thay đổi,
  /// áp dụng khi bấm "Cập nhật bản phát hành".
  void _scheduleSave() {
    if (state.record == null) return;
    if (state.isPublishedDoc) {
      emit(state.copyWith(dirtyRelease: true));
      return;
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(autosaveDelay, () => unawaited(saveNow()));
  }

  // ───────────────────────────── Xuất bản ─────────────────────────────

  /// Lưu bản mới nhất rồi xuất bản / hẹn giờ; tài liệu đang phát hành thì "Cập nhật bản phát hành".
  Future<void> publish() async {
    final record = state.record;
    if (record == null || state.isPublishing) return;
    final meta = state.json['meta'] as Map<String, dynamic>;
    meta['defaultView'] = state.defaultView.name;
    meta['allowedViews'] = state.allowSwitch ? ['slide', 'doc'] : [state.defaultView.name];
    emit(state.copyWith(isPublishing: true));
    _saveTimer?.cancel();
    while (_inflightSave != null) {
      await _inflightSave;
    }
    final saved = await _saveDraft.execute(record.id, content: DocJson(state.json), version: state.version);
    if (isClosed) return;
    if (saved case Failure(:final exception)) {
      emit(state.copyWith(isPublishing: false, notice: UiNotice.next(state.notice, exception.message)));
      return;
    }
    final savedVersion = switch (saved) {
      Success(:final data) => data.version,
      Failure() => state.version,
    };
    final result = record.status == DocStatus.published
        ? await _releaseDoc.execute(record.id)
        : await _publishDoc.execute(record.id, at: state.scheduleMode ? state.scheduleAt : null);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(record: data, version: data.version, isPublishing: false, published: true, dirtyRelease: false));
      case Failure(:final exception):
        emit(state.copyWith(version: savedVersion, isPublishing: false, notice: UiNotice.next(state.notice, exception.message)));
    }
  }

  // ───────────────────────────── Nội bộ ─────────────────────────────

  /// Nội dung vừa đổi: tính lại tài liệu, kiểm tra lỗi, dung lượng HTML; [replaced] = thay từ ngoài
  /// (ô nhập dựng lại); [save] = lên lịch tự lưu.
  void _emitContent(DocCreatorState next, {bool replaced = false, bool save = true}) {
    emit(next.copyWith(
      doc: WeeklyDoc.fromJson(next.json),
      validation: validateDocJson(_fullJson(next)),
      htmlSize: _htmlSizeOf(next.html),
      revision: next.revision + 1,
      epoch: replaced ? next.epoch + 1 : null,
    ));
    if (save) _scheduleSave();
  }

  /// JSON đầy đủ kèm cài đặt hiển thị ở bước 3.
  static Map<String, dynamic> _fullJson(DocCreatorState s) {
    final full = deepCopyJson(s.json) as Map<String, dynamic>;
    final meta = full['meta'] is Map<String, dynamic> ? full['meta'] as Map<String, dynamic> : (full['meta'] = <String, dynamic>{});
    meta['defaultView'] = s.defaultView.name;
    meta['allowedViews'] = s.allowSwitch ? ['slide', 'doc'] : [s.defaultView.name];
    return full;
  }

  /// Chuỗi html có thể tới 5 MB: chỉ đếm lại khi đổi file.
  int _htmlSizeOf(String html) {
    if (!identical(html, _sizedHtml)) {
      _sizedHtml = html;
      _sizedBytes = utf8Length(html);
    }
    return _sizedBytes;
  }

  /// Rời màn khi còn thay đổi đang chờ lưu: lưu ngay.
  @override
  Future<void> close() {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer?.cancel();
      final record = state.record;
      if (record != null && !state.isPublishedDoc) {
        unawaited(_saveDraft.execute(record.id, content: DocJson(state.json), version: state.version));
      }
    }
    return super.close();
  }
}
