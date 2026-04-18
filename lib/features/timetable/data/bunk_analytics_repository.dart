import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se_hack/features/timetable/data/models/academic_calendar.dart';
import 'package:se_hack/features/timetable/data/models/bunk_plan.dart';

class BunkAnalyticsRepository {
  final FirebaseFirestore _firestore;

  BunkAnalyticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Paths
  DocumentReference<Map<String, dynamic>> _calendarDoc(String userId) =>
      _firestore.collection('academic_calendars').doc(userId);

  DocumentReference<Map<String, dynamic>> _planDoc(String userId) =>
      _firestore.collection('bunk_plans').doc(userId);

  // --- Academic Calendar ---

  Future<AcademicCalendar?> getAcademicCalendar(String userId) async {
    final doc = await _calendarDoc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AcademicCalendar.fromJson(doc.data()!);
  }

  Future<void> saveAcademicCalendar(String userId, AcademicCalendar calendar) async {
    await _calendarDoc(userId).set(calendar.toJson());
  }

  Future<void> deleteAcademicCalendar(String userId) async {
    await _calendarDoc(userId).delete();
  }

  // --- Bunk Plan ---

  Future<BunkPlan?> getBunkPlan(String userId) async {
    final doc = await _planDoc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return BunkPlan.fromJson(doc.data()!);
  }

  Future<void> saveBunkPlan(String userId, BunkPlan plan) async {
    await _planDoc(userId).set(plan.toJson());
  }

  Future<void> deleteBunkPlan(String userId) async {
    await _planDoc(userId).delete();
  }
}
