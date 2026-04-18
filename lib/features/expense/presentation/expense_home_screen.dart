import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/expense_cubit.dart';
import '../data/expense_model.dart';
import 'widgets/expense_tile.dart';
import 'widgets/quick_add_sheet.dart';
import 'widgets/budget_view.dart';
import 'widgets/recurring_expense_list.dart';
import 'weekly_wrap_screen.dart';

class ExpenseHomeScreen extends StatefulWidget {
  const ExpenseHomeScreen({super.key});

  @override
  State<ExpenseHomeScreen> createState() => _ExpenseHomeScreenState();
}

class _ExpenseHomeScreenState extends State<ExpenseHomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color _amber = Color(0xFFF5A623);
  static const Color _bg = Color(0xFFF8F9FA);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<ExpenseCubit>().init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showQuickAdd([Expense? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ExpenseCubit>(),
        child: QuickAddSheet(existingExpense: existing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Expenses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          // Recurring manager
          IconButton(
            icon: const Text('🔁', style: TextStyle(fontSize: 20)),
            tooltip: 'Recurring Expenses',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ExpenseCubit>(),
                    child: const RecurringExpenseList(),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _amber,
          unselectedLabelColor: Colors.black38,
          indicatorColor: _amber,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Home'),
            Tab(text: 'Reports'),
            Tab(text: 'Budget'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ── Tab 0: Home feed ────────────────────────────────────────────
          _HomeTab(onEdit: _showQuickAdd),

          // ── Tab 1: Analytics / Pie chart ────────────────────────────────
          const AnalyticsView(),

          // ── Tab 2: Budget ───────────────────────────────────────────────
          const BudgetView(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) => _tabController.index == 0
            ? FloatingActionButton(
                onPressed: _showQuickAdd,
                backgroundColor: _amber,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 28),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

// ─── Home Tab ──────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final ValueChanged<Expense?> onEdit;
  const _HomeTab({required this.onEdit});

  static const Color _amber = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        if (state is ExpenseLoading || state is ExpenseInitial) {
          return const Center(
              child: CircularProgressIndicator(color: _amber));
        }
        if (state is ExpenseError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        if (state is! ExpenseLoaded) return const SizedBox.shrink();

        final grouped = state.groupedByDay;
        final total = state.weekTotal;
        final days = grouped.keys.length;
        final dayAvg = days > 0 ? total / days : 0.0;

        return RefreshIndicator(
          color: _amber,
          onRefresh: () => context.read<ExpenseCubit>().init(),
          child: CustomScrollView(
            slivers: [
              // ── Summary banner ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: _amber,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _amber.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _SummaryCol(
                        label: 'Expenses',
                        value: '₹${total.toStringAsFixed(0)}',
                      ),
                      _divider(),
                      _SummaryCol(
                        label: 'Avg/day',
                        value: '₹${dayAvg.toStringAsFixed(0)}',
                      ),
                      _divider(),
                      _SummaryCol(
                        label: 'Entries',
                        value: '${state.expenses.length}',
                      ),
                    ],
                  ),
                ),
              ),

              // ── Grouped expense list ──────────────────────────────────
              if (grouped.isEmpty)
                const SliverFillRemaining(
                  child: _EmptyState(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, dayIdx) {
                      final dayKey =
                          grouped.keys.elementAt(dayIdx);
                      final items = grouped[dayKey]!;
                      final dayTotal = items.fold<double>(
                          0, (s, e) => s + e.amount);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 16, 16, 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dayKey,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Daily: ₹${dayTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Expense tiles
                          ...items.map(
                            (expense) => ExpenseTile(
                              expense: expense,
                              onDelete: () {
                                context
                                    .read<ExpenseCubit>()
                                    .deleteExpense(expense.id);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Expense deleted'),
                                    behavior:
                                        SnackBarBehavior.floating,
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        // Re-add the expense
                                        context
                                            .read<ExpenseCubit>()
                                            .addExpense(expense.copyWith(
                                                isDeleted: false));
                                      },
                                    ),
                                  ),
                                );
                              },
                              onEdit: () => onEdit(expense),
                            ),
                          ),
                        ],
                      );
                    },
                    childCount: grouped.length,
                  ),
                ),

              const SliverPadding(
                  padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        width: 1,
        height: 40,
        color: Colors.white30,
      );
}

class _SummaryCol extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💸', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          const Text(
            'No expenses this week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to log your first expense',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
