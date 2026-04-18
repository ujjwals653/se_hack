// lib/core/services/sync_service.dart
// Lumina — Handles dual write to Hive (local) and Firebase (cloud)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if online
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none && result != [] && !result.toString().contains('none');
  }

  // Write to Hive first, then Firebase if online
  static Future<void> syncTimetableEntry(Map<String, dynamic> data) async {
    // 1. Always save to Hive first
    final box = Hive.box('timetableBox');
    await box.put(data['id'], data);

    // 2. Push to Firebase if online
    if (await isOnline()) {
      await _firestore
          .collection('timetable_entries')
          .doc(data['id'])
          .set(data, SetOptions(merge: true));
    }
  }

  static Future<void> syncAttendanceRecord(Map<String, dynamic> data) async {
    final box = Hive.box('attendanceBox');
    await box.put(data['id'], data);

    if (await isOnline()) {
      await _firestore
          .collection('attendance_records')
          .doc(data['id'])
          .set(data, SetOptions(merge: true));
    }
  }

  static Future<void> syncExpense(Map<String, dynamic> data) async {
    final box = Hive.box('expensesBox');
    await box.put(data['id'], data);

    if (await isOnline()) {
      await _firestore
          .collection('expenses')
          .doc(data['id'])
          .set(data, SetOptions(merge: true));
    }
  }

  static Future<void> syncKanbanTask(Map<String, dynamic> data) async {
    final box = Hive.box('kanbanBox');
    await box.put(data['id'], data);

    if (await isOnline()) {
      await _firestore
          .collection('kanban_tasks')
          .doc(data['id'])
          .set(data, SetOptions(merge: true));
    }
  }
}
