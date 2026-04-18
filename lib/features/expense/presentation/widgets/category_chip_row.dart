import 'package:flutter/material.dart';
import '../../data/expense_model.dart';

class CategoryChipRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryChipRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: ExpenseCategory.values.map((cat) {
          final isSelected = selected == cat.label;
          return GestureDetector(
            onTap: () => onSelected(cat.label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? cat.color : cat.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? cat.color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
