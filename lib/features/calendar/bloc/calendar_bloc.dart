import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:se_hack/features/calendar/data/calendar_repository.dart';
import 'package:se_hack/features/calendar/domain/calendar_event_model.dart';
import 'package:se_hack/features/group_hub/data/squad_repository.dart';
import 'package:se_hack/features/group_hub/models/deadline_model.dart';
import 'package:se_hack/features/timetable/data/timetable_repository.dart';

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

class CalendarSyncTimetableRequested extends CalendarEvent {}

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
    on<CalendarSyncTimetableRequested>(_onSyncTimetable);
  }

  Future<void> _onSyncTimetable(
    CalendarSyncTimetableRequested event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final timetableRepo = TimetableRepository();
      final timetable = await timetableRepo.getTimetable(uid);
      if (timetable == null || !timetable.hasTimetable) return;

      final currentEvents = state is CalendarLoaded
          ? (state as CalendarLoaded).events
          : <CalendarEventModel>[];

      final now = DateTime.now();
      // Find the start of the current week (Monday)
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      // Timetable map: Mon, Tue, Wed, Thu, Fri, Sat
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (final dayEntry in timetable.days.entries) {
        final dayName = dayEntry.key;
        final entries = dayEntry.value;
        final dayIndex = dayNames.indexOf(dayName);
        if (dayIndex == -1) continue;

        final baseDate = startOfWeek.add(Duration(days: dayIndex));

        for (final entry in entries) {
          if (entry.isFree) continue;

          // Parse start and end times, with fallback mapped to period number (1st period = 9 AM)
          final partsStart = entry.startTime.split(':');
          final partsEnd = entry.endTime.split(':');

          int hourStart = 9 + (entry.period - 1);
          int minStart = 0;
          int hourEnd = 10 + (entry.period - 1);
          int minEnd = 0;

          if (partsStart.length >= 2) {
            hourStart = int.tryParse(partsStart[0].trim()) ?? hourStart;
            minStart = int.tryParse(partsStart[1].trim()) ?? 0;
          }
          if (partsEnd.length >= 2) {
            hourEnd = int.tryParse(partsEnd[0].trim()) ?? hourEnd;
            minEnd = int.tryParse(partsEnd[1].trim()) ?? 0;
          }

          final startDateTime = DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day,
            hourStart,
            minStart,
          );
          final endDateTime = DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day,
            hourEnd,
            minEnd,
          );

          final title = '[Class] ${entry.subject}';

          // To avoid duplicates, we can check if there's an event at exactly the same start time with the same title.
          // Note: occursOn doesn't check specific times, but we can do a simple check.
          final exists = currentEvents.any(
            (e) =>
                e.title == title &&
                e.start?.weekday == startDateTime.weekday &&
                e.start?.hour == startDateTime.hour &&
                e.start?.minute == startDateTime.minute,
          );

          if (!exists) {
            final calendarEvent = CalendarEventModel(
              id: '',
              title: title,
              start: startDateTime,
              end: endDateTime,
              isAllDay: false,
              location: entry.section,
              description:
                  'Routine Class sync\\nSubject: ${entry.subject}\\nPeriod: ${entry.period}',
              recurrenceRule: ['RRULE:FREQ=WEEKLY;COUNT=16'],
            );
            await _repository.addEvent(calendarEvent);
          }
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
            currentEvents
                .where(
                  (e) =>
                      e.id != event.eventId &&
                      e.recurringEventId != event.eventId,
                )
                .toList(),
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
