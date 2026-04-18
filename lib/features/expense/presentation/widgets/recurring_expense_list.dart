import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/expense_cubit.dart';
import '../../data/recurring_expense_model.dart';
import '../../data/expense_model.dart';

class RecurringExpenseList extends StatelessWidget {
  const RecurringExpenseList({super.key});

  static const Color _teal = Color(0xFF4ECDC4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🔁 Recurring Expenses',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state is! ExpenseLoaded) {
            return const Center(
                child: CircularProgressIndicator(color: _teal));
          }

          final list = state.recurringExpenses;

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔁', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text(
                    'No recurring expenses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Set up recurring expenses from the\nLog Expense sheet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i];
              return _RecurringTile(recurring: r);
            },
          );
        },
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringExpense recurring;
  const _RecurringTile({required this.recurring});

  @override
  Widget build(BuildContext context) {
    final cat = ExpenseCategory.fromLabel(recurring.category);
    final cubit = context.read<ExpenseCubit>();
    final nextDue = _nextDueLabel();

    return Dismissible(
      key: Key(recurring.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        cubit.deleteRecurring(recurring.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recurring expense deleted')),
        );
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: recurring.isActive
                    ? cat.color.withOpacity(0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  cat.emoji,
                  style: TextStyle(
                    fontSize: 22,
                    color: recurring.isActive ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: recurring.isActive
                          ? Colors.black87
                          : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _badge(recurring.frequency.label,
                          const Color(0xFF4ECDC4)),
                      const SizedBox(width: 6),
                      if (recurring.note.isNotEmpty)
                        Flexible(
                          child: Text(
                            recurring.note,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nextDue,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Amount + toggle
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${recurring.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: recurring.isActive
                        ? Colors.black87
                        : Colors.black38,
                  ),
                ),
                const SizedBox(height: 4),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: recurring.isActive,
                    onChanged: (v) =>
                        cubit.toggleRecurring(recurring.id, v),
                    activeColor: const Color(0xFF4ECDC4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _nextDueLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = recurring.lastGeneratedDate;
    DateTime next;
    switch (recurring.frequency) {
      case RecurringFrequency.daily:
        next = last.add(const Duration(days: 1));
        break;
      case RecurringFrequency.weekly:
        next = last.add(const Duration(days: 7));
        break;
      case RecurringFrequency.monthly:
        next = DateTime(last.year, last.month + 1, last.day);
        break;
    }
    if (!recurring.isActive) return 'Paused';
    if (!next.isAfter(today)) return 'Due today';
    final diff = next.difference(today).inDays;
    return 'Next in $diff day${diff == 1 ? '' : 's'}';
  }
}
