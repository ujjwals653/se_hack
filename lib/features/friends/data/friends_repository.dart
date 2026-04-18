import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';
import '../models/direct_message_model.dart';
import '../../group_hub/models/chat_message_model.dart';

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
                friends.add(
                  Friend(
                    uid: doc.id,
                    displayName: friendData['displayName'] ?? 'Unknown User',
                    photoUrl: friendData['photoUrl'],
                    status: UserStatusX.fromString(friendData['status'] ?? 'online'),
                    joinedAt: (doc['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
        .limit(20)
        .get();

    return snap.docs
        .where((d) => d.id != _uid) // Exclude self
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

  // --- PRIVATE CHAT STUFF --- 
  
  Stream<List<DirectMessage>> watchDMs(String targetUid) {
     final chatId = _getChatId(_uid, targetUid);
     return _db.collection('directMessages').doc(chatId).collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(100)
        .snapshots()
        .map((s) => s.docs.map(DirectMessage.fromDoc).toList());
  }

  Future<void> sendDM(String targetUid, String content, MessageType type) async {
     final chatId = _getChatId(_uid, targetUid);
     await _db.collection('directMessages').doc(chatId).collection('messages').add({
         'senderId': _uid,
         'text': content,
         'timestamp': FieldValue.serverTimestamp(),
         'type': type.name,
     });

     // Optionally, update a chat preview in users/{uid}/recentChats
  }
}
