import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/learning_results.dart';

part 'learning_result_models.g.dart';

/// `POST /weekly/documents/:id/quiz-answers`.
@JsonSerializable(createToJson: false)
class QuizFeedbackModel {
  const QuizFeedbackModel({required this.correct, required this.answer, this.explain});

  factory QuizFeedbackModel.fromJson(Map<String, dynamic> json) => _$QuizFeedbackModelFromJson(json);

  final bool correct;
  final int answer;
  final String? explain;

  QuizFeedback toEntity() => QuizFeedback(correct: correct, answer: answer, explain: explain);
}

@JsonSerializable(createToJson: false)
class WeekStageModel {
  const WeekStageModel({required this.done, required this.goal, required this.justPassedGate});

  factory WeekStageModel.fromJson(Map<String, dynamic> json) => _$WeekStageModelFromJson(json);

  final int done;
  final int goal;
  @JsonKey(defaultValue: false)
  final bool justPassedGate;
}

/// `POST /weekly/documents/:id/complete`.
@JsonSerializable(createToJson: false)
class CompleteResultModel {
  const CompleteResultModel({required this.completedNow, required this.weekStage, required this.streak});

  factory CompleteResultModel.fromJson(Map<String, dynamic> json) => _$CompleteResultModelFromJson(json);

  final bool completedNow;
  final WeekStageModel weekStage;
  final int streak;

  CompleteResult toEntity() => CompleteResult(
        completedNow: completedNow,
        stageDone: weekStage.done,
        stageGoal: weekStage.goal,
        justPassedGate: weekStage.justPassedGate,
        streak: streak,
      );
}

/// `POST /weekly/vocab/from-document`.
@JsonSerializable(createToJson: false)
class VocabSaveResultModel {
  const VocabSaveResultModel({required this.added, required this.existed, required this.total});

  factory VocabSaveResultModel.fromJson(Map<String, dynamic> json) => _$VocabSaveResultModelFromJson(json);

  final int added;
  final int existed;
  final int total;

  VocabSaveResult toEntity() => VocabSaveResult(added: added, existed: existed, total: total);
}
