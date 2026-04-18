// lib/features/timetable/presentation/bloc/timetable_bloc.dart
// Lumina — BLoC for timetable state management

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../data/timetable_repository.dart';
import '../../data/timetable_parser_service.dart';
import '../../data/models/timetable_entry.dart';

// Events
abstract class TimetableEvent extends Equatable {
  @override List<Object> get props => [];
}

class ParseTimetablePdf extends TimetableEvent {
  final File pdfFile;
  final String userId;
  ParseTimetablePdf(this.pdfFile, this.userId);
  @override List<Object> get props => [pdfFile, userId];
}

class LoadTimetable extends TimetableEvent {}

// States
abstract class TimetableState extends Equatable {
  @override List<Object> get props => [];
}

class TimetableInitial extends TimetableState {}
class TimetableLoading extends TimetableState {}
class TimetableError extends TimetableState {
  final String message;
  TimetableError(this.message);
  @override List<Object> get props => [message];
}

class TimetableLoaded extends TimetableState {
  final List<TimetableEntry> todayClasses;
  final Map<int, List<TimetableEntry>> fullWeek;
  TimetableLoaded({required this.todayClasses, required this.fullWeek});
  @override List<Object> get props => [todayClasses, fullWeek];
}

// BLoC
class TimetableBloc extends Bloc<TimetableEvent, TimetableState> {
  final TimetableRepository _repo = TimetableRepository();

  TimetableBloc() : super(TimetableInitial()) {
    on<ParseTimetablePdf>(_onParse);
    on<LoadTimetable>(_onLoad);
  }

  Future<void> _onParse(
      ParseTimetablePdf event, Emitter<TimetableState> emit) async {
    emit(TimetableLoading());
    try {
      final parsed =
          await TimetableParserService.parseTimetablePdf(event.pdfFile);
      await _repo.saveParsedTimetable(parsed, event.userId);
      final todayClasses = _repo.getTodayClasses();
      final fullWeek = _repo.getFullWeek();
      emit(TimetableLoaded(todayClasses: todayClasses, fullWeek: fullWeek));
    } catch (e) {
      emit(TimetableError(e.toString()));
    }
  }

  Future<void> _onLoad(
      LoadTimetable event, Emitter<TimetableState> emit) async {
    emit(TimetableLoading());
    try {
      final todayClasses = _repo.getTodayClasses();
      final fullWeek = _repo.getFullWeek();
      emit(TimetableLoaded(todayClasses: todayClasses, fullWeek: fullWeek));
    } catch (e) {
      emit(TimetableError(e.toString()));
    }
  }
}
