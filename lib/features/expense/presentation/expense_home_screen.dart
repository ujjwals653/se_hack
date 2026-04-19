import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
  static const Color _bg = Color(0xFFF4F5FA);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<ExpenseCubit>().init();
    _tabController.addListener(() => setState(() {}));
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
        backgroundColor: const Color(0xFFF4F5FA),
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Expenses',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat_rounded, color: Color(0xFF7B61FF)),
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
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7B61FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF7B61FF),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
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
          _HomeTab(onEdit: _showQuickAdd),
          const AnalyticsView(),
          const BudgetView(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showQuickAdd,
              backgroundColor: const Color(0xFFFFAB61),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ─── Home Tab ──────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final ValueChanged<Expense?> onEdit;
  const _HomeTab({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        if (state is ExpenseLoading || state is ExpenseInitial) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7B61FF)));
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
          color: const Color(0xFF7B61FF),
          onRefresh: () => context.read<ExpenseCubit>().init(),
          child: CustomScrollView(
            slivers: [
              // ── Summary banner ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFAB61), Color(0xFFFF8C42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFAB61).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _SummaryCol(
                        label: 'This Week',
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
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dayKey,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                ),
                                Text(
                                  '₹${dayTotal.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
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
