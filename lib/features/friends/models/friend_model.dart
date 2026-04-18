import 'package:cloud_firestore/cloud_firestore.dart';

enum UserStatus { online, idle, invisible }

extension UserStatusX on UserStatus {
  String get name {
    switch (this) {
      case UserStatus.online:
        return 'online';
      case UserStatus.idle:
        return 'idle';
      case UserStatus.invisible:
        return 'invisible';
    }
  }

  static UserStatus fromString(String status) {
    switch (status) {
      case 'idle':
        return UserStatus.idle;
      case 'invisible':
        return UserStatus.invisible;
      case 'online':
      default:
        return UserStatus.online;
    }
  }
}

class Friend {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final UserStatus status;
  final DateTime joinedAt;

  Friend({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.status,
    required this.joinedAt,
  });

  factory Friend.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      uid: doc.id,
      displayName: data['displayName'] ?? 'Unknown User',
      photoUrl: data['photoUrl'],
      status: UserStatusX.fromString(data['status'] ?? 'online'),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'status': status.name,
      'joinedAt': FieldValue.serverTimestamp(),
    };
  }
}
