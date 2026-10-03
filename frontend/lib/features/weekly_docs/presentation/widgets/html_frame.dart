// html_frame.dart — Chạy nguyên file HTML của tài liệu, tách khỏi app (file 9 mục 6).
// Web: <iframe srcdoc sandbox="allow-scripts allow-modals"> · Android/iOS: webview_flutter.

export 'html_frame_io.dart' if (dart.library.js_interop) 'html_frame_web.dart';
