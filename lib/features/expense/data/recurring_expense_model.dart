import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Frequency Enum ───────────────────────────────────────────────────────────
enum RecurringFrequency {
  daily('Daily', 'Every day'),
  weekly('Weekly', 'Every week'),
  monthly('Monthly', 'Every month');

  const RecurringFrequency(this.label, this.description);
  final String label;
  final String description;

  static RecurringFrequency fromLabel(String label) {
    return RecurringFrequency.values.firstWhere(
      (e) => e.label == label,
      orElse: () => RecurringFrequency.monthly,
    );
  }
}

// ─── Recurring Expense Model ─────────────────────────────────────────────────
class RecurringExpense {
  final String id;
  final double amount;
  final String category;
  final String note;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime lastGeneratedDate;
  final bool isActive;

  const RecurringExpense({
    required this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.frequency,
    required this.startDate,
    required this.lastGeneratedDate,
    this.isActive = true,
  });

  /// Returns all dates between [lastGeneratedDate] and today (exclusive of
  /// lastGeneratedDate, inclusive of dates that match the frequency).
  List<DateTime> dueDates() {
    final List<DateTime> dates = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime cursor = _nextDate(lastGeneratedDate);

    while (!cursor.isAfter(today)) {
      dates.add(cursor);
      cursor = _nextDate(cursor);
    }
    return dates;
  }

  DateTime _nextDate(DateTime from) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'category': category,
        'note': note,
        'frequency': frequency.label,
        'startDate': Timestamp.fromDate(startDate),
        'lastGeneratedDate': Timestamp.fromDate(lastGeneratedDate),
        'isActive': isActive,
      };

  factory RecurringExpense.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RecurringExpense(
      id: doc.id,
      amount: (d['amount'] as num).toDouble(),
      category: d['category'] ?? 'Other',
      note: d['note'] ?? '',
      frequency: RecurringFrequency.fromLabel(d['frequency'] ?? 'Monthly'),
      startDate: (d['startDate'] as Timestamp).toDate(),
      lastGeneratedDate: (d['lastGeneratedDate'] as Timestamp).toDate(),
      isActive: d['isActive'] ?? true,
    );
  }

  RecurringExpense copyWith({
    String? id,
    double? amount,
    String? category,
    String? note,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? lastGeneratedDate,
    bool? isActive,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
