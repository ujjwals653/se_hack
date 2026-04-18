// lib/features/timetable/presentation/widgets/class_card.dart
// Lumina — Single class slot card widget

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/timetable_entry.dart';

class ClassCard extends StatelessWidget {
  final TimetableEntry entry;
  const ClassCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.accentAmber, width: 4),
        ),
      ),
      child: Row(
        children: [
          // Time column
          Column(
            children: [
              Text(entry.startTime,
                  style: const TextStyle(
                      color: AppColors.accentAmber,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(entry.endTime,
                  style:
                      const TextStyle(color: AppColors.textSecondary,
                          fontSize: 12)),
            ],
          ),
          const SizedBox(width: 16),
          // Subject details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subjectName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(entry.professorName,
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.room, size: 14,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(entry.room,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.group, size: 14,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(entry.batch,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
