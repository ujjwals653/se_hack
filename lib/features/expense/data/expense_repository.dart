import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'expense_model.dart';
import 'recurring_expense_model.dart';
import 'budget_model.dart';

class ExpenseRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  String get _uid => _auth.currentUser!.uid;

  // ─── Collection refs ──────────────────────────────────────────────────────
  CollectionReference get _itemsCol =>
      _db.collection('expenses').doc(_uid).collection('items');

  CollectionReference get _recurringCol =>
      _db.collection('expenses').doc(_uid).collection('recurring');

  CollectionReference get _budgetsCol =>
      _db.collection('expenses').doc(_uid).collection('budgets');

  // ─── EXPENSES ─────────────────────────────────────────────────────────────

  Future<void> addExpense(Expense expense) async {
    await _itemsCol.doc(expense.id).set(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    await _itemsCol.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _itemsCol.doc(id).update({'isDeleted': true});
  }

  Stream<List<Expense>> watchThisWeek() {
    final weekKey = Expense.computeWeekKey(DateTime.now());
    return _itemsCol
        .where('weekKey', isEqualTo: weekKey)
        .snapshots()
        .map((s) {
      final expenses = s.docs
          .map(Expense.fromDoc)
          .where((e) => !e.isDeleted)
          .toList();
      expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return expenses;
    });
  }

  Stream<List<Expense>> watchAllExpenses() {
    return _itemsCol
        .snapshots()
        .map((s) {
      final expenses = s.docs
          .map(Expense.fromDoc)
          .where((e) => !e.isDeleted)
          .toList();
      expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return expenses;
    });
  }

  /// Stream of expenses within a date range (for pie chart time filters).
  Stream<List<Expense>> watchExpensesByDateRange(
      DateTime start, DateTime end) {
    return _itemsCol
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((s) {
      final expenses = s.docs
          .map(Expense.fromDoc)
          .where((e) => !e.isDeleted)
          .toList();
      expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return expenses;
    });
  }

  // ─── RECURRING EXPENSES ───────────────────────────────────────────────────

  Future<void> addRecurring(RecurringExpense recurring) async {
    await _recurringCol.doc(recurring.id).set(recurring.toMap());
  }

  Future<void> updateRecurring(RecurringExpense recurring) async {
    await _recurringCol.doc(recurring.id).update(recurring.toMap());
  }

  Future<void> deleteRecurring(String id) async {
    await _recurringCol.doc(id).delete();
  }

  Future<void> toggleRecurring(String id, bool isActive) async {
    await _recurringCol.doc(id).update({'isActive': isActive});
  }

  Stream<List<RecurringExpense>> watchRecurring() {
    return _recurringCol
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(RecurringExpense.fromDoc).toList());
  }

  /// Core method: auto-generates expense entries for all due recurring rules.
  /// Returns the number of entries generated.
  Future<int> generateDueExpenses() async {
    final snapshot = await _recurringCol
        .where('isActive', isEqualTo: true)
        .get();

    final List<RecurringExpense> recurringList =
        snapshot.docs.map(RecurringExpense.fromDoc).toList();

    int generated = 0;

    for (final recurring in recurringList) {
      final due = recurring.dueDates();
      if (due.isEmpty) continue;

      // Batch write all due entries
      final batch = _db.batch();
      for (final date in due) {
        final expense = Expense(
          id: _uuid.v4(),
          amount: recurring.amount,
          category: recurring.category,
          note: recurring.note.isEmpty
              ? '🔁 ${recurring.frequency.label}'
              : '${recurring.note} (🔁 ${recurring.frequency.label})',
          createdAt: date,
          isRecurring: true,
          recurringParentId: recurring.id,
        );
        batch.set(_itemsCol.doc(expense.id), expense.toMap());
        generated++;
      }

      // Update lastGeneratedDate to today
      final today = DateTime.now();
      batch.update(_recurringCol.doc(recurring.id), {
        'lastGeneratedDate': Timestamp.fromDate(
          DateTime(today.year, today.month, today.day),
        ),
      });

      await batch.commit();
    }

    return generated;
  }

  // ─── BUDGETS ──────────────────────────────────────────────────────────────

  Future<void> setBudget(Budget budget) async {
    await _budgetsCol.doc(budget.id).set(budget.toMap());
  }

  Future<void> deleteBudget(String id) async {
    await _budgetsCol.doc(id).delete();
  }

  Stream<List<Budget>> watchBudgets() {
    final monthKey = Budget.currentMonthKey();
    return _budgetsCol
        .where('monthKey', isEqualTo: monthKey)
        .snapshots()
        .map((s) => s.docs.map(Budget.fromDoc).toList());
  }

  /// Returns current month's spent amount per category.
  Future<Map<String, double>> getSpentByCategory() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final snapshot = await _itemsCol
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final expenses = snapshot.docs.map(Expense.fromDoc).where((e) => !e.isDeleted).toList();
    final Map<String, double> totals = {};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }
}
