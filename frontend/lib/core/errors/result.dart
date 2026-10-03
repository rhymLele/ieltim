import 'app_exception.dart';

/// Kết quả của UseCase / Repository: không ném exception ra khỏi tầng data (FLUTTER_STANDARDS mục 6).
///
/// ```dart
/// switch (await getWeeks.execute()) {
///   case Success(:final data): emit(...);
///   case Failure(:final exception): emit(... exception.message ...);
/// }
/// ```
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.exception);
  final AppException exception;
}
