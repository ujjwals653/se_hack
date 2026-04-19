import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class GlobalNotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  StreamSubscription? _authSub;
  StreamSubscription? _squadsSub;
  StreamSubscription? _friendsSub;

  final Map<String, StreamSubscription> _squadChatSubs = {};
  final Map<String, StreamSubscription> _squadResourceSubs = {};
  final Map<String, StreamSubscription> _squadNotesSubs = {};
  final Map<String, StreamSubscription> _squadDeadlineSubs = {};
  
  // Track start time to only notify on NEW events
  final Timestamp _appStartTime = Timestamp.now();
  
  bool _initialized = false;
  String? _uid;

  GlobalNotificationService() {
    _initNotifications();
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _uid = user.uid;
        _startListening(user.uid);
      } else {
        _stopListening();
        _uid = null;
      }
    });
  }

  Future<void> _initNotifications() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> _showNotification(int id, String title, String body) async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      'global_notifications',
      'Global Notifications',
      channelDescription: 'Notifications for messages, resources, and deadlines',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(id, title, body, details);
  }
  
  void _startListening(String uid) {
    // 1. Listen to user's squads
    _squadsSub = _db.collection('users').doc(uid).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final rawSquads = (data['squadIds'] as List<dynamic>?) ?? [];
      final List<String> currentSquads = rawSquads.map((e) => e.toString()).toList();
      
      _updateSquadListeners(currentSquads);
    });

    // 2. Listen to friends updates for DMs
    _friendsSub = _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .listen((FriendsSnap) async {
      for (var change in FriendsSnap.docChanges) {
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          
          final lastMsgTime = data['lastMessageTime'] as Timestamp?;
          final lastMsg = data['lastMessage'] as String?;
          
          if (lastMsgTime != null && lastMsgTime.compareTo(_appStartTime) > 0) {
            // Verify who sent the message by fetching the latest DM in their chat thread
            final friendUid = change.doc.id;
            final chatId = _getChatId(uid, friendUid);
            final msgSnap = await _db
                .collection('directMessages')
                .doc(chatId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();
                
            if (msgSnap.docs.isNotEmpty) {
              final msgData = msgSnap.docs.first.data();
              if (msgData['senderId'] != uid) {
                // Fetch friend's name
                final friendDoc = await _db.collection('users').doc(friendUid).get();
                final friendName = friendDoc.data()?['displayName'] ?? 'Friend';
                
                _showNotification(friendUid.hashCode, friendName, lastMsg ?? 'New Message');
              }
            }
          }
        }
      }
    });
  }

  String _getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  void _updateSquadListeners(List<String> currentSquads) {
    // Stop listeners for removed squads
    final toRemove = _squadChatSubs.keys.where((id) => !currentSquads.contains(id)).toList();
    for (var id in toRemove) {
      _squadChatSubs[id]?.cancel();
      _squadChatSubs.remove(id);
      _squadResourceSubs[id]?.cancel();
      _squadResourceSubs.remove(id);
      _squadNotesSubs[id]?.cancel();
      _squadNotesSubs.remove(id);
      _squadDeadlineSubs[id]?.cancel();
      _squadDeadlineSubs.remove(id);
    }

    // Add listeners for new squads
    for (var squadId in currentSquads) {
      if (!_squadChatSubs.containsKey(squadId)) {
        _listenToSquadEvents(squadId);
      }
    }
  }

  void _listenToSquadEvents(String squadId) {
    // Fetch squad basic info for notification title
    String squadName = 'Group';
    _db.collection('squads').doc(squadId).get().then((doc) {
      if (doc.exists) squadName = doc.data()?['name'] ?? 'Group';
    });

    // Chat
    _squadChatSubs[squadId] = _db
        .collection('squads')
        .doc(squadId)
        .collection('chat')
        .where('createdAt', isGreaterThan: _appStartTime)
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          if (data['uid'] != _uid) {
            final senderName = data['senderName'] ?? 'Someone';
            final content = data['content'] ?? '';
            final type = data['type'] ?? 'text';
            
            String msg = content;
            if (type == 'image') msg = '📸 Photo';
            if (type == 'file') msg = '📎 Document Uploaded: ${data['fileName'] ?? ''}';
            
            _showNotification(change.doc.id.hashCode, '$squadName ($senderName)', msg);
          }
        }
      }
    });

    // Resources
    _squadResourceSubs[squadId] = _db
        .collection('squads')
        .doc(squadId)
        .collection('resources')
        .where('uploadedAt', isGreaterThan: _appStartTime)
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          if (data['uploadedBy'] != _uid) {
            final senderName = data['uploaderName'] ?? 'Someone';
            final fileName = data['fileName'] ?? 'A file';
            _showNotification(change.doc.id.hashCode, '$squadName ($senderName)', 'Uploaded a file: $fileName');
          }
        }
      }
    });

    // Notes
    _squadNotesSubs[squadId] = _db
        .collection('squads')
        .doc(squadId)
        .collection('notes')
        .where('lastEditedAt', isGreaterThan: _appStartTime)
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data()!;
          if (data['lastEditedBy'] != _uid) {
            final senderName = data['lastEditedByName'] ?? 'Someone';
            final title = data['title'] ?? 'A note';
            _showNotification(change.doc.id.hashCode, '$squadName ($senderName)', 'Added/updated note: $title');
          }
        }
      }
    });

    // Deadlines
    _squadDeadlineSubs[squadId] = _db
        .collection('squads')
        .doc(squadId)
        .collection('deadlines')
        .where('createdAt', isGreaterThan: _appStartTime)
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          final addedBy = List<String>.from(data['addedBy'] ?? []);
          if (addedBy.isNotEmpty && addedBy.last != _uid) {
            final title = data['title'] ?? 'A deadline';
            final subject = data['subject'] ?? '';
            _showNotification(change.doc.id.hashCode, squadName, 'New Deadline added: $title ($subject)');
          }
        }
      }
    });
  }

  void _stopListening() {
    _squadsSub?.cancel();
    _friendsSub?.cancel();
    
    for (var sub in _squadChatSubs.values) sub.cancel();
    _squadChatSubs.clear();
    
    for (var sub in _squadResourceSubs.values) sub.cancel();
    _squadResourceSubs.clear();
    
    for (var sub in _squadNotesSubs.values) sub.cancel();
    _squadNotesSubs.clear();
    
    for (var sub in _squadDeadlineSubs.values) sub.cancel();
    _squadDeadlineSubs.clear();
  }
}
