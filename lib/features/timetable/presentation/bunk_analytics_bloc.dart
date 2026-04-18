import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se_hack/features/timetable/data/bunk_analytics_repository.dart';
import 'package:se_hack/features/timetable/data/models/bunk_plan.dart';
import 'package:se_hack/features/timetable/data/timetable_repository.dart';
import 'package:se_hack/features/timetable/domain/bunk_recommendation_engine.dart';
import 'package:se_hack/features/timetable/domain/ocr_parser_service.dart';
import 'package:se_hack/features/attendance/domain/attendance_service.dart';

// --- Events ---
abstract class BunkAnalyticsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadBunkPlan extends BunkAnalyticsEvent {
  final String userId;
  LoadBunkPlan(this.userId);
  @override
  List<Object?> get props => [userId];
}

class UploadAcademicCalendar extends BunkAnalyticsEvent {
  final String userId;
  final String filePath;
  final bool isPdf;

  UploadAcademicCalendar({
    required this.userId,
    required this.filePath,
    required this.isPdf,
  });

  @override
  List<Object?> get props => [userId, filePath, isPdf];
}

class DiscardBunkPlan extends BunkAnalyticsEvent {
  final String userId;
  DiscardBunkPlan(this.userId);
  @override
  List<Object?> get props => [userId];
}

// --- States ---
abstract class BunkAnalyticsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BunkAnalyticsInitial extends BunkAnalyticsState {}

class BunkAnalyticsLoading extends BunkAnalyticsState {}

class BunkAnalyticsNoPlan extends BunkAnalyticsState {}

class BunkAnalyticsProcessing extends BunkAnalyticsState {}

class BunkAnalyticsLoaded extends BunkAnalyticsState {
  final BunkPlan plan;
  BunkAnalyticsLoaded(this.plan);
  @override
  List<Object?> get props => [plan];
}

class BunkAnalyticsError extends BunkAnalyticsState {
  final String message;
  BunkAnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class BunkAnalyticsBloc extends Bloc<BunkAnalyticsEvent, BunkAnalyticsState> {
  final BunkAnalyticsRepository _repo;
  final TimetableRepository _timetableRepo;
  final GeminiParserService _parser;
  final AttendanceService _attendanceService;
  final BunkRecommendationEngine _engine = BunkRecommendationEngine();

  BunkAnalyticsBloc({
    required BunkAnalyticsRepository repository,
    required TimetableRepository timetableRepository,
    required GeminiParserService parserService,
    required AttendanceService attendanceService,
  })  : _repo = repository,
        _timetableRepo = timetableRepository,
        _parser = parserService,
        _attendanceService = attendanceService,
        super(BunkAnalyticsInitial()) {
    on<LoadBunkPlan>(_onLoad);
    on<UploadAcademicCalendar>(_onUpload);
    on<DiscardBunkPlan>(_onDiscard);
  }

  Future<void> _onLoad(LoadBunkPlan event, Emitter<BunkAnalyticsState> emit) async {
    emit(BunkAnalyticsLoading());
    try {
      final plan = await _repo.getBunkPlan(event.userId);
      if (plan != null) {
        emit(BunkAnalyticsLoaded(plan));
      } else {
        emit(BunkAnalyticsNoPlan());
      }
    } catch (e) {
      emit(BunkAnalyticsError('Failed to load plan: $e'));
    }
  }

  Future<void> _onUpload(UploadAcademicCalendar event, Emitter<BunkAnalyticsState> emit) async {
    emit(BunkAnalyticsProcessing());
    try {
      // 1. Get Timetable
      final timetable = await _timetableRepo.getTimetable(event.userId);
      if (timetable == null || !timetable.hasTimetable) {
        emit(BunkAnalyticsError('You must set up your Timetable first in My Classes.'));
        return;
      }

      // 2. Parse Calendar
      final calendar = await _parser.parseAcademicCalendar(
        event.filePath,
        isPdf: event.isPdf,
      );

      // Seed subjects into Firestore / local cache based on this new timetable
      await _attendanceService.seedSubjectsFromTimetable(timetable);

      // 3. Generate Plan using live attendance data
      final plan = _engine.generatePlan(
         timetable, 
         calendar, 
         liveStats: _attendanceService.stats,
      );
      await _attendanceService.updateTotalPlannedFromPlan(plan);

      // 4. Save
      await _repo.saveAcademicCalendar(event.userId, calendar);
      await _repo.saveBunkPlan(event.userId, plan);

      emit(BunkAnalyticsLoaded(plan));
    } catch (e) {
      emit(BunkAnalyticsError('Analysis failed: $e'));
    }
  }

  Future<void> _onDiscard(DiscardBunkPlan event, Emitter<BunkAnalyticsState> emit) async {
    emit(BunkAnalyticsLoading());
    try {
      await _repo.deleteAcademicCalendar(event.userId);
      await _repo.deleteBunkPlan(event.userId);
      emit(BunkAnalyticsNoPlan());
    } catch (e) {
      emit(BunkAnalyticsError('Failed to discard plan: $e'));
    }
  }
}
