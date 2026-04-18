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
     final fromUserDoc = await _db.collection('users').doc(fromUid).get();
     final d = fromUserDoc.data();

     final user = _auth.currentUser!;

     final batch = _db.batch();
     
     // Add to my friends list
     batch.set(_db.collection('users').doc(_uid).collection('friends').doc(fromUid), {
        'joinedAt': FieldValue.serverTimestamp(),
     });
     batch.update(_db.collection('users').doc(_uid), {
        'friendsCount': FieldValue.increment(1)
     });

     // Add to their friends list
     batch.set(_db.collection('users').doc(fromUid).collection('friends').doc(_uid), {
        'joinedAt': FieldValue.serverTimestamp(),
     });
     batch.update(_db.collection('users').doc(fromUid), {
        'friendsCount': FieldValue.increment(1)
     });

     // Delete requests
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
  Stream<List<Map<String, dynamic>>> watchAllNotifications() {
    // Merge friend requests (incoming) and squad invites from notifications subcollection
    return _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((notifSnap) async {
      final notifications = <Map<String, dynamic>>[];

      // Squad invites from notifications collection
      for (final doc in notifSnap.docs) {
        notifications.add({'id': doc.id, ...doc.data()});
      }

      // Friend requests
      final friendReqSnap = await _db
          .collection('users')
          .doc(_uid)
          .collection('friendRequests')
          .where('type', isEqualTo: 'incoming')
          .get();
      for (final doc in friendReqSnap.docs) {
        // Spread FIRST so our 'type' key overrides the Firestore 'type: incoming'
        notifications.add({
          ...doc.data(),
          'id': doc.id,
          'type': 'friendRequest',
          'uid': doc.id,
        });
      }

      return notifications;
    });
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
