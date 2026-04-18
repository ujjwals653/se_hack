import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/squad_model.dart';
import '../models/chat_message_model.dart';
import '../models/kanban_task_model.dart';
import '../models/deadline_model.dart';
import '../models/notes_page_model.dart';
import '../models/challenge_resource_model.dart';

class SquadRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ═══════════════════════════════════════════════════════════════════════════
  // SQUAD CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> createSquad({
    required String name,
    required String tagline,
    required String badge,
    required SquadType type,
  }) async {
    final user = _auth.currentUser!;
    final squadRef = _db.collection('squads').doc();
    final batch = _db.batch();

    batch.set(squadRef, {
      'name': name, 'tagline': tagline, 'badge': badge,
      'type': type.name, 'trophies': 0, 'weeklyPoints': 0,
      'healthScore': 100, 'examPrepActive': false,
      'createdBy': _uid, 'createdAt': FieldValue.serverTimestamp(),
      'maxMembers': 15, 'memberCount': 1,
    });

    batch.set(squadRef.collection('members').doc(_uid), {
      'role': 'leader', 'joinedAt': FieldValue.serverTimestamp(),
      'weeklyFocusMinutes': 0, 'totalTrophies': 0,
      'xp': 0, 'level': 1, 'streakDays': 0,
      'displayName': user.displayName ?? 'Leader',
      'photoUrl': user.photoURL,
    });

    batch.set(
      _db.collection('users').doc(_uid),
      {'squadId': squadRef.id, 'coins': 0, 'totalTrophies': 0, 'xp': 0, 'level': 1},
      SetOptions(merge: true),
    );

    await batch.commit();
    return squadRef.id;
  }

  Future<void> joinSquad(String squadId) async {
    final user = _auth.currentUser!;
    final snap = await _db.collection('squads').doc(squadId).get();
    final squad = Squad.fromDoc(snap);

    if (squad.type == SquadType.open) {
      final batch = _db.batch();
      batch.set(
        _db.collection('squads').doc(squadId).collection('members').doc(_uid),
        {
          'role': 'member', 'joinedAt': FieldValue.serverTimestamp(),
          'weeklyFocusMinutes': 0, 'totalTrophies': 0,
          'xp': 0, 'level': 1, 'streakDays': 0,
          'displayName': user.displayName ?? 'Member',
          'photoUrl': user.photoURL,
        },
      );
      batch.update(_db.collection('squads').doc(squadId),
          {'memberCount': FieldValue.increment(1)});
      batch.set(_db.collection('users').doc(_uid),
          {'squadId': squadId}, SetOptions(merge: true));
      await batch.commit();
    } else {
      await _db.collection('squads').doc(squadId)
          .collection('requests').doc(_uid).set({
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'displayName': user.displayName, 'photoUrl': user.photoURL,
      });
    }
  }

  Future<void> leaveSquad(String squadId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('squads').doc(squadId).collection('members').doc(_uid));
    batch.update(_db.collection('squads').doc(squadId),
        {'memberCount': FieldValue.increment(-1)});
    batch.set(_db.collection('users').doc(_uid),
        {'squadId': null}, SetOptions(merge: true));
    await batch.commit();
  }

  Future<String?> getMySquadId() async {
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return (doc.data() as Map<String, dynamic>?)?['squadId'] as String?;
  }

  Stream<Squad?> watchSquad(String squadId) => _db
      .collection('squads').doc(squadId).snapshots()
      .map((s) => s.exists ? Squad.fromDoc(s) : null);

  Stream<List<SquadMember>> watchMembers(String squadId) => _db
      .collection('squads').doc(squadId).collection('members').snapshots()
      .map((s) => s.docs.map(SquadMember.fromDoc).toList()
        ..sort((a, b) => a.role.index.compareTo(b.role.index)));

  Future<List<Squad>> searchSquads(String query) async {
    final snap = await _db.collection('squads')
        .where('type', isNotEqualTo: 'closed').limit(20).get();
    return snap.docs.map(Squad.fromDoc)
        .where((s) => s.name.toLowerCase().contains(query.toLowerCase()) || query.isEmpty)
        .toList();
  }

  Future<void> changeRole(String squadId, String targetUid, SquadRole newRole) =>
      _db.collection('squads').doc(squadId).collection('members').doc(targetUid)
          .update({'role': newRole == SquadRole.coLeader ? 'co_leader' : newRole.name});

  Future<void> kickMember(String squadId, String targetUid) async {
    final batch = _db.batch();
    batch.delete(_db.collection('squads').doc(squadId).collection('members').doc(targetUid));
    batch.update(_db.collection('squads').doc(squadId),
        {'memberCount': FieldValue.increment(-1)});
    batch.set(_db.collection('users').doc(targetUid),
        {'squadId': null}, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> acceptJoinRequest(String squadId, String requestUid) async {
    final reqDoc = await _db.collection('squads').doc(squadId)
        .collection('requests').doc(requestUid).get();
    final d = reqDoc.data();
    final batch = _db.batch();
    batch.set(
      _db.collection('squads').doc(squadId).collection('members').doc(requestUid),
      {
        'role': 'member', 'joinedAt': FieldValue.serverTimestamp(),
        'weeklyFocusMinutes': 0, 'totalTrophies': 0,
        'xp': 0, 'level': 1, 'streakDays': 0,
        'displayName': d?['displayName'], 'photoUrl': d?['photoUrl'],
      },
    );
    batch.delete(reqDoc.reference);
    batch.update(_db.collection('squads').doc(squadId),
        {'memberCount': FieldValue.increment(1)});
    batch.set(_db.collection('users').doc(requestUid),
        {'squadId': squadId}, SetOptions(merge: true));
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> watchJoinRequests(String squadId) => _db
      .collection('squads').doc(squadId).collection('requests')
      .where('status', isEqualTo: 'pending').snapshots()
      .map((s) => s.docs.map((d) => {'uid': d.id, ...d.data()}).toList());

  // ═══════════════════════════════════════════════════════════════════════════
  // TROPHIES & HEALTH
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> awardTrophies(String squadId, int points, String reason) async {
    final ref = _db.collection('squads').doc(squadId);
    final batch = _db.batch();
    batch.update(ref, {
      'trophies': FieldValue.increment(points),
      'weeklyPoints': FieldValue.increment(points),
    });
    batch.set(ref.collection('trophy_log').doc(), {
      'points': points, 'reason': reason,
      'awardedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COINS & XP
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> spendCoins(int amount, String reason) async {
    final userRef = _db.collection('users').doc(_uid);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(userRef);
      final current = ((snap.data() as Map<String, dynamic>?)?['coins'] as num?)?.toInt() ?? 0;
      if (current < amount) return false;
      tx.update(userRef, {'coins': current - amount});
      return true;
    });
  }

  Future<void> awardCoins(String uid, int amount, String reason) async {
    await _db.collection('users').doc(uid).set(
      {'coins': FieldValue.increment(amount)}, SetOptions(merge: true));
  }

  Stream<int> watchMyCoins() => _db.collection('users').doc(_uid).snapshots()
      .map((s) => ((s.data() as Map<String, dynamic>?)?['coins'] as num?)?.toInt() ?? 0);

  Future<void> awardXP(String uid, String squadId, int xp, String reason) async {
    final userRef = _db.collection('users').doc(uid);
    final memberRef = _db.collection('squads').doc(squadId).collection('members').doc(uid);
    await userRef.set({'xp': FieldValue.increment(xp)}, SetOptions(merge: true));
    final snap = await userRef.get();
    final newXP = ((snap.data() as Map<String, dynamic>?)?['xp'] as num?)?.toInt() ?? 0;
    final newLevel = XPEngine.levelFromXP(newXP);
    await userRef.set({'level': newLevel}, SetOptions(merge: true));
    await memberRef.set({'xp': FieldValue.increment(xp), 'level': newLevel},
        SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<ChatMessage>> watchMessages(String squadId) => _db
      .collection('squads').doc(squadId).collection('chat')
      .orderBy('createdAt', descending: false).limitToLast(100).snapshots()
      .map((s) => s.docs.map(ChatMessage.fromDoc).toList());

  Future<void> sendMessage(String squadId, MessageType type, String content) async {
    final user = _auth.currentUser!;
    await _db.collection('squads').doc(squadId).collection('chat').add({
      'uid': _uid, 'type': type.name, 'content': content,
      'pinned': false, 'createdAt': FieldValue.serverTimestamp(),
      'senderName': user.displayName ?? 'Member', 'senderPhoto': user.photoURL,
    });
  }

  Future<void> pinMessage(String squadId, String messageId, bool pinned) =>
      _db.collection('squads').doc(squadId).collection('chat').doc(messageId)
          .update({'pinned': pinned});

  Stream<List<ChatMessage>> watchPinned(String squadId) => _db
      .collection('squads').doc(squadId).collection('chat')
      .where('pinned', isEqualTo: true).snapshots()
      .map((s) => s.docs.map(ChatMessage.fromDoc).toList());

  // ═══════════════════════════════════════════════════════════════════════════
  // KANBAN
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<KanbanTask>> watchKanban(String squadId) => _db
      .collection('squads').doc(squadId).collection('kanban')
      .orderBy('createdAt').snapshots()
      .map((s) => s.docs.map(KanbanTask.fromDoc).toList());

  Future<void> addKanbanTask(String squadId, KanbanTask task) =>
      _db.collection('squads').doc(squadId).collection('kanban').add(task.toMap());

  Future<void> moveKanbanTask(String squadId, String taskId, KanbanColumn col) =>
      _db.collection('squads').doc(squadId).collection('kanban').doc(taskId)
          .update({'column': col.name});

  Future<void> deleteKanbanTask(String squadId, String taskId) =>
      _db.collection('squads').doc(squadId).collection('kanban').doc(taskId).delete();

  // ═══════════════════════════════════════════════════════════════════════════
  // DEADLINES
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<Deadline>> watchDeadlines(String squadId) => _db
      .collection('squads').doc(squadId).collection('deadlines')
      .orderBy('dueDate').snapshots()
      .map((s) => s.docs.map(Deadline.fromDoc).toList());

  Future<void> addDeadline(
      String squadId, String title, String subject, DateTime due) async {
    final existing = await _db.collection('squads').doc(squadId)
        .collection('deadlines').where('title', isEqualTo: title).get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final current = List<String>.from(doc['addedBy'] ?? []);
      if (!current.contains(_uid)) {
        current.add(_uid);
        await doc.reference.update({
          'addedBy': FieldValue.arrayUnion([_uid]),
          'priority': current.length >= 3 ? 'squad_priority' : 'normal',
        });
      }
    } else {
      await _db.collection('squads').doc(squadId).collection('deadlines').add({
        'title': title, 'subject': subject,
        'dueDate': Timestamp.fromDate(due),
        'addedBy': [_uid], 'priority': 'normal',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteDeadline(String squadId, String deadlineId) =>
      _db.collection('squads').doc(squadId).collection('deadlines')
          .doc(deadlineId).delete();

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES WIKI
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<NotesPage>> watchNotes(String squadId) => _db
      .collection('squads').doc(squadId).collection('notes')
      .orderBy('lastEditedAt', descending: true).snapshots()
      .map((s) => s.docs.map(NotesPage.fromDoc).toList());

  Future<void> savePage(String squadId, NotesPage page) async {
    final user = _auth.currentUser!;
    final ref = page.id.isEmpty
        ? _db.collection('squads').doc(squadId).collection('notes').doc()
        : _db.collection('squads').doc(squadId).collection('notes').doc(page.id);
    await ref.set({
      'title': page.title,
      'content': page.content,
      'subject': page.subject,
      'lastEditedBy': _uid,
      'lastEditedByName': user.displayName ?? 'Member',
      'lastEditedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deletePage(String squadId, String pageId) =>
      _db.collection('squads').doc(squadId).collection('notes').doc(pageId).delete();

  // ═══════════════════════════════════════════════════════════════════════════
  // MICRO-CHALLENGES
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<MicroChallenge?> watchTodayChallenge(String squadId) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _db.collection('squads').doc(squadId)
        .collection('micro_challenges').doc(today).snapshots()
        .map((s) => s.exists ? MicroChallenge.fromDoc(s) : null);
  }

  Future<void> createDailyChallenge(String squadId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final challenges = [
      {'title': 'All members log 45-min focus before 10 PM', 'targetMinutes': 45, 'coinReward': 30},
      {'title': 'Complete one Kanban task today', 'targetMinutes': 0, 'coinReward': 20},
      {'title': 'Log a 60-min uninterrupted session', 'targetMinutes': 60, 'coinReward': 40},
      {'title': 'Share one study tip in squad chat', 'targetMinutes': 0, 'coinReward': 15},
      {'title': 'All members add a deadline to radar', 'targetMinutes': 0, 'coinReward': 25},
    ];
    final picked = challenges[DateTime.now().day % challenges.length];
    await _db.collection('squads').doc(squadId)
        .collection('micro_challenges').doc(today).set({
      ...picked, 'date': today, 'completedBy': [], 'status': 'active',
    });
  }

  Future<void> markChallengeComplete(String squadId, String challengeId, int memberCount) async {
    await _db.collection('squads').doc(squadId)
        .collection('micro_challenges').doc(challengeId)
        .update({'completedBy': FieldValue.arrayUnion([_uid])});

    final snap = await _db.collection('squads').doc(squadId)
        .collection('micro_challenges').doc(challengeId).get();
    final completed = List<String>.from(snap['completedBy'] ?? []).length;
    final coinReward = (snap['coinReward'] as num?)?.toInt() ?? 15;

    if (memberCount > 0 && completed / memberCount >= 0.8) {
      await awardTrophies(squadId, 8, 'Micro-challenge completed!');
      await _db.collection('squads').doc(squadId)
          .collection('micro_challenges').doc(challengeId)
          .update({'status': 'completed'});
      for (final uid in List<String>.from(snap['completedBy'] ?? [])) {
        await awardCoins(uid, coinReward, 'Daily challenge');
      }
    }
    // XP for self
    await awardXP(_uid, squadId, 25, 'Micro-challenge completed');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESOURCES / VAULT
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<SquadResource>> watchResources(String squadId) => _db
      .collection('squads').doc(squadId).collection('resources')
      .orderBy('uploadedAt', descending: true).snapshots()
      .map((s) => s.docs.map(SquadResource.fromDoc).toList());

  Future<void> addResourceMetadata({
    required String squadId,
    required String fileName,
    required String storagePath,
    required String subject,
    required String semester,
  }) async {
    final user = _auth.currentUser!;
    await _db.collection('squads').doc(squadId).collection('resources').add({
      'fileName': fileName,
      'storagePath': storagePath,
      'subject': subject,
      'semester': semester,
      'uploadedBy': _uid,
      'uploaderName': user.displayName ?? 'Member',
      'uploadedAt': FieldValue.serverTimestamp(),
      'fileType': fileName.toLowerCase().endsWith('.pdf')
          ? 'pdf'
          : (fileName.toLowerCase().endsWith('.png') ||
                  fileName.toLowerCase().endsWith('.jpg') ||
                  fileName.toLowerCase().endsWith('.jpeg'))
              ? 'image'
              : 'other',
    });
    await awardXP(_uid, squadId, 20, 'Resource uploaded');
    await awardCoins(_uid, 10, 'Resource uploaded');
  }

  Future<void> deleteResource(String squadId, String resourceId) =>
      _db.collection('squads').doc(squadId).collection('resources')
          .doc(resourceId).delete();

  // ═══════════════════════════════════════════════════════════════════════════
  // FOCUS HEATMAP
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> logFocusDay(String uid, int minutes) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _db.collection('users').doc(uid)
        .collection('focusLog').doc(today)
        .set({'minutes': FieldValue.increment(minutes)}, SetOptions(merge: true));
  }

  /// Returns {uid: {date: minutes}} for all squad members, last 30 days.
  Future<Map<String, Map<String, int>>> fetchSquadHeatmap(
      List<SquadMember> members) async {
    final result = <String, Map<String, int>>{};
    for (final m in members) {
      final snap = await _db.collection('users').doc(m.uid)
          .collection('focusLog').orderBy(FieldPath.documentId, descending: true)
          .limit(30).get();
      result[m.uid] = {
        for (final d in snap.docs)
          d.id: ((d.data() as Map<String, dynamic>?))?['minutes'] as int? ?? 0
      };
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXAM PREP
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> activateExamPrep(
      String squadId, String subject, DateTime examDate) async {
    final batch = _db.batch();
    final squadRef = _db.collection('squads').doc(squadId);

    batch.update(squadRef, {
      'examPrepActive': true,
      'examPrepSubject': subject,
      'examPrepDate': Timestamp.fromDate(examDate),
    });

    for (final col in ['backlog', 'todo', 'doing', 'done']) {
      batch.set(squadRef.collection('kanban').doc(), {
        'title': '$subject – ${col.toUpperCase()} zone',
        'description': 'Exam prep auto-generated',
        'column': col, 'isExamPrep': true,
        'subject': subject, 'assignees': [],
        'priority': 'high', 'createdBy': 'system',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    batch.set(squadRef.collection('chat').doc(), {
      'uid': 'system', 'type': 'text',
      'content':
          '📌 Exam Prep activated for **$subject**. Exam on ${examDate.day}/${examDate.month}/${examDate.year}. 1.5× XP for tagged sessions. Go! 🚀',
      'pinned': true, 'createdAt': FieldValue.serverTimestamp(),
      'senderName': 'Lumina', 'senderPhoto': null,
    });

    await batch.commit();
  }

  Future<void> deactivateExamPrep(String squadId) async {
    await _db.collection('squads').doc(squadId).update({
      'examPrepActive': false,
      'examPrepSubject': null,
      'examPrepDate': null,
    });
    await awardTrophies(squadId, 20, 'Exam prep completed! 🎓');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH SCORE (local compute for display; Cloud Function recomputes weekly)
  // ═══════════════════════════════════════════════════════════════════════════

  int computeHealthScore(List<SquadMember> members) {
    if (members.isEmpty) return 0;
    final active = members.where((m) => m.weeklyFocusMinutes > 0).length;
    final avgFocus = members.fold(0, (s, m) => s + m.weeklyFocusMinutes) / members.length;
    final avgStreak = members.fold(0, (s, m) => s + m.streakDays) / members.length;

    final score = ((active / members.length) * 40 +
            (avgFocus / 120).clamp(0, 1) * 40 +
            (avgStreak / 7).clamp(0, 1) * 20)
        .round();
    return score.clamp(0, 100);
  }
}
