import 'package:se_hack/features/attendance/data/models/attendance_stats.dart';
import 'package:se_hack/features/timetable/data/models/academic_calendar.dart';
import 'package:se_hack/features/timetable/data/models/bunk_plan.dart';
import 'package:se_hack/features/timetable/data/models/timetable.dart';

class BunkRecommendationEngine {
  /// Generate a BunkPlan by analyzing the semester dates, holidays, and exams
  /// against the user's weekly timetable.
  BunkPlan generatePlan(Timetable timetable, AcademicCalendar calendar, {Map<String, AttendanceStats>? liveStats}) {
    // 1. Map timetable entries to working days (Mon-Fri)
    final workingDayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final subjectsPerDay = <int, List<String>>{}; // 1=Mon, 2=Tue... 5=Fri
    final allSubjectsSet = <String>{};

    for (int i = 0; i < workingDayKeys.length; i++) {
      final dayKey = workingDayKeys[i];
      final entries = timetable.days[dayKey] ?? [];
      final subjects = entries
          .where((e) => !e.isFree && e.subject.isNotEmpty)
          .map((e) => e.subject)
          .toList();

      subjectsPerDay[i + 1] = subjects;
      allSubjectsSet.addAll(subjects);
    }

    // 2. Count total classes per subject across the entire semester
    final totalClassesPerSubject = {for (var s in allSubjectsSet) s: 0};
    
    // We will simulate each day from startDate to endDate
    DateTime current = calendar.startDate;
    final holidayDates = _getHolidayDates(calendar.holidays);
    final examDates = _getExamDates(calendar.exams);
    final workingDates = <DateTime>[];

    while (!current.isAfter(calendar.endDate)) {
      final isWeekend = current.weekday == DateTime.saturday || current.weekday == DateTime.sunday;
      final isHoliday = holidayDates.contains(_stripTime(current));
      final isExam = examDates.contains(_stripTime(current));

      if (!isWeekend && !isHoliday && !isExam) {
        workingDates.add(current);
        // Add counts for subjects that happen on this weekday
        final subjectsThatDay = subjectsPerDay[current.weekday] ?? [];
        for (final s in subjectsThatDay) {
          totalClassesPerSubject[s] = (totalClassesPerSubject[s] ?? 0) + 1;
        }
      }
      current = current.add(const Duration(days: 1));
    }

    // 3. Initialize Subject Status Map using dynamic compulsory targets
    final subjectStatusMap = <String, SubjectBunkStatus>{};
    for (final s in totalClassesPerSubject.keys) {
      final total = totalClassesPerSubject[s] ?? 0;
      
      int realAbsent = 0;
      double userTarget = 75.0; // default
      
      if (liveStats != null) {
         for (var stat in liveStats.values) {
              if (stat.subjectName == s) {
                  realAbsent = stat.absent;
                  userTarget = stat.compulsoryPct;
              }
         }
      }
      
      // Target floor constraint exactly matching v2.0
      final maxBunks = (total * (1.0 - (userTarget / 100.0))).floor();
      
      subjectStatusMap[s] = SubjectBunkStatus(
        totalClassesInSemester: total,
        maxAllowedBunks: maxBunks,
        usedBunks: realAbsent,
      );
    }

    // Helper: simulate using a bunk for a given date
    bool canBunkDate(DateTime date, Map<String, SubjectBunkStatus> statusMap) {
      final subjects = subjectsPerDay[date.weekday] ?? [];
      if (subjects.isEmpty) return false;
      
      // Check if we have enough allowance for ALL subjects on this day
      for (final s in subjects) {
        if (statusMap[s]!.remainingBunks <= 0) return false;
      }
      return true;
    }

    void useBunkForDate(DateTime date, Map<String, SubjectBunkStatus> statusMap) {
      final subjects = subjectsPerDay[date.weekday] ?? [];
      for (final s in subjects) {
        final currentStatus = statusMap[s]!;
        statusMap[s] = SubjectBunkStatus(
          totalClassesInSemester: currentStatus.totalClassesInSemester,
          maxAllowedBunks: currentStatus.maxAllowedBunks,
          usedBunks: currentStatus.usedBunks + 1,
        );
      }
    }

    final recommendations = <BunkRecommendation>[];
    final today = _stripTime(DateTime.now());

    // 4. Priority 1: Pre-Exam Prep (5 days before)
    for (final exam in calendar.exams) {
      final prepStart = exam.startDate.subtract(const Duration(days: 5));
      DateTime pDate = prepStart;
      while (pDate.isBefore(exam.startDate)) {
        if (pDate.isBefore(today)) {
          pDate = pDate.add(const Duration(days: 1));
          continue;
        }
        if (workingDates.contains(_stripTime(pDate))) {
          if (canBunkDate(pDate, subjectStatusMap)) {
            useBunkForDate(pDate, subjectStatusMap);
            recommendations.add(BunkRecommendation(
              date: pDate,
              dayOfWeek: workingDayKeys[pDate.weekday - 1],
              reason: 'Exam Prep: ${exam.name}',
              affectedSubjects: subjectsPerDay[pDate.weekday] ?? [],
            ));
          }
        }
        pDate = pDate.add(const Duration(days: 1));
      }
    }

    // 5. Priority 2: Long Weekends (Sandwich days)
    // Check every working date.
    for (final wDate in workingDates) {
      if (wDate.isBefore(today)) continue;
      
      // Is it a sandwich? 
      // Example 1: Thursday is a holiday (or Thursday is exam), Friday is wDate, Saturday is weekend.
      // Example 2: Monday is wDate, Tuesday is holiday.
      bool isSandwich = false;
      String reason = '';

      if (wDate.weekday == DateTime.friday) {
        // Check if Thursday is a holiday
        final thursday = _stripTime(wDate.subtract(const Duration(days: 1)));
        if (holidayDates.contains(thursday)) {
          isSandwich = true;
          reason = 'Long Weekend (Post-Holiday)';
        }
      } else if (wDate.weekday == DateTime.monday) {
        // Check if Tuesday is a holiday
        final tuesday = _stripTime(wDate.add(const Duration(days: 1)));
        if (holidayDates.contains(tuesday)) {
          isSandwich = true;
          reason = 'Long Weekend (Pre-Holiday)';
        }
      }

      if (isSandwich && canBunkDate(wDate, subjectStatusMap)) {
        // Make sure we didn't already recommend it
        if (!recommendations.any((r) => _stripTime(r.date) == _stripTime(wDate))) {
          useBunkForDate(wDate, subjectStatusMap);
          recommendations.add(BunkRecommendation(
            date: wDate,
            dayOfWeek: workingDayKeys[wDate.weekday - 1],
            reason: reason,
            affectedSubjects: subjectsPerDay[wDate.weekday] ?? [],
          ));
        }
      }
    }

    // Sort by date
    recommendations.sort((a, b) => a.date.compareTo(b.date));

    return BunkPlan(
      recommendations: recommendations,
      subjectStatus: subjectStatusMap,
    );
  }

  Set<DateTime> _getHolidayDates(List<Holiday> holidays) {
    return holidays.map((h) => _stripTime(h.date)).toSet();
  }

  Set<DateTime> _getExamDates(List<ExamPeriod> exams) {
    final dates = <DateTime>{};
    for (final e in exams) {
      DateTime current = _stripTime(e.startDate);
      final end = _stripTime(e.endDate);
      while (!current.isAfter(end)) {
        dates.add(current);
        current = current.add(const Duration(days: 1));
      }
    }
    return dates;
  }

  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);
}
