/// Trạng thái vòng đời tài liệu (file 7 mục 1).
enum DocStatus {
  draft,
  scheduled,
  published,
  archived;

  static DocStatus parse(String? value) => values.firstWhere((s) => s.name == value, orElse: () => draft);

  String get label => switch (this) {
        DocStatus.draft => 'Nháp',
        DocStatus.scheduled => 'Đã hẹn',
        DocStatus.published => 'Đã xuất bản',
        DocStatus.archived => 'Đã gỡ',
      };
}
