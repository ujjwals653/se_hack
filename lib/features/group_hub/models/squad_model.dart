import 'package:cloud_firestore/cloud_firestore.dart';

enum SquadType { open, inviteOnly, closed }

enum SquadRole { leader, coLeader, elder, member }

extension SquadRoleX on SquadRole {
  String get label {
    switch (this) {
      case SquadRole.leader:    return 'Leader';
      case SquadRole.coLeader:  return 'Co-Leader';
      case SquadRole.elder:     return 'Elder';
      case SquadRole.member:    return 'Member';
    }
  }

  String get badge {
    switch (this) {
      case SquadRole.leader:    return '👑';
      case SquadRole.coLeader:  return '⚔️';
      case SquadRole.elder:     return '🛡️';
      case SquadRole.member:    return '🎓';
    }
  }

  bool get canKickMembers       => this == SquadRole.leader || this == SquadRole.coLeader;
  bool get canAcceptRequests    => index <= SquadRole.elder.index;
  bool get canPinMessages       => index <= SquadRole.elder.index;
  bool get canEditSquadProfile  => this == SquadRole.leader;
  bool get canActivateExamPrep  => index <= SquadRole.coLeader.index;
  bool get canPromote           => this == SquadRole.leader;
  bool get canDemote            => this == SquadRole.leader;
  bool get canDisband           => this == SquadRole.leader;
}

// ─── XP Engine ────────────────────────────────────────────────────────────────
class XPEngine {
  static const List<int> thresholds = [0, 200, 500, 1000, 1800, 2800, 4000, 5500, 7500, 10000];
  static const List<String> titles = [
    'Freshman', 'Sophomore', 'Junior', 'Senior',
    'Lab Rat', 'All-Nighter', 'Deadline Dodger',
    'Citation Needed', 'GPA Demon', 'Thesis God',
  ];

  static int levelFromXP(int xp) {
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (xp >= thresholds[i]) return i + 1;
    }
    return 1;
  }

  static String titleFromXP(int xp) => titles[levelFromXP(xp) - 1];

  static double progressToNext(int xp) {
    final level = levelFromXP(xp);
    if (level >= 10) return 1.0;
    final current = thresholds[level - 1];
    final next = thresholds[level];
    return (xp - current) / (next - current);
  }

  static int xpToNextLevel(int xp) {
    final level = levelFromXP(xp);
    if (level >= 10) return 0;
    return thresholds[level] - xp;
  }
}

// ─── Squad Member ─────────────────────────────────────────────────────────────
class SquadMember {
  final String uid;
  final SquadRole role;
  final DateTime joinedAt;
  final int weeklyFocusMinutes;
  final int totalTrophies;
  final int xp;
  final int level;
  final int streakDays;
  String? displayName;
  String? photoUrl;

  SquadMember({
    required this.uid,
    required this.role,
    required this.joinedAt,
    this.weeklyFocusMinutes = 0,
    this.totalTrophies = 0,
    this.xp = 0,
    this.level = 1,
    this.streakDays = 0,
    this.displayName,
    this.photoUrl,
  });

  factory SquadMember.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SquadMember(
      uid: doc.id,
      role: _parseRole(d['role'] ?? 'member'),
      joinedAt: (d['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weeklyFocusMinutes: (d['weeklyFocusMinutes'] as num?)?.toInt() ?? 0,
      totalTrophies: (d['totalTrophies'] as num?)?.toInt() ?? 0,
      xp: (d['xp'] as num?)?.toInt() ?? 0,
      level: (d['level'] as num?)?.toInt() ?? 1,
      streakDays: (d['streakDays'] as num?)?.toInt() ?? 0,
      displayName: d['displayName'],
      photoUrl: d['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'role': _roleToString(role),
        'joinedAt': Timestamp.fromDate(joinedAt),
        'weeklyFocusMinutes': weeklyFocusMinutes,
        'totalTrophies': totalTrophies,
        'xp': xp,
        'level': level,
        'streakDays': streakDays,
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
      case SquadRole.leader:    return 'leader';
      case SquadRole.coLeader:  return 'co_leader';
      case SquadRole.elder:     return 'elder';
      case SquadRole.member:    return 'member';
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
  final int trophies;
  final int weeklyPoints;
  final int healthScore;
  final bool examPrepActive;
  final String? examPrepSubject;
  final DateTime? examPrepDate;
  final String createdBy;
  final DateTime createdAt;
  final int maxMembers;
  final int memberCount;

  Squad({
    required this.id,
    required this.name,
    required this.tagline,
    required this.badge,
    required this.type,
    required this.trophies,
    required this.weeklyPoints,
    this.healthScore = 100,
    this.examPrepActive = false,
    this.examPrepSubject,
    this.examPrepDate,
    required this.createdBy,
    required this.createdAt,
    this.maxMembers = 15,
    this.memberCount = 0,
  });

  factory Squad.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Squad(
      id: doc.id,
      name: d['name'] ?? '',
      tagline: d['tagline'] ?? '',
      badge: d['badge'] ?? '⚡',
      type: _parseType(d['type'] ?? 'open'),
      trophies: (d['trophies'] as num?)?.toInt() ?? 0,
      weeklyPoints: (d['weeklyPoints'] as num?)?.toInt() ?? 0,
      healthScore: (d['healthScore'] as num?)?.toInt() ?? 100,
      examPrepActive: d['examPrepActive'] ?? false,
      examPrepSubject: d['examPrepSubject'],
      examPrepDate: (d['examPrepDate'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxMembers: (d['maxMembers'] as num?)?.toInt() ?? 15,
      memberCount: (d['memberCount'] as num?)?.toInt() ?? 0,
    );
  }

  String get league {
    if (trophies >= 8000) return 'Elite Scholars 👑';
    if (trophies >= 4000) return 'Deep Work Guild ⚡';
    if (trophies >= 1500) return 'Focus Legion 🔥';
    if (trophies >= 500)  return 'Study Force 📚';
    return 'Rookie Squad 🥉';
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
