import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';
import '../models/direct_message_model.dart';
import '../../group_hub/models/chat_message_model.dart';
import '../../group_hub/models/squad_model.dart';

class FriendsRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  String _getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  Stream<List<Friend>> watchFriends() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .snapshots()
        .asyncMap((snap) async {
          List<Friend> friends = [];
          for (var doc in snap.docs) {
             // Fetch real-time status from users collection
             final userDoc = await _db.collection('users').doc(doc.id).get();
             if (userDoc.exists) {
                final friendData = userDoc.data() as Map<String, dynamic>;
                final relationData = doc.data() as Map<String, dynamic>;
                friends.add(
                  Friend(
                    uid: doc.id,
                    displayName: friendData['displayName'] ?? 'Unknown User',
                    photoUrl: friendData['photoUrl'],
                    status: UserStatusX.fromString(friendData['status'] ?? 'online'),
                    joinedAt: (relationData['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    lastMessage: relationData['lastMessage'],
                    lastMessageTime: (relationData['lastMessageTime'] as Timestamp?)?.toDate(),
                  )
                );
             }
          }
          return friends;
        });
  }

  /// Streams the true friends count derived live from the subcollection.
  /// This is always accurate unlike a stored integer counter.
  Stream<int> watchFriendsCount(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<List<Map<String, dynamic>>> watchFriendRequests() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('friendRequests')
        .where('type', isEqualTo: 'incoming')
        .snapshots()
        .map((s) => s.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
  }

  Future<List<Map<String, dynamic>>> searchUsersByName(String query) async {
    if (query.trim().isEmpty) return [];
    
    // Convert to lowercase array of searchable strings or do an exact/startsWith query
    // Since firestore doesn't natively support full text search well without Algolia, 
    // we'll do a basic '>=' & '<=' for a start.
    final snap = await _db.collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(11) // Fetch 11 in case one is the current user
        .get();

    return snap.docs
        .where((d) => d.id != _uid) // Exclude self
        .take(10) // Limit exactly to 10
        .map((d) => {'uid': d.id, ...d.data()})
        .toList();
  }

  Future<void> sendFriendRequest(String targetUid) async {
    final user = _auth.currentUser!;
    final batch = _db.batch();

    // Outgoing reference
    batch.set(_db.collection('users').doc(_uid).collection('friendRequests').doc(targetUid), {
      'type': 'outgoing',
      'requestedAt': FieldValue.serverTimestamp(),
    });

    // Incoming reference
    batch.set(_db.collection('users').doc(targetUid).collection('friendRequests').doc(_uid), {
      'type': 'incoming',
      'requestedAt': FieldValue.serverTimestamp(),
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
    });

    await batch.commit();
  }

  Future<void> acceptFriendRequest(String fromUid) async {
     // Check if already friends to prevent double-incrementing the count
     final alreadyFriendDoc = await _db
         .collection('users')
         .doc(_uid)
         .collection('friends')
         .doc(fromUid)
         .get();
     final alreadyFriends = alreadyFriendDoc.exists;

     final batch = _db.batch();

     // Add to my friends list
     batch.set(_db.collection('users').doc(_uid).collection('friends').doc(fromUid), {
        'joinedAt': FieldValue.serverTimestamp(),
     });

     // Add to their friends list
     batch.set(_db.collection('users').doc(fromUid).collection('friends').doc(_uid), {
        'joinedAt': FieldValue.serverTimestamp(),
     });

     // Delete requests from both sides
     batch.delete(_db.collection('users').doc(_uid).collection('friendRequests').doc(fromUid));
     batch.delete(_db.collection('users').doc(fromUid).collection('friendRequests').doc(_uid));

     await batch.commit();
  }

  Future<void> declineFriendRequest(String fromUid) async {
    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(_uid).collection('friendRequests').doc(fromUid));
    batch.delete(_db.collection('users').doc(fromUid).collection('friendRequests').doc(_uid));
    await batch.commit();
  }

  Stream<bool> watchHasPendingRequest(String targetUid) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('friendRequests')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<bool> isFriend(String targetUid) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> unfriend(String targetUid) async {
    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(_uid).collection('friends').doc(targetUid));
    batch.update(_db.collection('users').doc(_uid), {
      'friendsCount': FieldValue.increment(-1)
    });
    batch.delete(_db.collection('users').doc(targetUid).collection('friends').doc(_uid));
    batch.update(_db.collection('users').doc(targetUid), {
      'friendsCount': FieldValue.increment(-1)
    });
    await batch.commit();
  }

  // --- SQUAD INVITE STUFF ---

  /// Sends a squad invite notification to [targetUid].
  Future<void> sendSquadInvite({
    required String targetUid,
    required String squadId,
    required String squadName,
    required String squadBadge,
  }) async {
    final user = _auth.currentUser!;
    await _db
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .doc('squad_\${squadId}_\${_uid}')
        .set({
      'type': 'squadInvite',
      'squadId': squadId,
      'squadName': squadName,
      'squadBadge': squadBadge,
      'fromUid': _uid,
      'fromName': user.displayName ?? 'Someone',
      'fromPhoto': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams all pending notifications (friend requests + squad invites).
  /// Both subcollections are watched as real-time streams so the count
  /// updates instantly when a request is accepted or dismissed.
  Stream<List<Map<String, dynamic>>> watchAllNotifications() {
    final notifStream = _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final friendReqStream = _db
        .collection('users')
        .doc(_uid)
        .collection('friendRequests')
        .where('type', isEqualTo: 'incoming')
        .snapshots();

    // CombineLatest: cache the latest snapshot from each stream,
    // emit a merged list whenever either changes.
    QuerySnapshot? latestNotif;
    QuerySnapshot? latestFriendReq;

    List<Map<String, dynamic>> _merge() {
      final notifications = <Map<String, dynamic>>[];

      if (latestNotif != null) {
        for (final doc in latestNotif!.docs) {
          notifications.add({'id': doc.id, ...doc.data() as Map<String, dynamic>});
        }
      }
      if (latestFriendReq != null) {
        for (final doc in latestFriendReq!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          notifications.add({
            ...data,
            'id': doc.id,
            'type': 'friendRequest',
            'uid': doc.id,
          });
        }
      }
      return notifications;
    }

    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    final sub1 = notifStream.listen((snap) {
      latestNotif = snap;
      if (latestFriendReq != null) controller.add(_merge());
    });
    final sub2 = friendReqStream.listen((snap) {
      latestFriendReq = snap;
      if (latestNotif != null) controller.add(_merge());
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  /// Accept a squad invite — calls joinSquad logic directly.
  Future<void> acceptSquadInvite(String notifId, String squadId) async {
    final user = _auth.currentUser!;
    // Add to squad members
    final batch = _db.batch();
    batch.set(
      _db.collection('squads').doc(squadId).collection('members').doc(_uid),
      {
        'role': SquadRole.member.name,
        'joinedAt': FieldValue.serverTimestamp(),
        'displayName': user.displayName ?? 'Member',
        'photoUrl': user.photoURL,
      },
    );
    batch.update(_db.collection('squads').doc(squadId), {
      'memberCount': FieldValue.increment(1),
    });
    batch.set(_db.collection('users').doc(_uid), {
      'squadIds': FieldValue.arrayUnion([squadId]),
    }, SetOptions(merge: true));
    // Delete the notification
    batch.delete(
      _db.collection('users').doc(_uid).collection('notifications').doc(notifId),
    );
    await batch.commit();
  }

  /// Decline / dismiss a notification.
  Future<void> dismissNotification(String notifId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc(notifId)
        .delete();
  }

  // --- PRIVATE CHAT STUFF --- 
  
  Stream<List<DirectMessage>> watchDMs(String targetUid) {
     final chatId = _getChatId(_uid, targetUid);
     return _db.collection('directMessages').doc(chatId).collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(100)
        .snapshots()
        .map((s) => s.docs.map(DirectMessage.fromDoc).toList());
  }

  Future<void> sendDM(
    String targetUid,
    String content,
    MessageType type, {
    String? fileUrl,
    String? fileName,
    int? fileSize,
  }) async {
     final chatId = _getChatId(_uid, targetUid);
     
     final batch = _db.batch();
     final msgRef = _db.collection('directMessages').doc(chatId).collection('messages').doc();
     
     batch.set(msgRef, {
         'senderId': _uid,
         'text': content,
         'timestamp': FieldValue.serverTimestamp(),
         'type': type.name,
         if (fileUrl != null) 'fileUrl': fileUrl,
         if (fileName != null) 'fileName': fileName,
         if (fileSize != null) 'fileSize': fileSize,
     });

     String snippet = content;
     if (type == MessageType.image) snippet = '📸 Photo';
     if (type == MessageType.file) snippet = '📎 Document';

     final updateData = {
       'lastMessage': snippet,
       'lastMessageTime': FieldValue.serverTimestamp(),
     };

     batch.set(_db.collection('users').doc(_uid).collection('friends').doc(targetUid), updateData, SetOptions(merge: true));
     batch.set(_db.collection('users').doc(targetUid).collection('friends').doc(_uid), updateData, SetOptions(merge: true));
     
     await batch.commit();
  }
}
