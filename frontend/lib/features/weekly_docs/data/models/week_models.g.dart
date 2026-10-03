// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'week_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeekModel _$WeekModelFromJson(Map<String, dynamic> json) => WeekModel(
  number: (json['number'] as num).toInt(),
  startDate: json['startDate'] as String,
  stageGoal: (json['stageGoal'] as num).toInt(),
  state: json['state'] as String,
  docTotal: (json['docTotal'] as num?)?.toInt(),
  docDone: (json['docDone'] as num?)?.toInt(),
);

WeekListModel _$WeekListModelFromJson(Map<String, dynamic> json) =>
    WeekListModel(
      data: (json['data'] as List<dynamic>)
          .map((e) => WeekModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentWeek: (json['currentWeek'] as num?)?.toInt(),
    );
