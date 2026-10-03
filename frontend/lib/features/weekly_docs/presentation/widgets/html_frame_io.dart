// html_frame_io.dart — Bản Android/iOS của HtmlFrame: WebView nạp chuỗi HTML.
// Chặn mọi điều hướng ra ngoài (chỉ cho about:, data: và anchor #), không gắn JavaScriptChannel.

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_tokens.dart';

class HtmlFrame extends StatefulWidget {
  const HtmlFrame({super.key, required this.html, this.autofocus = false});

  final String html;

  /// Chỉ có tác dụng trên web (focus iframe); WebView nhận chạm trực tiếp.
  final bool autofocus;

  @override
  State<HtmlFrame> createState() => _HtmlFrameState();
}

class _HtmlFrameState extends State<HtmlFrame> {
  late final WebViewController _c = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(AppColors.surface)
    ..setNavigationDelegate(NavigationDelegate(onNavigationRequest: (r) => isAllowedHtmlNavigation(r.url) ? NavigationDecision.navigate : NavigationDecision.prevent))
    ..loadHtmlString(widget.html);

  @override
  void didUpdateWidget(HtmlFrame old) {
    super.didUpdateWidget(old);
    if (old.html != widget.html) _c.loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _c);
}

/// loadHtmlString chạy ở about:blank → anchor `#` là about:blank#…; mọi http(s), tel:, intent: … đều chặn.
bool isAllowedHtmlNavigation(String url) {
  final scheme = Uri.tryParse(url)?.scheme.toLowerCase();
  return scheme == 'about' || scheme == 'data';
}
