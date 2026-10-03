/// Kết quả "Hoàn thành": chặng Vũ Môn của tuần lịch và streak (file 1 mục 6).
class CompleteResult {
  const CompleteResult({
    required this.completedNow,
    required this.stageDone,
    required this.stageGoal,
    required this.justPassedGate,
    required this.streak,
  });

  final bool completedNow;
  final int stageDone;
  final int stageGoal;
  final bool justPassedGate;
  final int streak;
}

/// Phản hồi khi trả lời một câu trắc nghiệm.
class QuizFeedback {
  const QuizFeedback({required this.correct, required this.answer, this.explain});

  final bool correct;
  final int answer;
  final String? explain;
}

/// Kết quả lưu từ vựng của tài liệu vào Sổ từ.
class VocabSaveResult {
  const VocabSaveResult({required this.added, required this.existed, required this.total});

  final int added;
  final int existed;
  final int total;
}
