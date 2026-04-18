import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Budget Model ─────────────────────────────────────────────────────────────
class Budget {
  final String id;
  final String category;
  final double monthlyLimit;
  final String monthKey; // e.g. "2026-04"

  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.monthKey,
  });

  static String currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'monthlyLimit': monthlyLimit,
        'monthKey': monthKey,
      };

  factory Budget.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      category: d['category'] ?? 'Other',
      monthlyLimit: (d['monthlyLimit'] as num).toDouble(),
      monthKey: d['monthKey'] ?? currentMonthKey(),
    );
  }

  Budget copyWith({
    String? id,
    String? category,
    double? monthlyLimit,
    String? monthKey,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      monthKey: monthKey ?? this.monthKey,
    );
  }
}

// ─── Budget Status (computed) ─────────────────────────────────────────────────
class BudgetStatus {
  final String category;
  final double limit;
  final double spent;

  const BudgetStatus({
    required this.category,
    required this.limit,
    required this.spent,
  });

  double get remaining => limit - spent;
  double get percentage => limit <= 0 ? 0 : (spent / limit).clamp(0, 1);
  bool get isOverBudget => spent > limit;
  bool get isNearLimit => percentage >= 0.9 && !isOverBudget;
}
