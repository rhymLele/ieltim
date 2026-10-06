/// Loại tài liệu (`category` của BE): bài học ("Tài liệu") hoặc bài tập về nhà ("Bài tập", tag HOMEWORK).
/// Mỗi loại đánh số riêng trong tuần: tuần 12 có thể có cả Tài liệu 1 lẫn Bài tập 1.
enum DocCategory {
  lesson,
  homework;

  /// Giá trị lạ / thiếu coi như tài liệu thường.
  static DocCategory parse(Object? value) => value == 'homework' ? homework : lesson;

  /// Ghép với số thứ tự: "Tài liệu 1", "Bài tập 1".
  String get label => switch (this) {
        DocCategory.lesson => 'Tài liệu',
        DocCategory.homework => 'Bài tập',
      };

  /// Mã công khai như BE: `w12-doc1`, `w12-hw1`.
  String code(int week, int order) => 'w$week-${this == homework ? 'hw' : 'doc'}$order';
}
