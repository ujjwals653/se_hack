import 'package:equatable/equatable.dart';

class BunkPlan extends Equatable {
  final List<BunkRecommendation> recommendations;
  final Map<String, SubjectBunkStatus> subjectStatus;

  const BunkPlan({
    required this.recommendations,
    required this.subjectStatus,
  });

  factory BunkPlan.fromJson(Map<String, dynamic> json) {
    return BunkPlan(
      recommendations: (json['recommendations'] as List?)
              ?.map((e) =>
                  BunkRecommendation.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      subjectStatus: (json['subjectStatus'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              SubjectBunkStatus.fromJson(Map<String, dynamic>.from(value)),
            ),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
      'subjectStatus': subjectStatus.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  @override
  List<Object?> get props => [recommendations, subjectStatus];
}

class BunkRecommendation extends Equatable {
  final DateTime date;
  final String dayOfWeek;
  final String reason;
  final List<String> affectedSubjects;

  const BunkRecommendation({
    required this.date,
    required this.dayOfWeek,
    required this.reason,
    required this.affectedSubjects,
  });

  factory BunkRecommendation.fromJson(Map<String, dynamic> json) {
    return BunkRecommendation(
      date: DateTime.parse(json['date']),
      dayOfWeek: json['dayOfWeek'],
      reason: json['reason'],
      affectedSubjects: List<String>.from(json['affectedSubjects'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'dayOfWeek': dayOfWeek,
        'reason': reason,
        'affectedSubjects': affectedSubjects,
      };

  @override
  List<Object?> get props => [date, dayOfWeek, reason, affectedSubjects];
}

class SubjectBunkStatus extends Equatable {
  final int totalClassesInSemester;
  final int maxAllowedBunks;
  final int usedBunks;

  int get remainingBunks => maxAllowedBunks - usedBunks;

  const SubjectBunkStatus({
    required this.totalClassesInSemester,
    required this.maxAllowedBunks,
    required this.usedBunks,
  });

  factory SubjectBunkStatus.fromJson(Map<String, dynamic> json) {
    return SubjectBunkStatus(
      totalClassesInSemester: json['totalClassesInSemester'] ?? 0,
      maxAllowedBunks: json['maxAllowedBunks'] ?? 0,
      usedBunks: json['usedBunks'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalClassesInSemester': totalClassesInSemester,
        'maxAllowedBunks': maxAllowedBunks,
        'usedBunks': usedBunks,
      };

  @override
  List<Object?> get props => [totalClassesInSemester, maxAllowedBunks, usedBunks];
}
