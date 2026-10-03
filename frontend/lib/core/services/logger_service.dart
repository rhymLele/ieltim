import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Log tập trung của app (FLUTTER_STANDARDS mục 10), thay cho `print` / `debugPrint`.
///
/// Bản release chỉ giữ warning / error. Không truyền token, mật khẩu hay dữ liệu cá nhân vào log.
class LoggerService {
  LoggerService([Logger? logger])
      : _logger = logger ??
            Logger(
              level: kReleaseMode ? Level.warning : Level.debug,
              printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5, noBoxingByDefault: true),
            );

  final Logger _logger;

  void debug(String message) => _logger.d(message);

  void info(String message) => _logger.i(message);

  void warning(String message, [Object? error, StackTrace? stackTrace]) => _logger.w(message, error: error, stackTrace: stackTrace);

  void error(String message, [Object? error, StackTrace? stackTrace]) => _logger.e(message, error: error, stackTrace: stackTrace);
}
