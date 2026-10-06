// html_frame_io.dart — Bản Android/iOS của HtmlFrame: WebView nạp chuỗi HTML.
// Chặn mọi điều hướng ra ngoài (chỉ cho about:, data: và anchor #). Chỉ một JavaScriptChannel
// (IELTSHubAnnot, khi bật ghi chú) cho script cầu nối báo bôi đen / cuộn / chạm highlight.

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_tokens.dart';
import 'annotate/html_bridge.dart';
import 'html_bridge_controller.dart';

class HtmlFrame extends StatefulWidget {
  const HtmlFrame({super.key, required this.html, this.autofocus = false, this.onBridgeMessage, this.bridge, this.onLoaded});

  final String html;

  /// Chỉ có tác dụng trên web (focus iframe); WebView nhận chạm trực tiếp.
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
  late final WebViewController _c = _create();

  bool get _bridged => widget.onBridgeMessage != null;

  String get _source => _bridged ? injectAnnotateBridge(widget.html) : widget.html;

  WebViewController _create() {
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.cardSurface)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (r) => isAllowedHtmlNavigation(r.url) ? NavigationDecision.navigate : NavigationDecision.prevent,
        onPageFinished: (_) => widget.onLoaded?.call(),
      ));
    if (_bridged) c.addJavaScriptChannel(kAnnotateChannel, onMessageReceived: _onMessage);
    c.loadHtmlString(_source);
    widget.bridge?.attach(send: _send);
    return c;
  }

  void _send(Map<String, Object?> command) => _c.runJavaScript('window.__ihAnnot&&window.__ihAnnot(${jsonEncode(command)})');

  void _onMessage(JavaScriptMessage message) {
    final Object? data;
    try {
      data = jsonDecode(message.message);
    } on FormatException {
      return;
    }
    if (data is! Map<String, dynamic> || data['source'] != kAnnotateMessageSource) return;
    widget.onBridgeMessage?.call(data);
  }

  @override
  void initState() {
    super.initState();
    _c; // tạo WebView + gắn kênh ngay
  }

  @override
  void didUpdateWidget(HtmlFrame old) {
    super.didUpdateWidget(old);
    if (old.html != widget.html) _c.loadHtmlString(_source);
    if (!identical(old.bridge, widget.bridge)) {
      old.bridge?.detach();
      widget.bridge?.attach(send: _send);
    }
  }

  @override
  void dispose() {
    widget.bridge?.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _c);
}

/// loadHtmlString chạy ở about:blank → anchor `#` là about:blank#…; mọi http(s), tel:, intent: … đều chặn.
bool isAllowedHtmlNavigation(String url) {
  final scheme = Uri.tryParse(url)?.scheme.toLowerCase();
  return scheme == 'about' || scheme == 'data';
}
