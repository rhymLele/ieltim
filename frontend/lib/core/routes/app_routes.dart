/// Đường dẫn route của app, khai báo tập trung (FLUTTER_STANDARDS mục 4, 18).
///
/// Chuyển màn hình luôn đi qua router bằng `context.go(...)` (URL trên web đổi theo) —
/// không `Navigator.push(MaterialPageRoute(...))`. Trang con khai báo lồng dưới trang cha
/// (`…Segment`, đường dẫn tương đối) nên mở thẳng link vẫn có trang cha bên dưới để Quay lại.
/// Hằng `…Pattern` / `…Segment` dùng khai báo `GoRoute`; hàm cùng tên dựng đường dẫn cụ thể.
abstract final class AppRoutes {
  static const access = '/access';
  static const home = '/home';
  static const resources = '/resources';
  static const articles = '/articles';
  static const wordbook = '/wordbook';
  static const search = '/search';
  static const lessonPattern = '/lessons/:id';
  static const documentPattern = '/documents/:id';

  // Tài liệu theo tuần (người học)
  static const weekly = '/weekly';
  static const weeklyDocSegment = 'doc/:id';
  static String weeklyDoc(String id) => '/weekly/doc/$id';
  static const weeklyDocDoneSegment = 'done';
  static String weeklyDocDone(String id) => '/weekly/doc/$id/done';

  // Admin
  static const admin = '/admin';
  static const adminDocumentCreate = '/admin/documents/create';
  static const adminDocumentEditPattern = '/admin/documents/:id/edit';
  static const adminVocabularies = '/admin/vocabularies';
  static const adminVocabularyCreate = '/admin/vocabularies/create';
  static const adminVocabularyEditPattern = '/admin/vocabularies/:id/edit';
  static const adminSentencePatterns = '/admin/sentence-patterns';
  static const adminSentencePatternCreate = '/admin/sentence-patterns/create';
  static const adminSentencePatternEditPattern = '/admin/sentence-patterns/:id/edit';
  static const adminTags = '/admin/tags';
  static const adminAccessKeys = '/admin/access-keys';

  // Tài liệu theo tuần (admin)
  static const adminWeeklyDocs = '/admin/weekly-docs';
  static const adminWeeklyDocCreateSegment = 'create';

  /// Tạo tài liệu; `week` là tuần gợi ý sẵn ở bước 1, `homework` chọn sẵn loại Bài tập.
  static String adminWeeklyDocCreate({int? week, bool homework = false}) {
    final query = [if (week != null) 'week=$week', if (homework) 'category=homework'];
    return query.isEmpty ? '$adminWeeklyDocs/create' : '$adminWeeklyDocs/create?${query.join('&')}';
  }

  static const adminWeeklyDocEditSegment = ':id/edit';
  static String adminWeeklyDocEdit(String id) => '$adminWeeklyDocs/$id/edit';
  static const adminWeeklyDocPreviewSegment = ':id/preview';
  static String adminWeeklyDocPreview(String id) => '$adminWeeklyDocs/$id/preview';
}
