import 'package:flutter/material.dart';
import 'package:se_hack/features/timetable/data/models/timetable_entry.dart';

class ClassCard extends StatelessWidget {
  final TimetableEntry entry;
  final Color cardColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ClassCard({
    super.key,
    required this.entry,
    required this.cardColor,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (entry.isLab) return _buildLabCard(context);
    if (entry.isFree) return _buildFreeCard(context);
    return _buildClassCard(context);
  }

  Widget _buildLabCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            left: BorderSide(color: Color(0xFF9333EA), width: 4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE9D4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.science_outlined,
                color: Color(0xFF7E22CE),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compulsory Lab',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF581C87),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Lab rotation — not counted in lectures',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple.shade300,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.rotate_right_outlined, size: 16, color: Color(0xFF9333EA)),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: cardColor, width: 4),
          ),
        ),
        child: Row(
          children: [
            // Subject icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getSubjectIcon(entry.subject),
                color: cardColor.withOpacity(0.9),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Subject details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.subject,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (entry.section.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      entry.section,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Edit indicator
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: Colors.blue.shade200, width: 4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.self_improvement,
                color: Colors.blue.shade300,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Free Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    final lower = subject.toLowerCase();
    if (lower.contains('lab')) return Icons.science_outlined;
    if (lower.contains('math')) return Icons.calculate_outlined;
    if (lower.contains('english') || lower.contains('lang')) return Icons.menu_book_outlined;
    if (lower.contains('science')) return Icons.science_outlined;
    if (lower.contains('social') || lower.contains('history')) return Icons.public_outlined;
    if (lower.contains('geo')) return Icons.terrain_outlined;
    if (lower.contains('phys')) return Icons.fitness_center_outlined;
    if (lower.contains('chem')) return Icons.biotech_outlined;
    if (lower.contains('bio')) return Icons.eco_outlined;
    if (lower.contains('comp') || lower.contains('it') || lower.contains('code')) return Icons.computer_outlined;
    if (lower.contains('art') || lower.contains('draw')) return Icons.palette_outlined;
    if (lower.contains('music')) return Icons.music_note_outlined;
    if (lower.contains('hindi') || lower.contains('sanskrit')) return Icons.translate_outlined;
    return Icons.school_outlined;
  }
}
