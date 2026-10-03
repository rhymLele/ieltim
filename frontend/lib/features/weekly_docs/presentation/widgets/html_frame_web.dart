// html_frame_web.dart — Bản web của HtmlFrame: iframe srcdoc có sandbox.
// KHÔNG thêm allow-same-origin: JS trong file vẫn chạy nhưng ở origin rỗng,
// không đọc được token, cookie, localStorage hay parent.document của app.

import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class HtmlFrame extends StatefulWidget {
  const HtmlFrame({super.key, required this.html, this.autofocus = false});

  final String html;

  /// Đưa focus vào file khi tải xong để phím ← → của file chạy ngay (màn đọc).
  final bool autofocus;

  @override
  State<HtmlFrame> createState() => _HtmlFrameState();
}

class _HtmlFrameState extends State<HtmlFrame> {
  web.HTMLIFrameElement? _frame;

  void _onCreated(Object element) {
    final f = element as web.HTMLIFrameElement;
    f
      ..setAttribute('sandbox', 'allow-scripts allow-modals')
      ..setAttribute('referrerpolicy', 'no-referrer')
      ..title = 'Nội dung tài liệu'
      ..srcdoc = widget.html.toJS;
    f.style
      ..border = '0'
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = '#ffffff';
    if (widget.autofocus) f.onload = (() => f.focus()).toJS;
    _frame = f;
  }

  @override
  void didUpdateWidget(HtmlFrame old) {
    super.didUpdateWidget(old);
    if (old.html != widget.html) _frame?.srcdoc = widget.html.toJS;
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(tagName: 'iframe', onElementCreated: _onCreated);
}
