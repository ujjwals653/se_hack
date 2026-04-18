import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../data/expense_model.dart';
import '../data/recurring_expense_model.dart';
import '../data/budget_model.dart';
import '../data/expense_repository.dart';

part 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _repo;
  final _uuid = const Uuid();

  StreamSubscription<List<Expense>>? _expenseSub;
  StreamSubscription<List<RecurringExpense>>? _recurringSub;
  StreamSubscription<List<Budget>>? _budgetSub;

  List<Expense> _expenses = [];
  List<RecurringExpense> _recurringExpenses = [];
  List<Budget> _budgets = [];
  Map<String, double> _spentByCategory = {};

  ExpenseCubit({ExpenseRepository? repo})
      : _repo = repo ?? ExpenseRepository(),
        super(const ExpenseInitial());

  // ─── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    emit(const ExpenseLoading());

    // Auto-generate any due recurring expenses first
    try {
      final count = await _repo.generateDueExpenses();
      if (count > 0) {
        // Will be reflected in stream below
      }
    } catch (_) {}

    // Subscribe to all streams simultaneously
    _expenseSub = _repo.watchThisWeek().listen(
      (expenses) {
        _expenses = expenses;
        _emitLoaded();
      },
      onError: (e) => emit(ExpenseError(e.toString())),
    );

    _recurringSub = _repo.watchRecurring().listen(
      (list) {
        _recurringExpenses = list;
        _emitLoaded();
      },
    );

    _budgetSub = _repo.watchBudgets().listen(
      (budgets) async {
        _budgets = budgets;
        _spentByCategory = await _repo.getSpentByCategory();
        _emitLoaded();
      },
    );
  }

  void loadAll() {
    _expenseSub?.cancel();
    _expenseSub = _repo.watchAllExpenses().listen(
      (expenses) {
        _expenses = expenses;
        _emitLoaded();
      },
    );
  }

  void loadThisWeek() {
    _expenseSub?.cancel();
    _expenseSub = _repo.watchThisWeek().listen(
      (expenses) {
        _expenses = expenses;
        _emitLoaded();
      },
    );
  }

  void loadByDateRange(DateTime start, DateTime end) {
    _expenseSub?.cancel();
    _expenseSub = _repo.watchExpensesByDateRange(start, end).listen(
      (expenses) {
        _expenses = expenses;
        _emitLoaded();
      },
    );
  }

  void _emitLoaded() {
    final spent = <String, double>{};
    for (final e in _expenses) {
      spent[e.category] = (spent[e.category] ?? 0) + e.amount;
    }

    final budgetStatuses = <String, BudgetStatus>{};
    for (final b in _budgets) {
      budgetStatuses[b.category] = BudgetStatus(
        category: b.category,
        limit: b.monthlyLimit,
        spent: _spentByCategory[b.category] ?? 0,
      );
    }

    emit(ExpenseLoaded(
      expenses: _expenses,
      recurringExpenses: _recurringExpenses,
      budgets: _budgets,
      budgetStatuses: budgetStatuses,
      categoryBreakdown: spent,
    ));
  }

  // ─── Computed helpers ─────────────────────────────────────────────────────

  double get weekTotal =>
      _expenses.fold(0, (s, e) => s + e.amount);

  String get topCategory {
    if (_expenses.isEmpty) return '—';
    final tally = <String, double>{};
    for (final e in _expenses) {
      tally[e.category] = (tally[e.category] ?? 0) + e.amount;
    }
    return tally.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  double get dailyAverage {
    if (_expenses.isEmpty) return 0;
    final days = _expenses.map((e) => e.createdAt.day).toSet().length;
    return weekTotal / days;
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> addExpense(Expense expense) async {
    await _repo.addExpense(expense);
    // Refresh budget status after adding
    _spentByCategory = await _repo.getSpentByCategory();
    _emitLoaded();
  }

  Future<void> updateExpense(Expense expense) async {
    await _repo.updateExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    _spentByCategory = await _repo.getSpentByCategory();
    _emitLoaded();
  }

  // ─── Recurring ────────────────────────────────────────────────────────────

  Future<void> addRecurring({
    required double amount,
    required String category,
    required String note,
    required RecurringFrequency frequency,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recurring = RecurringExpense(
      id: _uuid.v4(),
      amount: amount,
      category: category,
      note: note,
      frequency: frequency,
      startDate: today,
      lastGeneratedDate: today.subtract(const Duration(days: 1)),
    );
    await _repo.addRecurring(recurring);
  }

  Future<void> updateRecurring(RecurringExpense recurring) async {
    await _repo.updateRecurring(recurring);
  }

  Future<void> deleteRecurring(String id) async {
    await _repo.deleteRecurring(id);
  }

  Future<void> toggleRecurring(String id, bool isActive) async {
    await _repo.toggleRecurring(id, isActive);
  }

  // ─── Budget ───────────────────────────────────────────────────────────────

  Future<void> setBudget(String category, double limit) async {
    // Check if budget already exists for this category this month
    final existing = _budgets.where((b) => b.category == category).toList();
    final budget = Budget(
      id: existing.isNotEmpty ? existing.first.id : _uuid.v4(),
      category: category,
      monthlyLimit: limit,
      monthKey: Budget.currentMonthKey(),
    );
    await _repo.setBudget(budget);
    _spentByCategory = await _repo.getSpentByCategory();
    _emitLoaded();
  }

  Future<void> deleteBudget(String id) async {
    await _repo.deleteBudget(id);
  }

  @override
  Future<void> close() {
    _expenseSub?.cancel();
    _recurringSub?.cancel();
    _budgetSub?.cancel();
    return super.close();
  }
}
