import '../../features/annotate/data/datasources/fake_annotate_remote_datasource.dart';
import '../../features/annotate/data/repositories/annotate_repository_impl.dart';
import '../../features/annotate/domain/repositories/annotate_repository.dart';
import '../../features/vocab/data/repositories/fake_vocab_repository.dart';
import '../../features/vocab/data/repositories/vocab_repository_impl.dart';
import '../../features/vocab/domain/repositories/vocab_repository.dart';
import '../../features/weekly_docs/data/repositories/fake_weekly_docs_repository.dart';
import '../../features/weekly_docs/data/repositories/weekly_docs_repository_impl.dart';
import '../../features/weekly_docs/domain/repositories/weekly_docs_repository.dart';
import '../network/api_client.dart';
import '../services/analytics_service.dart';
import '../services/logger_service.dart';
import '../services/tts_service.dart';
import 'service_locator.dart';

/// `flutter run --dart-define=WEEKLY_DOCS_FAKE=true`: Tài liệu theo tuần, ghi chú, sổ từ dùng dữ liệu giả, xem UI không cần BE.
const _useFakeWeeklyDocs = bool.fromEnvironment('WEEKLY_DOCS_FAKE');

/// Đăng ký service dùng chung, gọi một lần trong `main()` trước `runApp`.
void setupDependencies() {
  registerSingleton<LoggerService>(LoggerService());
  registerSingleton<ApiClient>(ApiClient());
  registerSingleton<TtsService>(TtsService());
  registerSingleton<AnalyticsService>(AnalyticsService());
  registerSingleton<WeeklyDocsRepository>(_useFakeWeeklyDocs ? FakeWeeklyDocsRepository() : WeeklyDocsRepositoryImpl());
  registerSingleton<VocabRepository>(_useFakeWeeklyDocs ? FakeVocabRepository() : VocabRepositoryImpl());
  registerSingleton<AnnotateRepository>(AnnotateRepositoryImpl(remote: _useFakeWeeklyDocs ? FakeAnnotateRemoteDataSource() : null));
}
