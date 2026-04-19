import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/squad_model.dart';
import '../models/chat_message_model.dart';
import '../models/kanban_task_model.dart';
import '../models/deadline_model.dart';
import '../models/notes_page_model.dart';
import '../models/challenge_resource_model.dart';
import '../models/whiteboard_model.dart';

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
      'name': name,
      'tagline': tagline,
      'badge': badge,
      'type': type.name,
      'examPrepActive': false,
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'maxMembers': 15,
      'memberCount': 1,
    });

    batch.set(squadRef.collection('members').doc(_uid), {
      'role': 'leader',
      'joinedAt': FieldValue.serverTimestamp(),
      'displayName': user.displayName ?? 'Leader',
      'photoUrl': user.photoURL,
    });

    batch.set(_db.collection('users').doc(_uid), {
      'squadIds': FieldValue.arrayUnion([squadRef.id]),
    }, SetOptions(merge: true));

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
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
          'displayName': user.displayName ?? user.email?.split('@').first ?? 'Member',
          'photoUrl': user.photoURL,
        },
      );
      batch.update(_db.collection('squads').doc(squadId), {
        'memberCount': FieldValue.increment(1),
      });
      batch.set(_db.collection('users').doc(_uid), {
        'squadIds': FieldValue.arrayUnion([squadId]),
      }, SetOptions(merge: true));
      await batch.commit();
    } else {
      await _db
          .collection('squads')
          .doc(squadId)
          .collection('requests')
          .doc(_uid)
          .set({
            'requestedAt': FieldValue.serverTimestamp(),
            'status': 'pending',
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
          });
    }
  }

  Future<void> leaveSquad(String squadId) async {
    final batch = _db.batch();
    batch.delete(
      _db.collection('squads').doc(squadId).collection('members').doc(_uid),
    );
    batch.update(_db.collection('squads').doc(squadId), {
      'memberCount': FieldValue.increment(-1),
    });
    batch.set(_db.collection('users').doc(_uid), {
      'squadIds': FieldValue.arrayRemove([squadId]),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<List<String>> getMySquadIds() async {
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>?;
    final squadIds = List<String>.from(data?['squadIds'] ?? []);
    if (data != null &&
        data.containsKey('squadId') &&
        data['squadId'] != null) {
      if (!squadIds.contains(data['squadId'])) squadIds.add(data['squadId']);
    }
    return squadIds;
  }

  Stream<Squad?> watchSquad(String squadId) => _db
      .collection('squads')
      .doc(squadId)
      .snapshots()
      .map((s) => s.exists ? Squad.fromDoc(s) : null);

  Stream<List<SquadMember>> watchMembers(String squadId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('members')
      .snapshots()
      .map(
        (s) =>
            s.docs.map(SquadMember.fromDoc).toList()
              ..sort((a, b) => a.role.index.compareTo(b.role.index)),
      );

  Stream<List<Squad>> watchMySquads(List<String> squadIds) {
    if (squadIds.isEmpty) return Stream.value([]);
    // Limit to 10 for Firestore 'whereIn' restrictions
    final ids = squadIds.length > 10 ? squadIds.sublist(0, 10) : squadIds;
    return _db
        .collection('squads')
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map((snap) => snap.docs.map(Squad.fromDoc).toList());
  }

  Future<List<Squad>> searchSquads(String query) async {
    final snap = await _db
        .collection('squads')
        .where('type', isNotEqualTo: 'closed')
        .limit(20)
        .get();
    return snap.docs
        .map(Squad.fromDoc)
        .where(
          (s) =>
              s.name.toLowerCase().contains(query.toLowerCase()) ||
              query.isEmpty,
        )
        .toList();
  }

  Future<void> changeRole(
    String squadId,
    String targetUid,
    SquadRole newRole,
  ) => _db
      .collection('squads')
      .doc(squadId)
      .collection('members')
      .doc(targetUid)
      .update({
        'role': newRole == SquadRole.coLeader ? 'co_leader' : newRole.name,
      });

  Future<void> kickMember(String squadId, String targetUid) async {
    final batch = _db.batch();
    batch.delete(
      _db
          .collection('squads')
          .doc(squadId)
          .collection('members')
          .doc(targetUid),
    );
    batch.update(_db.collection('squads').doc(squadId), {
      'memberCount': FieldValue.increment(-1),
    });
    batch.set(_db.collection('users').doc(targetUid), {
      'squadIds': FieldValue.arrayRemove([squadId]),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> acceptJoinRequest(String squadId, String requestUid) async {
    final reqDoc = await _db
        .collection('squads')
        .doc(squadId)
        .collection('requests')
        .doc(requestUid)
        .get();
    final d = reqDoc.data();
    final batch = _db.batch();
    batch.set(
      _db
          .collection('squads')
          .doc(squadId)
          .collection('members')
          .doc(requestUid),
      {
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'displayName': d?['displayName'],
        'photoUrl': d?['photoUrl'],
      },
    );
    batch.delete(reqDoc.reference);
    batch.update(_db.collection('squads').doc(squadId), {
      'memberCount': FieldValue.increment(1),
    });
    batch.set(_db.collection('users').doc(requestUid), {
      'squadIds': FieldValue.arrayUnion([squadId]),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> watchJoinRequests(String squadId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('requests')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.map((d) => {'uid': d.id, ...d.data()}).toList());

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<ChatMessage>> watchMessages(String squadId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('chat')
      .orderBy('createdAt', descending: false)
      .limitToLast(100)
      .snapshots()
      .map((s) => s.docs.map(ChatMessage.fromDoc).toList());

  Future<void> sendMessage(
    String squadId,
    MessageType type,
    String content, {
    String? fileUrl,
    String? fileName,
    int? fileSize,
  }) async {
    final user = _auth.currentUser!;
    
    final batch = _db.batch();
    final msgRef = _db.collection('squads').doc(squadId).collection('chat').doc();
    
    batch.set(msgRef, {
      'uid': _uid,
      'type': type.name,
      'content': content,
      'pinned': false,
      'createdAt': FieldValue.serverTimestamp(),
      'senderName': user.displayName ?? user.email?.split('@').first ?? 'Member',
      'senderPhoto': user.photoURL,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
    });

    String snippet = content;
    if (type == MessageType.image) snippet = '📸 Photo';
    if (type == MessageType.file) snippet = '📎 Document';
    if (type == MessageType.code) snippet = '</> Code snippet';

    final safeName = user.displayName ?? user.email?.split('@').first ?? 'Someone';
    batch.update(_db.collection('squads').doc(squadId), {
      'lastMessage': "$safeName: $snippet",
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> pinMessage(String squadId, String messageId, bool pinned) => _db
      .collection('squads')
      .doc(squadId)
      .collection('chat')
      .doc(messageId)
      .update({'pinned': pinned});

  Stream<List<ChatMessage>> watchPinned(String squadId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('chat')
      .where('pinned', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(ChatMessage.fromDoc).toList());

  // ═══════════════════════════════════════════════════════════════════════════
  // KANBAN
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<KanbanTask>> watchKanban(String squadId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('kanban')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(KanbanTask.fromDoc).toList());

  Future<void> addKanbanTask(String squadId, KanbanTask task) => _db
      .collection('squads')
      .doc(squadId)
      .collection('kanban')
      .add(task.toMap());

  Future<void> moveKanbanTask(
    String squadId,
    String taskId,
    KanbanColumn col,
  ) => _db
      .collection('squads')
      .doc(squadId)
      .collection('kanban')
      .doc(taskId)
      .update({'column': col.name});

  Future<void> deleteKanbanTask(String squadId, String taskId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('kanban')
      .doc(taskId)
      .delete();

  // ═══════════════════════════════════════════════════════════════════════════
  // DEADLINES
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<Deadline>> watchDeadlines(String squadId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('deadlines')
      .orderBy('dueDate')
      .snapshots()
      .map((s) => s.docs.map(Deadline.fromDoc).toList());

  Future<void> addDeadline(
    String squadId,
    String title,
    String subject,
    DateTime due,
  ) async {
    final existing = await _db
        .collection('squads')
        .doc(squadId)
        .collection('deadlines')
        .where('title', isEqualTo: title)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final current = List<String>.from(doc['addedBy'] ?? []);
      if (!current.contains(_uid)) {
        await doc.reference.update({
          'addedBy': FieldValue.arrayUnion([_uid]),
          'priority': current.length >= 3 ? 'squad_priority' : 'normal',
        });
      }
    } else {
      await _db.collection('squads').doc(squadId).collection('deadlines').add({
        'title': title,
        'subject': subject,
        'dueDate': Timestamp.fromDate(due),
        'addedBy': [_uid],
        'priority': 'normal',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteDeadline(String squadId, String deadlineId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('deadlines')
      .doc(deadlineId)
      .delete();

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES WIKI
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<NotesPage>> watchNotes(String squadId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('notes')
      .orderBy('lastEditedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(NotesPage.fromDoc).toList());

  Future<void> savePage(String squadId, NotesPage page) async {
    final user = _auth.currentUser!;
    final ref = page.id.isEmpty
        ? _db.collection('squads').doc(squadId).collection('notes').doc()
        : _db
              .collection('squads')
              .doc(squadId)
              .collection('notes')
              .doc(page.id);
    await ref.set({
      'title': page.title,
      'content': page.content,
      'subject': page.subject,
      'lastEditedBy': _uid,
      'lastEditedByName': user.displayName ?? user.email?.split('@').first ?? 'Member',
      'lastEditedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deletePage(String squadId, String pageId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('notes')
      .doc(pageId)
      .delete();

  // ═══════════════════════════════════════════════════════════════════════════
  // RESOURCES / VAULT
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<SquadResource>> watchResources(String squadId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('resources')
      .orderBy('uploadedAt', descending: true)
      .snapshots()
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
      'uploaderName': user.displayName ?? user.email?.split('@').first ?? 'Member',
      'uploadedAt': FieldValue.serverTimestamp(),
      'fileType': fileName.toLowerCase().endsWith('.pdf')
          ? 'pdf'
          : (fileName.toLowerCase().endsWith('.png') ||
                fileName.toLowerCase().endsWith('.jpg') ||
                fileName.toLowerCase().endsWith('.jpeg'))
          ? 'image'
          : 'other',
    });
  }

  Future<void> deleteResource(String squadId, String resourceId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('resources')
      .doc(resourceId)
      .delete();

  // ═══════════════════════════════════════════════════════════════════════════
  // EXAM PREP
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> activateExamPrep(
    String squadId,
    String subject,
    DateTime examDate,
  ) async {
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
        'column': col,
        'isExamPrep': true,
        'subject': subject,
        'assignees': [],
        'priority': 'high',
        'createdBy': 'system',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    batch.set(squadRef.collection('chat').doc(), {
      'uid': 'system',
      'type': 'text',
      'content':
          '📌 Exam Prep activated for **$subject**. Exam on ${examDate.day}/${examDate.month}/${examDate.year}. Go! 🚀',
      'pinned': true,
      'createdAt': FieldValue.serverTimestamp(),
      'senderName': 'System',
      'senderPhoto': null,
    });

    await batch.commit();
  }

  Future<void> deactivateExamPrep(String squadId) async {
    await _db.collection('squads').doc(squadId).update({
      'examPrepActive': false,
      'examPrepSubject': null,
      'examPrepDate': null,
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WHITEBOARDS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> createWhiteboard(String squadId, String name) async {
    final ref = await _db
        .collection('squads')
        .doc(squadId)
        .collection('whiteboards')
        .add({
      'name': name,
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<Whiteboard>> watchWhiteboards(String squadId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('whiteboards')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Whiteboard.fromDoc).toList());

  Future<void> deleteWhiteboard(String squadId, String whiteboardId) async {
    // Delete all strokes first
    final strokes = await _db
        .collection('squads')
        .doc(squadId)
        .collection('whiteboards')
        .doc(whiteboardId)
        .collection('strokes')
        .get();
    final batch = _db.batch();
    for (final doc in strokes.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(
      _db.collection('squads').doc(squadId).collection('whiteboards').doc(whiteboardId),
    );
    await batch.commit();
  }

  Stream<List<WhiteboardStroke>> watchStrokes(String squadId, String whiteboardId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('whiteboards')
      .doc(whiteboardId)
      .collection('strokes')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(WhiteboardStroke.fromDoc).toList());

  Future<void> addStroke(String squadId, String whiteboardId, WhiteboardStroke stroke) async {
    await _db
        .collection('squads')
        .doc(squadId)
        .collection('whiteboards')
        .doc(whiteboardId)
        .collection('strokes')
        .add(stroke.toMap());
  }

  /// Saves a stroke and returns its Firestore document ID (for local undo).
  Future<String?> addStrokeGetId(String squadId, String whiteboardId, WhiteboardStroke stroke) async {
    try {
      final ref = await _db
          .collection('squads')
          .doc(squadId)
          .collection('whiteboards')
          .doc(whiteboardId)
          .collection('strokes')
          .add(stroke.toMap());
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a specific stroke by its doc ID — used for local undo.
  Future<void> deleteStrokeById(String squadId, String whiteboardId, String strokeId) => _db
      .collection('squads')
      .doc(squadId)
      .collection('whiteboards')
      .doc(whiteboardId)
      .collection('strokes')
      .doc(strokeId)
      .delete();

  Future<void> undoLastStroke(String squadId, String whiteboardId) async {
    final snap = await _db
        .collection('squads')
        .doc(squadId)
        .collection('whiteboards')
        .doc(whiteboardId)
        .collection('strokes')
        .where('uid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.delete();
    }
  }

  Future<void> clearAllStrokes(String squadId, String whiteboardId) async {
    final snap = await _db
        .collection('squads')
        .doc(squadId)
        .collection('whiteboards')
        .doc(whiteboardId)
        .collection('strokes')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
