// html_frame_web.dart — Bản web của HtmlFrame: iframe srcdoc có sandbox.
// KHÔNG thêm allow-same-origin: JS trong file vẫn chạy nhưng ở origin rỗng,
// không đọc được token, cookie, localStorage hay parent.document của app.
// Ghi chú (bôi đen, highlight): script cầu nối trong file nói chuyện với app qua postMessage;
// app chỉ nhận tin từ đúng iframe này và đúng nguồn 'ieltshub-annot'.

import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../../../../core/theme/app_colors.dart';
import 'annotate/html_bridge.dart';
import 'html_bridge_controller.dart';

class HtmlFrame extends StatefulWidget {
  const HtmlFrame({super.key, required this.html, this.autofocus = false, this.onBridgeMessage, this.bridge, this.onLoaded});

  final String html;

  /// Đưa focus vào file khi tải xong để phím ← → của file chạy ngay (màn đọc).
  final bool autofocus;

  /// Có giá trị = chèn script cầu nối và nhận tin từ file (bôi đen, cuộn, chạm highlight).
  final ValueChanged<Map<String, Object?>>? onBridgeMessage;

  /// Gửi lệnh vào file (áp highlight, bỏ vùng chọn, khoá cuộn…).
  final HtmlBridgeController? bridge;

  /// File tải xong (gửi highlight đã lưu vào).
  final VoidCallback? onLoaded;

  @override
  State<HtmlFrame> createState() => _HtmlFrameState();
}

class _HtmlFrameState extends State<HtmlFrame> {
  web.HTMLIFrameElement? _frame;
  JSFunction? _listener;

  bool get _bridged => widget.onBridgeMessage != null;

  String get _source => _bridged ? injectAnnotateBridge(widget.html) : widget.html;

  void _onCreated(Object element) {
    final f = element as web.HTMLIFrameElement;
    f
      ..setAttribute('sandbox', 'allow-scripts allow-modals')
      ..setAttribute('referrerpolicy', 'no-referrer')
      ..title = 'Nội dung tài liệu'
      ..srcdoc = _source.toJS;
    f.style
      ..border = '0'
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = _cssHex(AppColors.cardSurface);
    f.onload = (() {
      if (widget.autofocus) f.focus();
      widget.onLoaded?.call();
    }).toJS;
    _frame = f;
    if (_bridged) {
      final listener = ((web.MessageEvent e) => _onMessage(e)).toJS;
      _listener = listener;
      web.window.addEventListener('message', listener);
    }
    widget.bridge?.attach(
      send: (command) => f.contentWindow?.postMessage(command.jsify(), '*'.toJS),
      setPassthrough: (on) => f.style.pointerEvents = on ? 'none' : '',
    );
  }

  void _onMessage(web.MessageEvent e) {
    final window = _frame?.contentWindow;
    // Chỉ nhận tin từ đúng iframe này.
    if (window == null || !e.source.strictEquals(window).toDart) return;
    final data = e.data.dartify();
    if (data is! Map || data['source'] != kAnnotateMessageSource) return;
    widget.onBridgeMessage?.call({for (final entry in data.entries) entry.key.toString(): entry.value});
  }

  @override
  void didUpdateWidget(HtmlFrame old) {
    super.didUpdateWidget(old);
    if (old.html != widget.html) _frame?.srcdoc = _source.toJS;
    if (!identical(old.bridge, widget.bridge)) {
      old.bridge?.detach();
      final f = _frame;
      if (f != null) {
        widget.bridge?.attach(
          send: (command) => f.contentWindow?.postMessage(command.jsify(), '*'.toJS),
          setPassthrough: (on) => f.style.pointerEvents = on ? 'none' : '',
        );
      }
    }
  }

  @override
  void dispose() {
    final listener = _listener;
    if (listener != null) web.window.removeEventListener('message', listener);
    widget.bridge?.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(tagName: 'iframe', onElementCreated: _onCreated);
}

/// Màu cho thuộc tính CSS của iframe (vd `#ffffff`).
String _cssHex(Color color) => '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
