import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se_hack/features/calendar/data/calendar_repository.dart';
import 'package:se_hack/features/calendar/domain/calendar_event_model.dart';
import 'package:se_hack/features/group_hub/data/squad_repository.dart';
import 'package:se_hack/features/group_hub/models/deadline_model.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class CalendarEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CalendarLoadRequested extends CalendarEvent {}

class CalendarRefreshRequested extends CalendarEvent {}

class CalendarEventAddRequested extends CalendarEvent {
  final CalendarEventModel event;
  CalendarEventAddRequested(this.event);

  @override
  List<Object?> get props => [event];
}

class CalendarEventDeleteRequested extends CalendarEvent {
  final String eventId;
  CalendarEventDeleteRequested(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class CalendarEventUndoDeleteRequested extends CalendarEvent {
  final CalendarEventModel event;
  CalendarEventUndoDeleteRequested(this.event);

  @override
  List<Object?> get props => [event];
}

class CalendarSyncSquadDeadlinesRequested extends CalendarEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class CalendarState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final List<CalendarEventModel> events;
  CalendarLoaded(this.events);

  @override
  List<Object?> get props => [events];
}

class CalendarNeedsAuth extends CalendarState {}

class CalendarError extends CalendarState {
  final String message;
  CalendarError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CalendarRepository _repository;

  CalendarBloc({CalendarRepository? repository})
    : _repository = repository ?? CalendarRepository(),
      super(CalendarInitial()) {
    on<CalendarLoadRequested>(_onLoad);
    on<CalendarRefreshRequested>(_onRefresh);
    on<CalendarEventAddRequested>(_onAdd);
    on<CalendarEventDeleteRequested>(_onDelete);
    on<CalendarEventUndoDeleteRequested>(_onUndoDelete);
    on<CalendarSyncSquadDeadlinesRequested>(_onSyncSquadDeadlines);
  }

  Future<void> _onSyncSquadDeadlines(
    CalendarSyncSquadDeadlinesRequested event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final squadRepo = SquadRepository();
      final deadlines = await squadRepo.getAllMyDeadlines();

      final currentEvents = state is CalendarLoaded
          ? (state as CalendarLoaded).events
          : <CalendarEventModel>[];

      for (final deadline in deadlines) {
        final title = '[Squad Deadline] ${deadline.title}';

        final exists = currentEvents.any((e) => e.title == title);

        if (!exists) {
          final calendarEvent = CalendarEventModel(
            id: '',
            title: title,
            start: deadline.dueDate,
            end: deadline.dueDate,
            isAllDay: true,
            description:
                'Subject: ${deadline.subject}\\n\\nAutomated sync from Lumina Squads.',
          );
          await _repository.addEvent(calendarEvent);
        }
      }

      await _fetch(emit);
    } catch (e) {
      if (e is CalendarAuthException) {
        emit(CalendarNeedsAuth());
      } else {
        emit(CalendarError(e.toString()));
      }
    }
  }

  Future<void> _onAdd(
    CalendarEventAddRequested event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      if (state is CalendarLoaded) {
        final currentEvents = (state as CalendarLoaded).events;
        emit(CalendarLoaded([...currentEvents, event.event]));
      }
      await _repository.addEvent(event.event);
      await _fetch(emit);
    } catch (e) {
      if (e is CalendarAuthException) {
        emit(CalendarNeedsAuth());
      } else {
        await _fetch(emit);
      }
    }
  }

  Future<void> _onDelete(
    CalendarEventDeleteRequested event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      if (state is CalendarLoaded) {
        final currentEvents = (state as CalendarLoaded).events;
        emit(
          CalendarLoaded(
            currentEvents.where((e) => e.id != event.eventId).toList(),
          ),
        );
      }
      await _repository.deleteEvent(event.eventId);
      await _fetch(emit);
    } catch (e) {
      if (e is CalendarAuthException) {
        emit(CalendarNeedsAuth());
      } else {
        await _fetch(emit);
      }
    }
  }

  Future<void> _onUndoDelete(
    CalendarEventUndoDeleteRequested event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      if (state is CalendarLoaded) {
        final currentEvents = (state as CalendarLoaded).events;
        emit(CalendarLoaded([...currentEvents, event.event]));
      }
      await _repository.addEvent(event.event);
      await _fetch(emit);
    } catch (e) {
      if (e is CalendarAuthException) {
        emit(CalendarNeedsAuth());
      } else {
        await _fetch(emit);
      }
    }
  }

  Future<void> _onLoad(
    CalendarLoadRequested event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    CalendarRefreshRequested event,
    Emitter<CalendarState> emit,
  ) async {
    // Keep current data visible during refresh
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<CalendarState> emit) async {
    try {
      final events = await _repository.fetchEvents();
      emit(CalendarLoaded(events));
    } on CalendarAuthException {
      emit(CalendarNeedsAuth());
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }
}
