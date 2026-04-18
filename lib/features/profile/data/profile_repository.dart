import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';
import '../../friends/models/friend_model.dart';

class ProfileRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  Stream<UserProfile> watchProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) => UserProfile.fromDoc(doc));
  }

  Future<void> updateStatus(UserStatus status) async {
    await _db.collection('users').doc(_uid).update({
      'status': status.name,
    });
  }

  Stream<Map<DateTime, int>> watchActivityLog(String uid) {
    return _db.collection('users').doc(uid).collection('activityLog').snapshots().map((snap) {
       Map<DateTime, int> log = {};
       for (var doc in snap.docs) {
          final dateStr = doc.id; // Expecting 'YYYY-MM-DD'
          try {
            final date = DateTime.parse(dateStr);
            log[date] = (doc['points'] as num?)?.toInt() ?? 0;
          } catch(e) {
             // ignore parsing error
          }
       }
       return log;
    });
  }

  // Example of seeding Badges, if we want them as reference for later. (We will display them from here)
  Future<List<Map<String, dynamic>>> fetchAvailableBadges() async {
     // For this hackathon scope, we can hardcode the initial available list to show up, 
     // but the condition logic checks UserProfile.badges (a list of acquired string names).
     // Since user asked for firestore, returning from a 'badges' collection is better.
     try {
       final snap = await _db.collection('badges').get();
       if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) => d.data()).toList();
       }
       // Seed if empty
       final sampleBadges = [
         {'id': 'focus_master', 'name': 'Focus Master', 'icon': '🏆', 'condition': 'Earn 1000 points'},
         {'id': 'streak_7', 'name': '7-Day Streak', 'icon': '🔥', 'condition': 'Study 7 days in a row'},
         {'id': 'squad_leader', 'name': 'Squad Leader', 'icon': '👑', 'condition': 'Create a squad'},
         {'id': 'night_owl', 'name': 'Night Owl', 'icon': '🦉', 'condition': 'Focus after midnight'},
       ];
       final batch = _db.batch();
       for (var b in sampleBadges) {
          batch.set(_db.collection('badges').doc(b['id']), b);
       }
       await batch.commit();
       return sampleBadges;
     } catch (e) {
        return [];
     }
  }
}
