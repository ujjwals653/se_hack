part of 'expense_cubit.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();
  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

class ExpenseLoaded extends ExpenseState {
  final List<Expense> expenses;
  final List<RecurringExpense> recurringExpenses;
  final List<Budget> budgets;
  final Map<String, BudgetStatus> budgetStatuses;
  final Map<String, double> categoryBreakdown;

  const ExpenseLoaded({
    required this.expenses,
    required this.recurringExpenses,
    required this.budgets,
    required this.budgetStatuses,
    required this.categoryBreakdown,
  });

  /// Groups expenses by formatted date string.
  Map<String, List<Expense>> get groupedByDay {
    final map = <String, List<Expense>>{};
    for (final e in expenses) {
      final key =
          '${e.createdAt.day} ${_monthName(e.createdAt.month)} ${e.createdAt.year}';
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  double get weekTotal => expenses.fold(0, (s, e) => s + e.amount);

  double get dailyAverage {
    if (expenses.isEmpty) return 0;
    final days = expenses.map((e) => e.createdAt.day).toSet().length;
    return weekTotal / days;
  }

  String get topCategory {
    if (categoryBreakdown.isEmpty) return '—';
    return categoryBreakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  @override
  List<Object?> get props => [
        expenses,
        recurringExpenses,
        budgets,
        budgetStatuses,
        categoryBreakdown,
      ];
}

class ExpenseError extends ExpenseState {
  final String message;
  const ExpenseError(this.message);
  @override
  List<Object?> get props => [message];
}
