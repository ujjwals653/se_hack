// lib/core/services/restore_service.dart
// Lumina — Restores data from Firebase into Hive on new device login

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class RestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> restoreAllData(String userId) async {
    await Future.wait([
      _restoreTimetable(userId),
      _restoreAttendance(userId),
      _restoreExpenses(userId),
      _restoreKanban(userId),
    ]);
  }

  static Future<void> _restoreTimetable(String userId) async {
    final snapshot = await _firestore
        .collection('timetable_entries')
        .where('userId', isEqualTo: userId)
        .get();

    final box = Hive.box('timetableBox');
    for (var doc in snapshot.docs) {
      await box.put(doc.id, doc.data());
    }
  }

  static Future<void> _restoreAttendance(String userId) async {
    final snapshot = await _firestore
        .collection('attendance_records')
        .where('userId', isEqualTo: userId)
        .get();

    final box = Hive.box('attendanceBox');
    for (var doc in snapshot.docs) {
      await box.put(doc.id, doc.data());
    }
  }

  static Future<void> _restoreExpenses(String userId) async {
    final snapshot = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .get();

    final box = Hive.box('expensesBox');
    for (var doc in snapshot.docs) {
      await box.put(doc.id, doc.data());
    }
  }

  static Future<void> _restoreKanban(String userId) async {
    final snapshot = await _firestore
        .collection('kanban_tasks')
        .where('userId', isEqualTo: userId)
        .get();

    final box = Hive.box('kanbanBox');
    for (var doc in snapshot.docs) {
      await box.put(doc.id, doc.data());
    }
  }
}
