import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se_hack/features/timetable/data/bunk_analytics_repository.dart';
import 'package:se_hack/features/timetable/data/timetable_repository.dart';
import 'package:se_hack/features/timetable/domain/ocr_parser_service.dart';
import 'package:se_hack/features/timetable/presentation/bunk_analytics_bloc.dart';
import 'package:se_hack/features/attendance/domain/attendance_service.dart';
import 'package:se_hack/features/timetable/presentation/screens/bunk_analytics_dashboard.dart';
import 'package:se_hack/features/timetable/presentation/screens/bunk_analytics_upload_screen.dart';

class BunkAnalyticsWrapper extends StatelessWidget {
  final String userId;

  const BunkAnalyticsWrapper({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BunkAnalyticsBloc(
        repository: BunkAnalyticsRepository(),
        timetableRepository: TimetableRepository(),
        parserService: GeminiParserService(),
        attendanceService: context.read<AttendanceService>(),
      )..add(LoadBunkPlan(userId)),
      child: _BunkWrapperBody(userId: userId),
    );
  }
}

class _BunkWrapperBody extends StatelessWidget {
  final String userId;

  const _BunkWrapperBody({required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BunkAnalyticsBloc, BunkAnalyticsState>(
      listener: (context, state) {
        if (state is BunkAnalyticsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is BunkAnalyticsLoading || state is BunkAnalyticsInitial) {
          return const Scaffold(
            backgroundColor: Color(0xFF4C4D7B),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (state is BunkAnalyticsProcessing) {
          return Scaffold(
            backgroundColor: const Color(0xFF4C4D7B),
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Analyzing Sem Calendar...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generating 75% Bunk Plan',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is BunkAnalyticsLoaded) {
          return BunkAnalyticsDashboard(
            userId: userId,
            plan: state.plan,
          );
        }

        // BunkAnalyticsNoPlan or Error
        return Scaffold(
          backgroundColor: const Color(0xFF4C4D7B),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BunkAnalyticsUploadScreen(
                    onFileSelected: (filePath, isPdf) {
                      context.read<BunkAnalyticsBloc>().add(
                            UploadAcademicCalendar(
                              userId: userId,
                              filePath: filePath,
                              isPdf: isPdf,
                            ),
                          );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
