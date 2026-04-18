import 'package:flutter/material.dart';

class WeeklyWrapCard extends StatelessWidget {
  final double totalSpent;
  final String topCategory;
  final double dailyAverage;
  final int entryCount;
  final String weekLabel;

  const WeeklyWrapCard({
    super.key,
    required this.totalSpent,
    required this.topCategory,
    required this.dailyAverage,
    required this.entryCount,
    this.weekLabel = 'This Week',
  });

  String get _wittyMessage {
    if (topCategory == '—') return 'No spending yet 🎉';
    const messages = {
      'Food': '🍜 Your stomach is your biggest investor',
      'Travel': '🚌 Always on the move!',
      'Books': '📚 Your brain is well-funded',
      'Fun': '🎮 Living your best life',
      'Other': '🧾 Miscellaneous mysteries',
    };
    return messages[topCategory] ?? '$topCategory is eating your budget';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A623), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A623).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                weekLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalSpent.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _wittyMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat(
                '₹${dailyAverage.toStringAsFixed(0)}/day',
                'Daily Avg',
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: 1,
                height: 30,
                color: Colors.white30,
              ),
              _stat('$entryCount', 'Entries'),
              if (topCategory != '—') ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: 1,
                  height: 30,
                  color: Colors.white30,
                ),
                _stat(topCategory, 'Top Spend'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }
}
