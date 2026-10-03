// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_result_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizFeedbackModel _$QuizFeedbackModelFromJson(Map<String, dynamic> json) =>
    QuizFeedbackModel(
      correct: json['correct'] as bool,
      answer: (json['answer'] as num).toInt(),
      explain: json['explain'] as String?,
    );

WeekStageModel _$WeekStageModelFromJson(Map<String, dynamic> json) =>
    WeekStageModel(
      done: (json['done'] as num).toInt(),
      goal: (json['goal'] as num).toInt(),
      justPassedGate: json['justPassedGate'] as bool? ?? false,
    );

CompleteResultModel _$CompleteResultModelFromJson(Map<String, dynamic> json) =>
    CompleteResultModel(
      completedNow: json['completedNow'] as bool,
      weekStage: WeekStageModel.fromJson(
        json['weekStage'] as Map<String, dynamic>,
      ),
      streak: (json['streak'] as num).toInt(),
    );

VocabSaveResultModel _$VocabSaveResultModelFromJson(
  Map<String, dynamic> json,
) => VocabSaveResultModel(
  added: (json['added'] as num).toInt(),
  existed: (json['existed'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);
