// lib/features/timetable/data/models/timetable_entry.dart
// Lumina — Hive model for a single timetable slot

import 'package:hive/hive.dart';
part 'timetable_entry.g.dart';

@HiveType(typeId: 0)
class TimetableEntry extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String subjectName;
  @HiveField(2) String subjectCode;
  @HiveField(3) int weekday;        // 1=Mon … 5=Fri
  @HiveField(4) String startTime;  // "HH:mm"
  @HiveField(5) String endTime;
  @HiveField(6) String room;
  @HiveField(7) String professorName;
  @HiveField(8) String batch;
  @HiveField(9) String userId;

  TimetableEntry({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.professorName,
    required this.batch,
    required this.userId,
  });

  // Convert to map for Firebase
  Map<String, dynamic> toMap() => {
    'id': id,
    'subjectName': subjectName,
    'subjectCode': subjectCode,
    'weekday': weekday,
    'startTime': startTime,
    'endTime': endTime,
    'room': room,
    'professorName': professorName,
    'batch': batch,
    'userId': userId,
  };

  // Create from Firebase map
  factory TimetableEntry.fromMap(Map<String, dynamic> map) => TimetableEntry(
    id: map['id'],
    subjectName: map['subjectName'],
    subjectCode: map['subjectCode'],
    weekday: map['weekday'],
    startTime: map['startTime'],
    endTime: map['endTime'],
    room: map['room'],
    professorName: map['professorName'],
    batch: map['batch'],
    userId: map['userId'],
  );
}
