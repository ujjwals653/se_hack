import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se_hack/features/timetable/data/models/timetable.dart';

class TimetableRepository {
  final FirebaseFirestore _firestore;

  TimetableRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('timetables');

  /// Fetch timetable for a specific user.
  Future<Timetable?> getTimetable(String userId) async {
    final doc = await _collection.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Timetable.fromFirestore(doc.data()!);
  }

  /// Save (create/overwrite) a timetable for a specific user.
  Future<void> saveTimetable(String userId, Timetable timetable) async {
    await _collection.doc(userId).set(timetable.toFirestore());
  }

  /// Delete the timetable document for a user (discard).
  Future<void> deleteTimetable(String userId) async {
    await _collection.doc(userId).delete();
  }
}
