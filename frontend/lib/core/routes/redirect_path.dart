/// Trang cần quay lại sau khi đăng nhập (`/access?from=…`). Chỉ nhận đường dẫn nội bộ của app,
/// không nhận `//host` hay link ngoài, để `from` không bị lợi dụng chuyển hướng sang trang khác.
String? safeRedirectPath(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) return null;
  if (from == '/' || from.startsWith('/access')) return null;
  return from;
}

/// `/access`, kèm `?from=` khi người dùng đang mở một trang cụ thể (link chia sẻ, F5).
String accessPathFor(String location) {
  final from = safeRedirectPath(location);
  return from == null || from == '/home' ? '/access' : Uri(path: '/access', queryParameters: {'from': from}).toString();
}
