// lib/features/timetable/data/timetable_repository.dart
// Lumina — Handles saving and fetching timetable from Hive + Firebase

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/sync_service.dart';
import 'models/timetable_entry.dart';

class TimetableRepository {
  final Box<TimetableEntry> _box = Hive.box<TimetableEntry>('timetableBox');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save parsed Gemini JSON into Hive + Firebase
  Future<void> saveParsedTimetable(
      Map<String, dynamic> parsed, String userId) async {
    
    final weekdayMap = {
      'monday': 1, 'tuesday': 2, 'wednesday': 3,
      'thursday': 4, 'friday': 5, 'saturday': 6
    };

    final schedule = parsed['schedule'] as Map<String, dynamic>;

    for (final day in schedule.keys) {
      final slots = schedule[day] as List;
      for (final slot in slots) {
        final entry = TimetableEntry(
          id: const Uuid().v4(),
          subjectName: slot['subject_name'] ?? '',
          subjectCode: slot['subject_code'] ?? '',
          weekday: weekdayMap[day] ?? 1,
          startTime: slot['start'] ?? '',
          endTime: slot['end'] ?? '',
          room: slot['room'] ?? '',
          professorName: slot['teacher'] ?? '',
          batch: slot['batch'] ?? '',
          userId: userId,
        );

        // Save to Hive
        await _box.put(entry.id, entry);

        // Sync to Firebase
        await SyncService.syncTimetableEntry(entry.toMap());
      }
    }
  }

  // Get today's classes from Hive
  List<TimetableEntry> getTodayClasses() {
    final today = DateTime.now().weekday; // 1=Mon … 5=Fri
    return _box.values
        .where((e) => e.weekday == today)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Get all classes for a specific day
  List<TimetableEntry> getClassesForDay(int weekday) {
    return _box.values
        .where((e) => e.weekday == weekday)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Get full week timetable
  Map<int, List<TimetableEntry>> getFullWeek() {
    final Map<int, List<TimetableEntry>> week = {};
    for (int day = 1; day <= 6; day++) {
      final classes = getClassesForDay(day);
      if (classes.isNotEmpty) week[day] = classes;
    }
    return week;
  }
}
