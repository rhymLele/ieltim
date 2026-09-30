import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:frontend/core/network/api_client.dart';

class Lesson {
  final String id;
  final String title;
  final String? description;
  final String? studyDate;
  final int? weekNumber;
  final int? dayOfWeek;
  final String? level;
  final String? status;

  Lesson({
    required this.id,
    required this.title,
    this.description,
    this.studyDate,
    this.weekNumber,
    this.dayOfWeek,
    this.level,
    this.status,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        studyDate: json['studyDate'],
        weekNumber: json['weekNumber'],
        dayOfWeek: json['dayOfWeek'],
        level: json['level'],
        status: json['status'],
      );
}

class WeeklyDocumentsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDocuments extends WeeklyDocumentsEvent {
  final int week;
  LoadDocuments({required this.week});
  @override
  List<Object?> get props => [week];
}

class WeeklyDocumentsState extends Equatable {
  final bool loading;
  final String? error;
  final List<Lesson> lessons;
  final int selectedWeek;

  const WeeklyDocumentsState({
    this.loading = false,
    this.error,
    this.lessons = const [],
    this.selectedWeek = 1,
  });

  WeeklyDocumentsState copyWith({
    bool? loading,
    String? error,
    List<Lesson>? lessons,
    int? selectedWeek,
    bool clearError = false,
  }) =>
      WeeklyDocumentsState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        lessons: lessons ?? this.lessons,
        selectedWeek: selectedWeek ?? this.selectedWeek,
      );

  @override
  List<Object?> get props => [loading, error, lessons, selectedWeek];
}

class WeeklyDocumentsBloc extends Bloc<WeeklyDocumentsEvent, WeeklyDocumentsState> {
  final ApiClient _api = ApiClient();

  WeeklyDocumentsBloc() : super(const WeeklyDocumentsState()) {
    on<LoadDocuments>(_onLoad);
  }

  Future<void> _onLoad(LoadDocuments event, Emitter<WeeklyDocumentsState> emit) async {
    emit(state.copyWith(loading: true, clearError: true, selectedWeek: event.week));
    try {
      final res = await _api.get('/lessons', queryParameters: {
        'week': event.week,
      });
      final data = res.data;
      final list = (data['data'] as List? ?? []);
      final lessons = list
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(loading: false, lessons: lessons));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Failed to load lessons'));
    }
  }
}
