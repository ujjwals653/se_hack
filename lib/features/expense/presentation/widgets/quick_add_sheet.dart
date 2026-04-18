import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../bloc/expense_cubit.dart';
import '../../data/expense_model.dart';
import '../../data/recurring_expense_model.dart';
import 'category_chip_row.dart';

class QuickAddSheet extends StatefulWidget {
  final Expense? existingExpense;

  const QuickAddSheet({super.key, this.existingExpense});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  static const Color _amber = Color(0xFFF5A623);
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'Food';
  bool _makeRecurring = false;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _amountController.text = e.amount.toStringAsFixed(0);
      _noteController.text = e.note;
      _selectedCategory = e.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final cubit = context.read<ExpenseCubit>();

    try {
      if (widget.existingExpense != null) {
        // Update
        final updated = widget.existingExpense!.copyWith(
          amount: amount,
          category: _selectedCategory,
          note: _noteController.text.trim(),
        );
        await cubit.updateExpense(updated);
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense updated ✓')),
          );
        }
      } else {
        // Create
        final expense = Expense(
          id: const Uuid().v4(),
          amount: amount,
          category: _selectedCategory,
          note: _noteController.text.trim(),
          createdAt: DateTime.now(),
        );
        await cubit.addExpense(expense);

        // Also create recurring rule if toggled
        if (_makeRecurring) {
          await cubit.addRecurring(
            amount: amount,
            category: _selectedCategory,
            note: _noteController.text.trim(),
            frequency: _frequency,
          );
        }

        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '₹${amount.toStringAsFixed(0)} logged${_makeRecurring ? ' + recurring set 🔁' : ''} ✓',
              ),
              backgroundColor: _amber,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingExpense != null;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              isEditing ? 'Edit Expense' : 'Log Expense',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Amount input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _amber,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 32,
                          color: Colors.black26,
                          fontWeight: FontWeight.bold,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Category chips
          const Padding(
            padding: EdgeInsets.only(left: 24, bottom: 10),
            child: Text(
              'Category',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54),
            ),
          ),
          CategoryChipRow(
            selected: _selectedCategory,
            onSelected: (cat) => setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: 16),

          // Note field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _noteController,
              maxLength: 80,
              decoration: InputDecoration(
                hintText: 'What was it for? (optional)',
                hintStyle:
                    const TextStyle(color: Colors.black38, fontSize: 14),
                counterText: '',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _amber, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recurring toggle (only for new expenses)
          if (!isEditing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: _makeRecurring
                      ? const Color(0xFF4ECDC4).withOpacity(0.08)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _makeRecurring
                        ? const Color(0xFF4ECDC4)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _makeRecurring,
                      onChanged: (v) => setState(() => _makeRecurring = v),
                      activeColor: const Color(0xFF4ECDC4),
                      title: const Row(
                        children: [
                          Text('🔁 ', style: TextStyle(fontSize: 16)),
                          Text(
                            'Make Recurring',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text(
                        'Auto-log this expense periodically',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    if (_makeRecurring) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: RecurringFrequency.values.map((freq) {
                            final selected = _frequency == freq;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _frequency = freq),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF4ECDC4)
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF4ECDC4)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    freq.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Submit button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Expense' : 'Add Expense',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
