// annotation_controller.dart — Trạng thái lớp ghi chú của 1 slide: công cụ, màu, nét vẽ, hoàn tác.
// Lưu trữ / đồng bộ BE KHÔNG nằm ở đây: lắng nghe [onChanged] để debounce rồi gọi API (xem prompt logic).
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'annotate_theme.dart';
import 'models.dart';

class AnnotationController extends ChangeNotifier {
  AnnotationController({SlideAnnotations? initial, this.onChanged}) : _data = initial ?? const SlideAnnotations();

  /// Gọi mỗi khi nội dung ghi chú thay đổi (không gọi khi chỉ đổi công cụ / màu).
  final ValueChanged<SlideAnnotations>? onChanged;

  SlideAnnotations _data;
  final List<SlideAnnotations> _undo = [];
  AnnotationTool _tool = AnnotationTool.view;
  int _colorIndex = 0;
  int? _activePin;

  // Nét đang vẽ (chưa thả tay)
  List<Offset>? _drawing;
  Offset? _ellipseStart;
  Rect? _ellipseDraft;

  SlideAnnotations get data => _data;
  AnnotationTool get tool => _tool;
  int get colorIndex => _colorIndex;
  Color get color => kPenColors[_colorIndex];
  int? get activePin => _activePin;
  bool get canUndo => _undo.isNotEmpty;
  List<Offset>? get drawing => _drawing;
  Rect? get ellipseDraft => _ellipseDraft;

  set tool(AnnotationTool t) {
    if (_tool == t) return;
    _tool = t;
    notifyListeners();
  }

  set colorIndex(int i) {
    _colorIndex = i.clamp(0, kPenColors.length - 1);
    notifyListeners();
  }

  set activePin(int? i) {
    _activePin = i;
    notifyListeners();
  }

  /// Thay toàn bộ dữ liệu (khi tải từ BE / chuyển slide). Xoá lịch sử hoàn tác.
  void load(SlideAnnotations data) {
    _data = data;
    _undo.clear();
    _activePin = null;
    _drawing = null;
    _ellipseDraft = null;
    notifyListeners();
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  void _commit(SlideAnnotations next) {
    _undo.add(_data);
    if (_undo.length > 50) _undo.removeAt(0);
    _data = next;
    notifyListeners();
    onChanged?.call(_data);
  }

  // ── Vẽ bút / dạ quang ──
  void strokeStart(Offset p) {
    _drawing = [p];
    notifyListeners();
  }

  void strokeUpdate(Offset p) {
    final d = _drawing;
    if (d == null) return;
    if (d.isNotEmpty && (d.last - p).distance < 0.002) return; // bỏ điểm quá sát
    d.add(p);
    notifyListeners();
  }

  void strokeEnd() {
    final d = _drawing;
    _drawing = null;
    if (d == null || d.length < 2) {
      notifyListeners();
      return;
    }
    _commit(_data.copyWith(strokes: [
      ..._data.strokes,
      StrokeMark(id: _id(), points: List.unmodifiable(d), color: color, marker: _tool == AnnotationTool.marker),
    ]));
  }

  // ── Khoanh tròn ──
  void ellipseStart(Offset p) {
    _ellipseStart = p;
    _ellipseDraft = Rect.fromPoints(p, p);
    notifyListeners();
  }

  void ellipseUpdate(Offset p) {
    final s = _ellipseStart;
    if (s == null) return;
    _ellipseDraft = Rect.fromPoints(s, p);
    notifyListeners();
  }

  void ellipseEnd() {
    final r = _ellipseDraft;
    _ellipseStart = null;
    _ellipseDraft = null;
    if (r == null || (r.width < 0.01 && r.height < 0.01)) {
      notifyListeners();
      return;
    }
    _commit(_data.copyWith(ellipses: [..._data.ellipses, EllipseMark(id: _id(), rect: r, color: color)]));
  }

  // ── Chữ ──
  void addText(Offset at, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _commit(_data.copyWith(texts: [..._data.texts, TextMark(id: _id(), at: at, text: t, color: color)]));
  }

  // ── Ghim ghi chú ──
  void addPin(Offset at) {
    final pins = [..._data.pins, PinNote(id: _id(), at: at, createdAt: DateTime.now())];
    _activePin = pins.length - 1;
    _commit(_data.copyWith(pins: pins));
  }

  /// Sửa nội dung ghi chú: không đưa vào lịch sử hoàn tác từng ký tự.
  void updatePinText(int index, String text) {
    if (index < 0 || index >= _data.pins.length) return;
    final pins = [..._data.pins];
    pins[index] = pins[index].copyWith(text: text);
    _data = _data.copyWith(pins: pins);
    notifyListeners();
    onChanged?.call(_data);
  }

  void removePin(int index) {
    if (index < 0 || index >= _data.pins.length) return;
    _activePin = null;
    _commit(_data.copyWith(pins: [..._data.pins]..removeAt(index)));
  }

  void undo() {
    if (_undo.isEmpty) return;
    _data = _undo.removeLast();
    if (_activePin != null && _activePin! >= _data.pins.length) _activePin = null;
    notifyListeners();
    onChanged?.call(_data);
  }

  void clear() {
    if (_data.isEmpty) return;
    _commit(const SlideAnnotations());
  }
}
