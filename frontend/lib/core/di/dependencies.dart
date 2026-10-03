import '../../features/weekly_docs/data/repositories/fake_weekly_docs_repository.dart';
import '../../features/weekly_docs/data/repositories/weekly_docs_repository_impl.dart';
import '../../features/weekly_docs/domain/repositories/weekly_docs_repository.dart';
import '../network/api_client.dart';
import '../services/logger_service.dart';
import '../services/tts_service.dart';
import 'service_locator.dart';

/// `flutter run --dart-define=WEEKLY_DOCS_FAKE=true`: Tài liệu theo tuần dùng dữ liệu giả, xem UI không cần BE.
const _useFakeWeeklyDocs = bool.fromEnvironment('WEEKLY_DOCS_FAKE');

/// Đăng ký service dùng chung, gọi một lần trong `main()` trước `runApp`.
void setupDependencies() {
  registerSingleton<LoggerService>(LoggerService());
  registerSingleton<ApiClient>(ApiClient());
  registerSingleton<TtsService>(TtsService());
  registerSingleton<WeeklyDocsRepository>(_useFakeWeeklyDocs ? FakeWeeklyDocsRepository() : WeeklyDocsRepositoryImpl());
}
