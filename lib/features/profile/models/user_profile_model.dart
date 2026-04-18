import 'package:cloud_firestore/cloud_firestore.dart';
import '../../friends/models/friend_model.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String bio;
  final UserStatus status;
  final int points;
  final List<String> badges;
  final List<String> squadIds;
  final int followingCount;
  final int friendsCount;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.bio,
    required this.status,
    required this.points,
    required this.badges,
    required this.squadIds,
    required this.followingCount,
    required this.friendsCount,
  });

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] ?? 'Unknown User',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'] ?? 'Busy studying...',
      status: UserStatusX.fromString(data['status'] ?? 'online'),
      points: (data['points'] as num?)?.toInt() ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      squadIds: List<String>.from(data['squadIds'] ?? []),
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
      friendsCount: (data['friendsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'status': status.name,
      'points': points,
      'badges': badges,
      'squadIds': squadIds,
      'followingCount': followingCount,
      'friendsCount': friendsCount,
    };
  }
}
