import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:se_hack/features/timetable/data/models/timetable.dart';
import 'package:se_hack/features/timetable/data/models/timetable_entry.dart';
import 'package:se_hack/features/timetable/data/timetable_repository.dart';
import 'package:se_hack/features/timetable/domain/ocr_parser_service.dart';

// ─── Events ─────────────────────────────────────────────────────────────────

abstract class TimetableEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TimetableLoadRequested extends TimetableEvent {
  final String userId;
  TimetableLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class TimetableUploadRequested extends TimetableEvent {
  final String userId;
  final String filePath;
  final bool isPdf;

  TimetableUploadRequested({
    required this.userId,
    required this.filePath,
    this.isPdf = false,
  });

  @override
  List<Object?> get props => [userId, filePath, isPdf];
}

class TimetableSaveRequested extends TimetableEvent {
  final String userId;
  final Timetable timetable;

  TimetableSaveRequested({required this.userId, required this.timetable});

  @override
  List<Object?> get props => [userId, timetable];
}

class TimetableDiscardRequested extends TimetableEvent {
  final String userId;
  TimetableDiscardRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class TimetableEntryUpdated extends TimetableEvent {
  final String userId;
  final String day;
  final int index;
  final TimetableEntry entry;

  TimetableEntryUpdated({
    required this.userId,
    required this.day,
    required this.index,
    required this.entry,
  });

  @override
  List<Object?> get props => [userId, day, index, entry];
}

class TimetableEntryAdded extends TimetableEvent {
  final String userId;
  final String day;
  final TimetableEntry entry;

  TimetableEntryAdded({
    required this.userId,
    required this.day,
    required this.entry,
  });

  @override
  List<Object?> get props => [userId, day, entry];
}

class TimetableEntryDeleted extends TimetableEvent {
  final String userId;
  final String day;
  final int index;

  TimetableEntryDeleted({
    required this.userId,
    required this.day,
    required this.index,
  });

  @override
  List<Object?> get props => [userId, day, index];
}

/// User chose to create a timetable manually (empty scaffold).
class TimetableCreateManually extends TimetableEvent {
  final String userId;
  TimetableCreateManually(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ─── States ─────────────────────────────────────────────────────────────────

abstract class TimetableState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TimetableInitial extends TimetableState {}

class TimetableLoading extends TimetableState {}

class TimetableNotFound extends TimetableState {}

class TimetableLoaded extends TimetableState {
  final Timetable timetable;
  TimetableLoaded(this.timetable);
  @override
  List<Object?> get props => [timetable];
}

/// OCR is processing the uploaded file.
class TimetableProcessing extends TimetableState {}

/// OCR finished — preview parsed data before confirming save.
class TimetablePreview extends TimetableState {
  final Timetable timetable;
  TimetablePreview(this.timetable);
  @override
  List<Object?> get props => [timetable];
}

class TimetableError extends TimetableState {
  final String message;
  TimetableError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───────────────────────────────────────────────────────────────────

class TimetableBloc extends Bloc<TimetableEvent, TimetableState> {
  final TimetableRepository _repository;
  final GeminiParserService _parserService;

  TimetableBloc({
    required TimetableRepository repository,
    required GeminiParserService parserService,
  })  : _repository = repository,
        _parserService = parserService,
        super(TimetableInitial()) {
    on<TimetableLoadRequested>(_onLoad);
    on<TimetableUploadRequested>(_onUpload);
    on<TimetableSaveRequested>(_onSave);
    on<TimetableDiscardRequested>(_onDiscard);
    on<TimetableEntryUpdated>(_onEntryUpdated);
    on<TimetableEntryAdded>(_onEntryAdded);
    on<TimetableEntryDeleted>(_onEntryDeleted);
    on<TimetableCreateManually>(_onCreateManually);
  }

  Future<void> _onLoad(
    TimetableLoadRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(TimetableLoading());
    try {
      final timetable = await _repository.getTimetable(event.userId);
      if (timetable != null && timetable.hasTimetable) {
        emit(TimetableLoaded(timetable));
      } else {
        emit(TimetableNotFound());
      }
    } catch (e) {
      emit(TimetableError('Failed to load timetable: $e'));
    }
  }

  Future<void> _onUpload(
    TimetableUploadRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(TimetableProcessing());
    try {
      final timetable = await _parserService.parseFile(
        event.filePath,
        isPdf: event.isPdf,
      );
      emit(TimetablePreview(timetable));
    } catch (e) {
      emit(TimetableError('Analysis failed: $e'));
    }
  }

  Future<void> _onSave(
    TimetableSaveRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(TimetableLoading());
    try {
      final updated = event.timetable.copyWith(
        hasTimetable: true,
        updatedAt: DateTime.now(),
      );
      await _repository.saveTimetable(event.userId, updated);
      emit(TimetableLoaded(updated));
    } catch (e) {
      emit(TimetableError('Failed to save timetable: $e'));
    }
  }

  Future<void> _onDiscard(
    TimetableDiscardRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(TimetableLoading());
    try {
      await _repository.deleteTimetable(event.userId);
      emit(TimetableNotFound());
    } catch (e) {
      emit(TimetableError('Failed to discard timetable: $e'));
    }
  }

  Future<void> _onEntryUpdated(
    TimetableEntryUpdated event,
    Emitter<TimetableState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TimetableLoaded) return;

    final timetable = currentState.timetable;
    final dayEntries = List<TimetableEntry>.from(timetable.days[event.day] ?? []);
    if (event.index < 0 || event.index >= dayEntries.length) return;

    dayEntries[event.index] = event.entry;
    final updatedDays = Map<String, List<TimetableEntry>>.from(timetable.days);
    updatedDays[event.day] = dayEntries;

    final updated = timetable.copyWith(
      days: updatedDays,
      updatedAt: DateTime.now(),
    );

    emit(TimetableLoaded(updated));

    // Persist in background
    try {
      await _repository.saveTimetable(event.userId, updated);
    } catch (_) {}
  }

  Future<void> _onEntryAdded(
    TimetableEntryAdded event,
    Emitter<TimetableState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TimetableLoaded) return;

    final timetable = currentState.timetable;
    final dayEntries = List<TimetableEntry>.from(timetable.days[event.day] ?? []);
    dayEntries.add(event.entry);

    final updatedDays = Map<String, List<TimetableEntry>>.from(timetable.days);
    updatedDays[event.day] = dayEntries;

    final updated = timetable.copyWith(
      days: updatedDays,
      updatedAt: DateTime.now(),
    );

    emit(TimetableLoaded(updated));

    try {
      await _repository.saveTimetable(event.userId, updated);
    } catch (_) {}
  }

  Future<void> _onEntryDeleted(
    TimetableEntryDeleted event,
    Emitter<TimetableState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TimetableLoaded) return;

    final timetable = currentState.timetable;
    final dayEntries = List<TimetableEntry>.from(timetable.days[event.day] ?? []);
    if (event.index < 0 || event.index >= dayEntries.length) return;

    dayEntries.removeAt(event.index);
    // Re-number periods
    for (int i = 0; i < dayEntries.length; i++) {
      dayEntries[i] = dayEntries[i].copyWith(period: i + 1);
    }

    final updatedDays = Map<String, List<TimetableEntry>>.from(timetable.days);
    updatedDays[event.day] = dayEntries;

    final updated = timetable.copyWith(
      days: updatedDays,
      updatedAt: DateTime.now(),
    );

    emit(TimetableLoaded(updated));

    try {
      await _repository.saveTimetable(event.userId, updated);
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _parserService.dispose();
    return super.close();
  }

  Future<void> _onCreateManually(
    TimetableCreateManually event,
    Emitter<TimetableState> emit,
  ) async {
    final now = DateTime.now();
    final emptyTimetable = Timetable(
      hasTimetable: true,
      createdAt: now,
      updatedAt: now,
      days: {for (final d in Timetable.dayKeys) d: <TimetableEntry>[]},
    );

    try {
      await _repository.saveTimetable(event.userId, emptyTimetable);
      emit(TimetableLoaded(emptyTimetable));
    } catch (e) {
      emit(TimetableError('Failed to create timetable: $e'));
    }
  }
}
