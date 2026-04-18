import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/expense_cubit.dart';
import '../data/expense_model.dart';
import 'widgets/weekly_wrap_card.dart';

enum _TimeFilter { week, month, all }

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  _TimeFilter _filter = _TimeFilter.week;
  int _touchedIndex = -1;

  static const Color _amber = Color(0xFFF5A623);

  void _applyFilter(_TimeFilter filter) {
    setState(() => _filter = filter);
    final cubit = context.read<ExpenseCubit>();
    final now = DateTime.now();
    switch (filter) {
      case _TimeFilter.week:
        cubit.loadThisWeek();
        break;
      case _TimeFilter.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        cubit.loadByDateRange(start, end);
        break;
      case _TimeFilter.all:
        cubit.loadAll();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        final isLoaded = state is ExpenseLoaded;
        final expenses = isLoaded ? state.expenses : <Expense>[];
        final breakdown =
            isLoaded ? state.categoryBreakdown : <String, double>{};
        final total = expenses.fold<double>(0, (s, e) => s + e.amount);
        final dailyAvg = isLoaded ? state.dailyAverage : 0.0;
        final topCat = isLoaded ? state.topCategory : '—';

        final sections = _buildSections(breakdown, total);

        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
          children: [
            // Weekly Wrap Card
            WeeklyWrapCard(
              totalSpent: total,
              topCategory: topCat,
              dailyAverage: dailyAvg,
              entryCount: expenses.length,
              weekLabel: _filterLabel,
            ),

            // Time filter toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _TimeFilter.values.map((f) {
                  final selected = _filter == f;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _applyFilter(f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? _amber : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _filterName(f),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Pie Chart
            if (sections.isEmpty)
              _EmptyChart(filter: _filterLabel)
            else
              _PieSection(
                sections: sections,
                touchedIndex: _touchedIndex,
                onTouch: (i) => setState(() => _touchedIndex = i),
                total: total,
              ),

            const SizedBox(height: 16),

            // Legend
            if (breakdown.isNotEmpty)
              _LegendList(breakdown: breakdown, total: total),

            // Savings insight
            if (isLoaded && total > 0)
              _SavingsInsight(
                state: state,
                total: total,
              ),
          ],
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections(
      Map<String, double> breakdown, double total) {
    if (total == 0) return [];
    int i = 0;
    return breakdown.entries.map((entry) {
      final cat = ExpenseCategory.fromLabel(entry.key);
      final pct = entry.value / total;
      final isTouched = i == _touchedIndex;
      final section = PieChartSectionData(
        color: cat.color,
        value: entry.value,
        title: isTouched ? '${(pct * 100).toStringAsFixed(1)}%' : '',
        radius: isTouched ? 70 : 58,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      i++;
      return section;
    }).toList();
  }

  String get _filterLabel {
    switch (_filter) {
      case _TimeFilter.week:
        return 'This Week';
      case _TimeFilter.month:
        return 'This Month';
      case _TimeFilter.all:
        return 'All Time';
    }
  }

  String _filterName(_TimeFilter f) {
    switch (f) {
      case _TimeFilter.week:
        return 'Week';
      case _TimeFilter.month:
        return 'Month';
      case _TimeFilter.all:
        return 'All';
    }
  }
}

class _PieSection extends StatelessWidget {
  final List<PieChartSectionData> sections;
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  final double total;

  const _PieSection({
    required this.sections,
    required this.touchedIndex,
    required this.onTouch,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    onTouch(-1);
                    return;
                  }
                  onTouch(
                      response.touchedSection!.touchedSectionIndex);
                },
              ),
              sections: sections,
              centerSpaceRadius: 60,
              sectionsSpace: 3,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendList extends StatelessWidget {
  final Map<String, double> breakdown;
  final double total;
  const _LegendList({required this.breakdown, required this.total});

  @override
  Widget build(BuildContext context) {
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: sorted.map((entry) {
          final cat = ExpenseCategory.fromLabel(entry.key);
          final pct = total > 0 ? (entry.value / total * 100) : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: cat.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${cat.emoji} ${cat.label}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const Spacer(),
                Text(
                  '₹${entry.value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${pct.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: cat.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String filter;
  const _EmptyChart({required this.filter});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(
              'No expenses for $filter',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsInsight extends StatelessWidget {
  final ExpenseLoaded state;
  final double total;
  const _SavingsInsight({required this.state, required this.total});

  @override
  Widget build(BuildContext context) {
    // Sum all budget limits
    final totalLimit = state.budgets
        .fold<double>(0, (s, b) => s + b.monthlyLimit);
    if (totalLimit == 0) return const SizedBox.shrink();

    final isUnder = total <= totalLimit;
    final diff = (totalLimit - total).abs();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isUnder ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnder ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(
            isUnder ? '🟢' : '🔴',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUnder
                      ? 'Great job! You\'re ₹${diff.toStringAsFixed(0)} under budget'
                      : 'Oops! You\'re ₹${diff.toStringAsFixed(0)} over budget',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color:
                        isUnder ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                Text(
                  isUnder
                      ? 'Keep it up and you\'ll save this month 💪'
                      : 'Try cutting back on ${state.topCategory} this week',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnder ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
