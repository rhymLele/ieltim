import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:frontend/core/storage/local_note_storage.dart';

class NotesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotes extends NotesEvent {}

class AddNote extends NotesEvent {
  final String title;
  final String content;
  AddNote({required this.title, required this.content});
  @override
  List<Object?> get props => [title, content];
}

class DeleteNote extends NotesEvent {
  final int id;
  DeleteNote({required this.id});
  @override
  List<Object?> get props => [id];
}

class NotesState extends Equatable {
  final bool loading;
  final String? error;
  final List<LocalNote> notes;

  const NotesState({
    this.loading = false,
    this.error,
    this.notes = const [],
  });

  NotesState copyWith({
    bool? loading,
    String? error,
    List<LocalNote>? notes,
    bool clearError = false,
  }) =>
      NotesState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props => [loading, error, notes];
}

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final LocalNoteStorage _storage = LocalNoteStorage();

  NotesBloc() : super(const NotesState()) {
    on<LoadNotes>(_onLoad);
    on<AddNote>(_onAdd);
    on<DeleteNote>(_onDelete);
  }

  Future<void> _onLoad(LoadNotes event, Emitter<NotesState> emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final notes = await _storage.getAllNotes();
      emit(state.copyWith(loading: false, notes: notes));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Failed to load notes'));
    }
  }

  Future<void> _onAdd(AddNote event, Emitter<NotesState> emit) async {
    try {
      await _storage.saveNote(
        referenceId: 'general',
        referenceType: 'general',
        title: event.title,
        content: event.content,
      );
      add(LoadNotes());
    } catch (e) {
      emit(state.copyWith(error: 'Failed to save note'));
    }
  }

  Future<void> _onDelete(DeleteNote event, Emitter<NotesState> emit) async {
    try {
      await _storage.deleteNote(event.id);
      add(LoadNotes());
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete note'));
    }
  }
}
