import 'dart:math';

class AttendanceRecord {
  final String id;
  final String subjectId;
  final String status; // "present", "absent", "cancelled"
  final DateTime markedAt;
  final bool synced;

  AttendanceRecord({
    required this.id,
    required this.subjectId,
    required this.status,
    required this.markedAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'status': status,
      'marked_at': markedAt.toIso8601String(),
      'synced': synced,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      subjectId: map['subject_id'] ?? '',
      status: map['status'] ?? 'present',
      markedAt: DateTime.tryParse(map['marked_at'] ?? '') ?? DateTime.now(),
      synced: map['synced'] ?? false,
    );
  }
}

class AttendanceStats {
  final String subjectId;
  final String subjectName;
  final int totalPlanned;
  final double compulsoryPct;

  final int attended;
  final int absent;
  final int cancelled;

  AttendanceStats({
    required this.subjectId,
    required this.subjectName,
    required this.totalPlanned,
    this.compulsoryPct = 75.0,
    this.attended = 0,
    this.absent = 0,
    this.cancelled = 0,
  });

  int get conducted => attended + absent;
  int get bunked => conducted - attended;
  int get remaining => totalPlanned - conducted;

  double get currentPercentage => conducted > 0 ? (attended / conducted) * 100.0 : 0.0;

  int get totalBunkBudget => (totalPlanned * (1 - compulsoryPct / 100)).floor();
  int get canBunk => max(0, totalBunkBudget - bunked);
  int get classesStillNeeded => max(0, (totalPlanned * compulsoryPct / 100).ceil() - attended);

  String get riskStatus {
    if (currentPercentage >= compulsoryPct + 5) return 'safe';
    if (currentPercentage >= compulsoryPct) return 'warning';
    return 'danger';
  }

  AttendanceStats copyWith({
    String? subjectId,
    String? subjectName,
    int? totalPlanned,
    double? compulsoryPct,
    int? attended,
    int? absent,
    int? cancelled,
  }) {
    return AttendanceStats(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      totalPlanned: totalPlanned ?? this.totalPlanned,
      compulsoryPct: compulsoryPct ?? this.compulsoryPct,
      attended: attended ?? this.attended,
      absent: absent ?? this.absent,
      cancelled: cancelled ?? this.cancelled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject_id': subjectId,
      'subject_name': subjectName,
      'total_planned': totalPlanned,
      'compulsory_pct': compulsoryPct,
      'attended': attended,
      'absent': absent,
      'cancelled': cancelled,
    };
  }

  factory AttendanceStats.fromMap(Map<String, dynamic> map) {
    return AttendanceStats(
      subjectId: map['subject_id'] ?? '',
      subjectName: map['subject_name'] ?? '',
      totalPlanned: map['total_planned'] ?? 40,
      compulsoryPct: (map['compulsory_pct'] as num?)?.toDouble() ?? 75.0,
      attended: map['attended'] ?? 0,
      absent: map['absent'] ?? 0,
      cancelled: map['cancelled'] ?? 0,
    );
  }
}

