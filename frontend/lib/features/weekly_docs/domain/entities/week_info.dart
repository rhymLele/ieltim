/// Một tuần học (file 1 mục 3.1).
class WeekInfo {
  const WeekInfo({required this.number, required this.start, this.stageGoal = 5, this.locked, this.docTotal, this.docDone});

  final int number;
  final DateTime start;
  final int stageGoal;

  /// Trạng thái do máy chủ tính theo giờ Việt Nam; null thì so ngày bắt đầu với hôm nay.
  final bool? locked;

  /// Số tài liệu đã xuất bản / đã học của tuần (máy chủ tính sẵn); null thì màn hình tự đếm.
  final int? docTotal;
  final int? docDone;

  DateTime get end => start.add(const Duration(days: 6));
  bool get isLocked => locked ?? DateTime.now().isBefore(start);

  String get rangeLabel => '${_dayMonth(start)} – ${_dayMonth(end)}';
  String get opensLabel => 'Mở ${_weekday(start)}';

  static String _dayMonth(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  static String _weekday(DateTime d) => const ['thứ Hai', 'thứ Ba', 'thứ Tư', 'thứ Năm', 'thứ Sáu', 'thứ Bảy', 'Chủ nhật'][d.weekday - 1];
}

/// Danh sách tuần kèm tuần chứa hôm nay.
class WeekList {
  const WeekList({required this.weeks, this.currentWeek});

  final List<WeekInfo> weeks;

  /// Tuần chứa hôm nay theo máy chủ; null khi chưa có tuần nào chứa hôm nay.
  final int? currentWeek;

  /// Tuần mặc định để mở: tuần hiện tại, không có thì tuần mở gần nhất; 0 khi chưa có tuần nào.
  int get currentWeekNumber {
    final current = currentWeek;
    if (current != null) return current;
    final open = weeks.where((w) => !w.isLocked);
    if (open.isNotEmpty) return open.last.number;
    return weeks.isEmpty ? 0 : weeks.first.number;
  }

  WeekInfo? byNumber(int number) {
    for (final w in weeks) {
      if (w.number == number) return w;
    }
    return null;
  }
}
