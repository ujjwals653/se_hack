import 'package:flutter/material.dart';
import 'package:se_hack/features/timetable/data/models/timetable_entry.dart';
import 'package:se_hack/features/timetable/presentation/widgets/class_card.dart';

class TimelineSlot extends StatelessWidget {
  final TimetableEntry entry;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TimelineSlot({
    super.key,
    required this.entry,
    required this.color,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Time label & period badge
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(entry.startTime),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      if (entry.section.isNotEmpty)
                        Text(
                          entry.section,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      Text(
                        'Period ${entry.period}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Timeline dot and line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.isFree ? Colors.blue.shade200 : color,
                    border: Border.all(
                      color: (entry.isFree ? Colors.blue.shade100 : color.withOpacity(0.3)),
                      width: 3,
                    ),
                  ),
                ),
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey.shade200,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: class card
          Expanded(
            child: ClassCard(
              entry: entry,
              cardColor: color,
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }
}
