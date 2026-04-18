import 'package:equatable/equatable.dart';

class AcademicCalendar extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final List<Holiday> holidays;
  final List<ExamPeriod> exams;

  const AcademicCalendar({
    required this.startDate,
    required this.endDate,
    this.holidays = const [],
    this.exams = const [],
  });

  factory AcademicCalendar.fromJson(Map<String, dynamic> json) {
    return AcademicCalendar(
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      holidays: (json['holidays'] as List?)
              ?.map((e) => Holiday.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      exams: (json['exams'] as List?)
              ?.map((e) => ExamPeriod.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'holidays': holidays.map((e) => e.toJson()).toList(),
      'exams': exams.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [startDate, endDate, holidays, exams];
}

class Holiday extends Equatable {
  final String name;
  final DateTime date;

  const Holiday({required this.name, required this.date});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      name: json['name'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date.toIso8601String(),
      };

  @override
  List<Object?> get props => [name, date];
}

class ExamPeriod extends Equatable {
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  const ExamPeriod({
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory ExamPeriod.fromJson(Map<String, dynamic> json) {
    return ExamPeriod(
      name: json['name'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

  @override
  List<Object?> get props => [name, startDate, endDate];
}
