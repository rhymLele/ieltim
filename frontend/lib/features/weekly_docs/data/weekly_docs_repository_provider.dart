import 'api_weekly_docs_repository.dart';
import 'fake_weekly_docs_repository.dart';
import 'weekly_docs_repository.dart';

/// Singleton repository cho weekly_docs. Mặc định gọi BE;
/// `flutter run --dart-define=WEEKLY_DOCS_FAKE=true` dùng dữ liệu giả để xem trước UI không cần BE.
WeeklyDocsRepository get weeklyDocsRepo => _instance;
final WeeklyDocsRepository _instance = const bool.fromEnvironment('WEEKLY_DOCS_FAKE') ? FakeWeeklyDocsRepository() : ApiWeeklyDocsRepository();
