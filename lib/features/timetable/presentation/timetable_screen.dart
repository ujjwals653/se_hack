import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:se_hack/features/attendance/domain/attendance_service.dart';
import 'package:se_hack/features/timetable/data/timetable_repository.dart';
import 'package:se_hack/features/timetable/domain/ocr_parser_service.dart';
import 'package:se_hack/features/timetable/presentation/screens/my_classes_screen.dart';
import 'package:se_hack/features/timetable/presentation/screens/timetable_upload_screen.dart';
import 'package:se_hack/features/timetable/presentation/timetable_bloc.dart';

class TimetableScreen extends StatelessWidget {
  final String userId;

  const TimetableScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext ctx) => TimetableBloc(
        repository: TimetableRepository(),
        parserService: GeminiParserService(),
        attendanceService: ctx.read<AttendanceService>(),
      )..add(TimetableLoadRequested(userId)),
      child: _TimetableScreenBody(userId: userId),
    );
  }
}

class _TimetableScreenBody extends StatelessWidget {
  final String userId;

  const _TimetableScreenBody({required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TimetableBloc, TimetableState>(
      listener: (context, state) {
        if (state is TimetableError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is TimetableLoading || state is TimetableInitial) {
          return const Scaffold(
            backgroundColor: Color(0xFF4C4D7B),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (state is TimetableProcessing) {
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
                      'Analyzing your timetable...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a moment',
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

        if (state is TimetablePreview) {
          return _buildPreviewScreen(context, state);
        }

        if (state is TimetableLoaded) {
          return MyClassesScreen(
            timetable: state.timetable,
            userId: userId,
          );
        }

        // TimetableNotFound or TimetableError → show upload screen
        return Scaffold(
          backgroundColor: const Color(0xFF4C4D7B),
          body: SafeArea(
            child: Column(
              children: [
                // App bar with back button
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
                  child: TimetableUploadScreen(
                    onFileSelected: (filePath, isPdf) {
                      context.read<TimetableBloc>().add(
                            TimetableUploadRequested(
                              userId: userId,
                              filePath: filePath,
                              isPdf: isPdf,
                            ),
                          );
                    },
                  ),
                ),
                // Create manually button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<TimetableBloc>().add(
                              TimetableCreateManually(userId),
                            );
                      },
                      icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                      label: const Text('Create Manually Instead'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewScreen(BuildContext context, TimetablePreview state) {
    final timetable = state.timetable;
    final totalEntries = timetable.days.values
        .fold<int>(0, (sum, list) => sum + list.length);

    return Scaffold(
      backgroundColor: const Color(0xFF4C4D7B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Timetable Detected!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$totalEntries periods found across ${timetable.days.values.where((l) => l.isNotEmpty).length} days',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              // Preview summary
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListView(
                    children: timetable.days.entries
                        .where((e) => e.value.isNotEmpty)
                        .map((dayEntry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayEntry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...dayEntry.value.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: entry.isFree
                                          ? Colors.blue.shade200
                                          : Colors.greenAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${entry.startTime} - ${entry.endTime}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.subject,
                                      style: TextStyle(
                                        color: entry.isFree
                                            ? Colors.blue.shade200
                                            : Colors.white,
                                        fontSize: 14,
                                        fontStyle: entry.isFree
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<TimetableBloc>().add(
                              TimetableLoadRequested(userId),
                            );
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Re-upload'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<TimetableBloc>().add(
                              TimetableSaveRequested(
                                userId: userId,
                                timetable: timetable,
                              ),
                            );
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirm & Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.shade400,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
