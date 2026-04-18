import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:se_hack/features/timetable/data/models/timetable_entry.dart';

class Timetable extends Equatable {
  final bool hasTimetable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, List<TimetableEntry>> days;

  static const List<String> dayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  const Timetable({
    this.hasTimetable = true,
    required this.createdAt,
    required this.updatedAt,
    required this.days,
  });

  Timetable copyWith({
    bool? hasTimetable,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, List<TimetableEntry>>? days,
  }) {
    return Timetable(
      hasTimetable: hasTimetable ?? this.hasTimetable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      days: days ?? this.days,
    );
  }

  /// Creates an empty timetable scaffold with no entries for each day.
  factory Timetable.empty() {
    final now = DateTime.now();
    return Timetable(
      hasTimetable: false,
      createdAt: now,
      updatedAt: now,
      days: {for (final d in dayKeys) d: <TimetableEntry>[]},
    );
  }

  factory Timetable.fromFirestore(Map<String, dynamic> data) {
    final daysRaw = data['days'] as Map<String, dynamic>? ?? {};
    final days = <String, List<TimetableEntry>>{};

    for (final dayKey in dayKeys) {
      final entries = daysRaw[dayKey] as List<dynamic>? ?? [];
      days[dayKey] = entries
          .map((e) => TimetableEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return Timetable(
      hasTimetable: data['hasTimetable'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      days: days,
    );
  }

  Map<String, dynamic> toFirestore() {
    final daysMap = <String, dynamic>{};
    for (final entry in days.entries) {
      daysMap[entry.key] = entry.value.map((e) => e.toMap()).toList();
    }

    return {
      'hasTimetable': hasTimetable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'days': daysMap,
    };
  }

  @override
  List<Object?> get props => [hasTimetable, createdAt, updatedAt, days];
}
