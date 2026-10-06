import 'annotate/html_bridge.dart';

/// Kênh hai chiều với script cầu nối trong file HTML (web: postMessage với iframe, Android / iOS: JavaScriptChannel).
/// [HtmlFrame] gắn cách gửi khi hiển thị; trước đó mọi lệnh bị bỏ qua.
class HtmlBridgeController {
  void Function(Map<String, Object?> command)? _send;
  void Function(bool passthrough)? _setPassthrough;

  bool get isAttached => _send != null;

  /// Gửi lệnh vào file (tự gắn `source: 'ieltshub-host'`).
  void send(Map<String, Object?> command) => _send?.call({...command, 'source': kAnnotateHostSource});

  /// Web: cho chuột / chạm đi xuyên qua iframe tới lớp vẽ phía trên (đang cầm bút). Android / iOS không cần.
  void setPointerPassthrough({required bool enabled}) => _setPassthrough?.call(enabled);

  void attach({required void Function(Map<String, Object?> command) send, void Function(bool passthrough)? setPassthrough}) {
    _send = send;
    _setPassthrough = setPassthrough;
  }

  void detach() {
    _send = null;
    _setPassthrough = null;
  }
}
