/// Kiểu render của một khối.
enum RenderMode { slide, doc }

/// Ngữ cảnh render một khối, dùng chung cho [DocView] và [SlideView].
///
/// Hai view dùng **chung** một BlockContext (cùng các callback) nên khi chuyển
/// view, đáp án quiz / section hiện tại được giữ (state nằm ở bloc, không nằm
/// trong widget).
class BlockContext {
  const BlockContext({
    required this.mode,
    this.scale = 1.0,
    this.blockKey = '',
    this.selectedKey,
    this.onQuizAnswer,
    this.quizAnswerFor,
    this.onBlockSelected,
    this.onOpenLink,
  });

  final RenderMode mode;

  /// Hệ số thu phóng (dùng trong SlideView).
  final double scale;

  /// Khoá của khối (xem [blockKey]).
  final String blockKey;

  /// Khối đang được chọn ở chế độ admin (để tô viền vàng).
  final String? selectedKey;

  /// Người dùng chọn đáp án quiz (index) cho khối [blockKey].
  final void Function(String blockKey, int selectedIndex)? onQuizAnswer;

  /// Đọc đáp án đang chọn cho khối (null = chưa chọn).
  final int? Function(String blockKey)? quizAnswerFor;

  /// Bấm chọn khối (admin) — preview nhảy tới slide chứa khối.
  final void Function(String blockKey)? onBlockSelected;

  /// Mở link từ markdown.
  final void Function(String url)? onOpenLink;

  bool get isSelected =>
      blockKey.isNotEmpty && selectedKey != null && blockKey == selectedKey;

  BlockContext copyWith({
    RenderMode? mode,
    double? scale,
    String? blockKey,
  }) =>
      BlockContext(
        mode: mode ?? this.mode,
        scale: scale ?? this.scale,
        blockKey: blockKey ?? this.blockKey,
        selectedKey: selectedKey,
        onQuizAnswer: onQuizAnswer,
        quizAnswerFor: quizAnswerFor,
        onBlockSelected: onBlockSelected,
        onOpenLink: onOpenLink,
      );
}
