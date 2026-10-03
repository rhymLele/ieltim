/// Nơi DUY NHẤT đăng ký / lấy singleton service (FLUTTER_STANDARDS mục 21.1).
///
/// Project dùng Bloc (không dùng GetX) nên registry là một bảng theo kiểu dữ liệu, không thêm package DI.
/// Đăng ký đúng một lần trong `setupDependencies()` (main); nơi dùng resolve qua giá trị mặc định
/// của constructor, không gọi `getSingleton` rải rác trong logic hay trong `build()`.
library;

final _singletons = <Type, Object>{};

void registerSingleton<T extends Object>(T instance) {
  _singletons[T] = instance;
}

T getSingleton<T extends Object>() {
  final instance = _singletons[T];
  if (instance is T) return instance;
  throw StateError('Chưa đăng ký $T. Gọi registerSingleton<$T>() trong setupDependencies().');
}

/// Chỉ dùng trong test: xoá các đăng ký để thay bằng bản giả.
void resetSingletons() => _singletons.clear();
