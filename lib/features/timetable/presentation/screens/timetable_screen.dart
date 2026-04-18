// lib/features/timetable/presentation/screens/timetable_screen.dart
// Lumina — Timetable display screen with day tabs and today's classes

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../bloc/timetable_bloc.dart';
import '../widgets/class_card.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  static const List<String> _days = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TimetableBloc()..add(LoadTimetable()),
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          backgroundColor: AppColors.bgPrimary,
          appBar: AppBar(
            backgroundColor: AppColors.bgSurface,
            title: const Text('Timetable',
                style: TextStyle(color: AppColors.textPrimary)),
            bottom: TabBar(
              isScrollable: true,
              indicatorColor: AppColors.accentAmber,
              labelColor: AppColors.accentAmber,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: _days.map((d) => Tab(text: d)).toList(),
            ),
            actions: [
              // Upload PDF button
              BlocBuilder<TimetableBloc, TimetableState>(
                builder: (context, state) {
                  return IconButton(
                    icon: const Icon(Icons.upload_file,
                        color: AppColors.accentAmber),
                    onPressed: state is TimetableLoading
                        ? null
                        : () => _pickAndParse(context),
                  );
                },
              )
            ],
          ),
          body: BlocBuilder<TimetableBloc, TimetableState>(
            builder: (context, state) {
              if (state is TimetableLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.accentAmber),
                      SizedBox(height: 16),
                      Text('Parsing timetable...',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              if (state is TimetableError) {
                return Center(
                  child: Text(state.message,
                      style: const TextStyle(color: Colors.red)),
                );
              }

              if (state is TimetableLoaded) {
                return TabBarView(
                  children: List.generate(6, (index) {
                    final dayClasses = state.fullWeek[index + 1] ?? [];
                    if (dayClasses.isEmpty) {
                      return const Center(
                        child: Text('No classes',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: dayClasses.length,
                      itemBuilder: (context, i) =>
                          ClassCard(entry: dayClasses[i]),
                    );
                  }),
                );
              }

              // Initial state — no timetable yet
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_file,
                        size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    const Text('No timetable yet',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentAmber),
                      onPressed: () => _pickAndParse(context),
                      child: const Text('Upload Timetable PDF'),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndParse(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final userId = 'current_user_id'; // replace with actual auth userId
      if (context.mounted) {
        context.read<TimetableBloc>().add(ParseTimetablePdf(file, userId));
      }
    }
  }
}
