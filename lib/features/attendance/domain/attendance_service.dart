import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:se_hack/features/timetable/data/models/timetable.dart';
import 'package:se_hack/features/timetable/data/timetable_repository.dart' as se_hack_timetable_repo;
import 'package:se_hack/features/timetable/data/bunk_analytics_repository.dart' as calendar_repo;
import 'package:se_hack/features/timetable/data/models/bunk_plan.dart';
import 'package:se_hack/features/timetable/domain/bunk_recommendation_engine.dart';
import '../data/models/attendance_stats.dart';

class AttendanceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  IO.Socket? _socket;
  
  String? _userId;
  Map<String, AttendanceStats> _stats = {};
  StreamSubscription? _subscription;

  Map<String, AttendanceStats> get stats => _stats;

  void initialize(String userId) {
    if (_userId == userId) return; // Already initialized
    _userId = userId;
    
    _listenToFirestore();
    _connectWebSocket();
  }

  void _listenToFirestore() {
    _subscription?.cancel();
    if (_userId == null) return;

    _subscription = _firestore
        .collection('users')
        .doc(_userId)
        .collection('subjects')
        .snapshots()
        .listen((snapshot) {
      final newStats = <String, AttendanceStats>{};
      for (final doc in snapshot.docs) {
        newStats[doc.id] = AttendanceStats.fromMap(doc.data());
      }
      _stats = newStats;
      notifyListeners();
      _checkOverallAttendanceDanger();

      if (newStats.isEmpty) {
         // Auto-seed if they have a timetable but no attendance subjects yet
         _attemptAutoSeed();
      }
    });
  }

  Future<void> _attemptAutoSeed() async {
    if (_userId == null) return;
    try {
      final repo = se_hack_timetable_repo.TimetableRepository();
      final timetable = await repo.getTimetable(_userId!);
      if (timetable != null && timetable.hasTimetable) {
         await seedSubjectsFromTimetable(timetable);
      }
    } catch (e) {
      print('Auto-seed failed: $e');
    }
  }

  void _connectWebSocket() {
    if (_socket != null) {
      _socket!.disconnect();
    }

    // Using a mock WS URL for demo integration
    _socket = IO.io('https://ws.lumina-app.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    _socket!.connect();
    
    _socket!.onConnect((_) {
      print('WebSocket connected in AttendanceService');
      _socket!.emit('join_room', {'user_id': _userId});
    });

    _socket!.onDisconnect((_) => print('WebSocket disconnected'));
  }

  /// Parses an uploaded Timetable to extract subjects and seed Firestore.
  Future<void> seedSubjectsFromTimetable(Timetable timetable) async {
    if (_userId == null) return;
    
    final uniqueSubjects = <String>{};
    for (final entries in timetable.days.values) {
      for (final entry in entries) {
        if (!entry.isFree && entry.subject.isNotEmpty) {
          uniqueSubjects.add(entry.subject);
        }
      }
    }

    final batch = _firestore.batch();
    for (final subject in uniqueSubjects) {
      // Create safe subject ID
      final subId = subject.replaceAll(' ', '_').toLowerCase();
      
      final ref = _firestore
          .collection('users')
          .doc(_userId)
          .collection('subjects')
          .doc(subId);
      
      // Default to 40 planned classes if we don't know better yet
      final stat = AttendanceStats(
        subjectId: subId,
        subjectName: subject,
        totalPlanned: 40,
      );
      
      batch.set(ref, stat.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Updates existing stats with authentic total class counts calculated from calendar.
  Future<void> updateTotalPlannedFromPlan(BunkPlan plan) async {
    if (_userId == null || _stats.isEmpty) return;
    
    final batch = _firestore.batch();
    
    for (final entry in plan.subjectStatus.entries) {
      final subjectName = entry.key;
      final totalInSemester = entry.value.totalClassesInSemester;
      
      // Match stat by subject name
      for (final stat in _stats.values) {
        if (stat.subjectName == subjectName && stat.totalPlanned != totalInSemester) {
          final ref = _firestore
              .collection('users')
              .doc(_userId)
              .collection('subjects')
              .doc(stat.subjectId);
              
          final updated = stat.copyWith(totalPlanned: totalInSemester);
          batch.set(ref, updated.toMap(), SetOptions(merge: true));
        }
      }
    }
    
    await batch.commit();
  }

  /// Mark attendance for a subject. Blocks if conducted would exceed total_planned.
  Future<String?> markAttendance(String subjectId, String status) async {
    if (_userId == null || !_stats.containsKey(subjectId)) return 'Subject not found';

    final current = _stats[subjectId]!;
    
    int newAttended = current.attended;
    int newAbsent = current.absent;
    int newCancelled = current.cancelled;

    if (status == 'present') newAttended++;
    else if (status == 'absent') newAbsent++;
    else if (status == 'cancelled') newCancelled++;

    // Guard: attended + absent (conducted) must not exceed total_planned
    final newConducted = newAttended + newAbsent;
    if (newConducted > current.totalPlanned) {
      return 'Cannot exceed ${current.totalPlanned} planned lectures!';
    }

    final updated = current.copyWith(
      attended: newAttended,
      absent: newAbsent,
      cancelled: newCancelled,
    );

    // Update locally immediately for snappy UI
    _stats[subjectId] = updated;
    notifyListeners();

    // 1. Fire to Firestore (Single Source of Truth)
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('subjects')
        .doc(subjectId)
        .set(updated.toMap(), SetOptions(merge: true));

    // 2. Fire WebSocket to sync with Squads / external handlers
    _socket?.emit('attendance_updated', {
      'user_id': _userId,
      'subject_id': subjectId,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
      'resulting_percentage': updated.currentPercentage,
    });
    return null; // success
  }

  /// Reset attendance for a subject to 0 constraints.
  Future<void> resetAttendance(String subjectId) async {
    if (_userId == null || !_stats.containsKey(subjectId)) return;

    final current = _stats[subjectId]!;
    final updated = current.copyWith(
      attended: 0,
      absent: 0,
      cancelled: 0,
    );

    // Update locally immediately
    _stats[subjectId] = updated;
    notifyListeners();

    // Fire to Firestore
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('subjects')
        .doc(subjectId)
        .set(updated.toMap(), SetOptions(merge: true));
  }

  /// Change the compulsory percentage requirement (0-100).
  Future<void> setCompulsoryPercentage(String subjectId, double percentage) async {
    if (_userId == null || !_stats.containsKey(subjectId)) return;
    if (percentage < 0 || percentage > 100) throw ArgumentError('Must be 0-100');

    final current = _stats[subjectId]!;
    final updated = current.copyWith(compulsoryPct: percentage);

    _stats[subjectId] = updated;
    notifyListeners();

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('subjects')
        .doc(subjectId)
        .set(updated.toMap(), SetOptions(merge: true));
  }

  /// Refreshes bounds cleanly from DB by running the Bunk Engine over the latest Timetable & Calendar.
  Future<void> refreshSubjectCounts() async {
    if (_userId == null) return;
    
    try {
      final calRepo = calendar_repo.BunkAnalyticsRepository();
      final timeRepo = se_hack_timetable_repo.TimetableRepository();

      final calendar = await calRepo.getAcademicCalendar(_userId!);
      final timetable = await timeRepo.getTimetable(_userId!);

      if (calendar != null && timetable != null && timetable.hasTimetable) {
         final engine = BunkRecommendationEngine();
         final plan = engine.generatePlan(timetable, calendar);
         await updateTotalPlannedFromPlan(plan);
      }
    } catch (e) {
      print('Failed to refresh subject counts: $e');
    }
  }

  /// Manually set attended and absent counts directly.
  /// Validates that attended + absent <= totalPlanned.
  Future<String?> setManualValues(String subjectId, {int? attended, int? absent, int? totalPlanned}) async {
    if (_userId == null || !_stats.containsKey(subjectId)) return 'Subject not found';

    final current = _stats[subjectId]!;
    final newTotal = totalPlanned ?? current.totalPlanned;
    final newAttended = attended ?? current.attended;
    final newAbsent = absent ?? current.absent;

    // Validation
    if (newTotal < 0) return 'Total planned cannot be negative';
    if (newAttended < 0) return 'Attended cannot be negative';
    if (newAbsent < 0) return 'Absent cannot be negative';
    if ((newAttended + newAbsent) > newTotal) {
      return 'Attended ($newAttended) + Absent ($newAbsent) cannot exceed Total Planned ($newTotal)';
    }

    final updated = current.copyWith(
      totalPlanned: newTotal,
      attended: newAttended,
      absent: newAbsent,
    );

    _stats[subjectId] = updated;
    notifyListeners();

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('subjects')
        .doc(subjectId)
        .set(updated.toMap(), SetOptions(merge: true));

    return null; // success
  }

  void _checkOverallAttendanceDanger() {
    // If any subject is in danger, we want to broadcast urgency.
    // This can be polled by FocusService easily via Context.watch<AttendanceService>()
  }

  bool isOverallUrgent() {
    if (_stats.isEmpty) return false;
    return _stats.values.any((s) => s.riskStatus == 'danger');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _socket?.dispose();
    super.dispose();
  }
}
