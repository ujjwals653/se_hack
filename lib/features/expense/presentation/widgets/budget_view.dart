import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/expense_cubit.dart';
import '../../data/budget_model.dart';
import '../../data/expense_model.dart';

class BudgetView extends StatelessWidget {
  const BudgetView({super.key});

  static const Color _amber = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        if (state is! ExpenseLoaded) {
          return const Center(child: CircularProgressIndicator(color: _amber));
        }

        final statuses = state.budgetStatuses;
        final budgets = state.budgets;

        // Total budget health
        final totalLimit =
            budgets.fold<double>(0, (s, b) => s + b.monthlyLimit);
        final totalSpent = statuses.values
            .fold<double>(0, (s, b) => s + b.spent);
        final overallPct =
            totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Overall health card
            if (totalLimit > 0) ...[
              _OverallHealthCard(
                totalSpent: totalSpent,
                totalLimit: totalLimit,
                percentage: overallPct,
              ),
              const SizedBox(height: 16),
            ],

            // Per-category budgets
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Category Budgets',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            ...ExpenseCategory.values.map((cat) {
              final status = statuses[cat.label];
              final budget =
                  budgets.where((b) => b.category == cat.label).firstOrNull;

              return _BudgetCategoryCard(
                category: cat,
                status: status,
                budget: budget,
                onSetBudget: (limit) {
                  context.read<ExpenseCubit>().setBudget(cat.label, limit);
                },
                onDeleteBudget: budget != null
                    ? () =>
                        context.read<ExpenseCubit>().deleteBudget(budget.id)
                    : null,
              );
            }),
          ],
        );
      },
    );
  }
}

class _OverallHealthCard extends StatelessWidget {
  final double totalSpent;
  final double totalLimit;
  final double percentage;

  const _OverallHealthCard({
    required this.totalSpent,
    required this.totalLimit,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = totalSpent > totalLimit;
    final remaining = totalLimit - totalSpent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isOver
            ? Colors.red.shade50
            : const Color(0xFFF0FFF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOver ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isOver ? '⚠️' : '✅',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Budget Health',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isOver ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
              const Spacer(),
              Text(
                isOver
                    ? '₹${(-remaining).toStringAsFixed(0)} over'
                    : '₹${remaining.toStringAsFixed(0)} left',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isOver ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 1.0
                    ? Colors.red
                    : percentage >= 0.9
                        ? Colors.orange
                        : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalSpent.toStringAsFixed(0)} of ₹${totalLimit.toStringAsFixed(0)} spent (${(percentage * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  final ExpenseCategory category;
  final BudgetStatus? status;
  final Budget? budget;
  final ValueChanged<double> onSetBudget;
  final VoidCallback? onDeleteBudget;

  const _BudgetCategoryCard({
    required this.category,
    required this.status,
    required this.budget,
    required this.onSetBudget,
    this.onDeleteBudget,
  });

  @override
  Widget build(BuildContext context) {
    final hasLimit = status != null;
    final pct = status?.percentage ?? 0.0;
    final barColor = pct >= 1.0
        ? Colors.red
        : pct >= 0.9
            ? Colors.orange
            : Colors.green.shade500;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(category.emoji,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      hasLimit
                          ? '₹${status!.spent.toStringAsFixed(0)} / ₹${status!.limit.toStringAsFixed(0)}'
                          : 'No budget set',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              // Set / Edit button
              GestureDetector(
                onTap: () => _showSetBudgetSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasLimit
                        ? Colors.grey.shade100
                        : const Color(0xFFF5A623).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasLimit
                          ? Colors.grey.shade300
                          : const Color(0xFFF5A623),
                    ),
                  ),
                  child: Text(
                    hasLimit ? 'Edit' : 'Set',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasLimit
                          ? Colors.black54
                          : const Color(0xFFF5A623),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasLimit) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (_, val, __) => LinearProgressIndicator(
                  value: val,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
            if (status!.isNearLimit || status!.isOverBudget)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  status!.isOverBudget
                      ? '⚠️ Over budget by ₹${(-status!.remaining).toStringAsFixed(0)}'
                      : '🔔 Almost at limit! ₹${status!.remaining.toStringAsFixed(0)} left',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        status!.isOverBudget ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showSetBudgetSheet(BuildContext context) {
    final controller = TextEditingController(
      text: status?.limit != null
          ? status!.limit.toStringAsFixed(0)
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final bottomPad = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPad + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set ${category.emoji} ${category.label} Budget',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Monthly limit for this category',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF5A623),
                  ),
                  hintText: '5000',
                  filled: true,
                  fillColor: const Color(0xFFFFF8EE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onDeleteBudget != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          onDeleteBudget!();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Remove'),
                      ),
                    ),
                  if (onDeleteBudget != null) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final val = double.tryParse(controller.text);
                        if (val != null && val > 0) {
                          onSetBudget(val);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A623),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Save Budget',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
