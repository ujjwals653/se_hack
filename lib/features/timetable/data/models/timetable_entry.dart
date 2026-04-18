import 'package:equatable/equatable.dart';

class TimetableEntry extends Equatable {
  final int period;
  final String subject;
  final String startTime;
  final String endTime;
  final String section;
  final bool isFree;
  final bool isLab; // true = compulsory lab rotation slot (not counted as a lecture)

  const TimetableEntry({
    required this.period,
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.section = '',
    this.isFree = false,
    this.isLab = false,
  });

  TimetableEntry copyWith({
    int? period,
    String? subject,
    String? startTime,
    String? endTime,
    String? section,
    bool? isFree,
    bool? isLab,
  }) {
    return TimetableEntry(
      period: period ?? this.period,
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      section: section ?? this.section,
      isFree: isFree ?? this.isFree,
      isLab: isLab ?? this.isLab,
    );
  }

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      period: (map['period'] as num?)?.toInt() ?? 0,
      subject: map['subject'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      section: map['section'] as String? ?? '',
      isFree: map['isFree'] as bool? ?? false,
      isLab: map['isLab'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'period': period,
      'subject': subject,
      'startTime': startTime,
      'endTime': endTime,
      'section': section,
      'isFree': isFree,
      'isLab': isLab,
    };
  }

  @override
  List<Object?> get props => [period, subject, startTime, endTime, section, isFree, isLab];
}
