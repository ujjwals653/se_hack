import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─── Category Enum ───────────────────────────────────────────────────────────
enum ExpenseCategory {
  food('Food', '🍜', Color(0xFFFF6B6B)),
  travel('Travel', '🚌', Color(0xFF4ECDC4)),
  books('Books', '📚', Color(0xFF45B7D1)),
  fun('Fun', '🎮', Color(0xFFFFA07A)),
  other('Other', '🧾', Color(0xFF98D8C8));

  const ExpenseCategory(this.label, this.emoji, this.color);
  final String label;
  final String emoji;
  final Color color;

  static ExpenseCategory fromLabel(String label) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.label == label,
      orElse: () => ExpenseCategory.other,
    );
  }
}

// ─── Expense Model ────────────────────────────────────────────────────────────
class Expense {
  final String id;
  final double amount;
  final String category;
  final String note;
  final DateTime createdAt;
  final String weekKey;
  bool isDeleted;
  final bool isRecurring;
  final String? recurringParentId;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.createdAt,
    this.isDeleted = false,
    this.isRecurring = false,
    this.recurringParentId,
  }) : weekKey = _computeWeekKey(createdAt);

  static String computeWeekKey(DateTime date) {
    final weekNumber = _isoWeekNumber(date);
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  // Keep private alias for internal use
  static String _computeWeekKey(DateTime date) => computeWeekKey(date);

  static int _isoWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays;
    return ((dayOfYear + startOfYear.weekday - 1) / 7).ceil();
  }

  ExpenseCategory get categoryEnum => ExpenseCategory.fromLabel(category);

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'category': category,
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
        'weekKey': weekKey,
        'isDeleted': isDeleted,
        'isRecurring': isRecurring,
        'recurringParentId': recurringParentId,
      };

  factory Expense.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final createdAt = (d['createdAt'] as Timestamp).toDate();
    return Expense(
      id: doc.id,
      amount: (d['amount'] as num).toDouble(),
      category: d['category'] ?? 'Other',
      note: d['note'] ?? '',
      createdAt: createdAt,
      isDeleted: d['isDeleted'] ?? false,
      isRecurring: d['isRecurring'] ?? false,
      recurringParentId: d['recurringParentId'],
    );
  }

  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    String? note,
    DateTime? createdAt,
    bool? isDeleted,
    bool? isRecurring,
    String? recurringParentId,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringParentId: recurringParentId ?? this.recurringParentId,
    );
  }
}
