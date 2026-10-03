import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/week_info.dart';

part 'week_models.g.dart';

/// Một tuần trong `GET /weekly/weeks`.
@JsonSerializable(createToJson: false)
class WeekModel {
  const WeekModel({required this.number, required this.startDate, required this.stageGoal, required this.state, this.docTotal, this.docDone});

  factory WeekModel.fromJson(Map<String, dynamic> json) => _$WeekModelFromJson(json);

  final int number;

  /// `YYYY-MM-DD` theo giờ Việt Nam.
  final String startDate;
  final int stageGoal;

  /// `locked` | `open`.
  final String state;
  final int? docTotal;
  final int? docDone;

  WeekInfo toEntity() => WeekInfo(
        number: number,
        start: DateTime.parse(startDate),
        stageGoal: stageGoal,
        locked: state == 'locked',
        docTotal: docTotal,
        docDone: docDone,
      );
}

/// `GET /weekly/weeks`.
@JsonSerializable(createToJson: false)
class WeekListModel {
  const WeekListModel({required this.data, this.currentWeek});

  factory WeekListModel.fromJson(Map<String, dynamic> json) => _$WeekListModelFromJson(json);

  final int? currentWeek;
  final List<WeekModel> data;

  WeekList toEntity() => WeekList(weeks: [for (final w in data) w.toEntity()], currentWeek: currentWeek);
}
