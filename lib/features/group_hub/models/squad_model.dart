import 'package:cloud_firestore/cloud_firestore.dart';

enum SquadType { open, inviteOnly, closed }

enum SquadRole { leader, coLeader, elder, member }

extension SquadRoleX on SquadRole {
  String get label {
    switch (this) {
      case SquadRole.leader:   return 'Leader';
      case SquadRole.coLeader: return 'Co-Leader';
      case SquadRole.elder:    return 'Elder';
      case SquadRole.member:   return 'Member';
    }
  }

  String get badge {
    switch (this) {
      case SquadRole.leader:   return '👑';
      case SquadRole.coLeader: return '⚔️';
      case SquadRole.elder:    return '🛡️';
      case SquadRole.member:   return '🎓';
    }
  }

  bool get canKickMembers      => this == SquadRole.leader || this == SquadRole.coLeader;
  bool get canAcceptRequests   => index <= SquadRole.elder.index;
  bool get canPinMessages      => index <= SquadRole.elder.index;
  bool get canEditSquadProfile => this == SquadRole.leader;
  bool get canActivateExamPrep => index <= SquadRole.coLeader.index;
  bool get canPromote          => this == SquadRole.leader;
  bool get canDemote           => this == SquadRole.leader;
  bool get canDisband          => this == SquadRole.leader;
}

// ─── Squad Member ─────────────────────────────────────────────────────────────
class SquadMember {
  final String uid;
  final SquadRole role;
  final DateTime joinedAt;
  String? displayName;
  String? photoUrl;

  SquadMember({
    required this.uid,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.photoUrl,
  });

  factory SquadMember.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SquadMember(
      uid: doc.id,
      role: _parseRole(d['role'] ?? 'member'),
      joinedAt: (d['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      displayName: d['displayName'],
      photoUrl: d['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'role': _roleToString(role),
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  static SquadRole _parseRole(String r) {
    switch (r) {
      case 'leader':    return SquadRole.leader;
      case 'co_leader':
      case 'coLeader':  return SquadRole.coLeader;
      case 'elder':     return SquadRole.elder;
      default:          return SquadRole.member;
    }
  }

  static String _roleToString(SquadRole r) {
    switch (r) {
      case SquadRole.leader:   return 'leader';
      case SquadRole.coLeader: return 'co_leader';
      case SquadRole.elder:    return 'elder';
      case SquadRole.member:   return 'member';
    }
  }
}

// ─── Squad ────────────────────────────────────────────────────────────────────
class Squad {
  final String id;
  final String name;
  final String tagline;
  final String badge;
  final SquadType type;
  final bool examPrepActive;
  final String? examPrepSubject;
  final DateTime? examPrepDate;
  final String createdBy;
  final DateTime createdAt;
  final int maxMembers;
  final int memberCount;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  Squad({
    required this.id,
    required this.name,
    required this.tagline,
    required this.badge,
    required this.type,
    this.examPrepActive = false,
    this.examPrepSubject,
    this.examPrepDate,
    required this.createdBy,
    required this.createdAt,
    this.maxMembers = 15,
    this.memberCount = 0,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory Squad.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Squad(
      id: doc.id,
      name: d['name'] ?? '',
      tagline: d['tagline'] ?? '',
      badge: d['badge'] ?? '⚡',
      type: _parseType(d['type'] ?? 'open'),
      examPrepActive: d['examPrepActive'] ?? false,
      examPrepSubject: d['examPrepSubject'],
      examPrepDate: (d['examPrepDate'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxMembers: (d['maxMembers'] as num?)?.toInt() ?? 15,
      memberCount: (d['memberCount'] as num?)?.toInt() ?? 0,
      lastMessage: d['lastMessage'],
      lastMessageTime: (d['lastMessageTime'] as Timestamp?)?.toDate(),
    );
  }

  static SquadType _parseType(String t) {
    switch (t) {
      case 'invite_only':
      case 'inviteOnly': return SquadType.inviteOnly;
      case 'closed':     return SquadType.closed;
      default:           return SquadType.open;
    }
  }
}
