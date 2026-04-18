import 'package:flutter/material.dart';
import 'package:se_hack/features/timetable/data/models/timetable_entry.dart';

class EditEntrySheet extends StatefulWidget {
  final TimetableEntry? entry; // null when adding new
  final int periodNumber;
  final ValueChanged<TimetableEntry> onSave;
  final VoidCallback? onDelete;

  const EditEntrySheet({
    super.key,
    this.entry,
    required this.periodNumber,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<EditEntrySheet> {
  late TextEditingController _subjectController;
  late TextEditingController _sectionController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late bool _isFree;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _subjectController = TextEditingController(text: e?.subject ?? '');
    _sectionController = TextEditingController(text: e?.section ?? '');
    _startTimeController = TextEditingController(text: e?.startTime ?? '');
    _endTimeController = TextEditingController(text: e?.endTime ?? '');
    _isFree = e?.isFree ?? false;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _sectionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.entry == null;
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isNew ? 'Add Period' : 'Edit Period ${widget.periodNumber}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),

            // Free Period toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _isFree ? const Color(0xFFF0F4FF) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Free Period',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: _isFree,
                onChanged: (val) {
                  setState(() {
                    _isFree = val;
                    if (val) {
                      _subjectController.text = 'Free Period';
                    } else if (_subjectController.text == 'Free Period') {
                      _subjectController.text = '';
                    }
                  });
                },
                activeColor: const Color(0xFF4C4D7B),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),

            // Subject
            if (!_isFree) ...[
              _buildTextField(
                controller: _subjectController,
                label: 'Subject',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 12),
            ],

            // Section
            _buildTextField(
              controller: _sectionController,
              label: 'Section (e.g., 7th A)',
              icon: Icons.class_outlined,
            ),
            const SizedBox(height: 12),

            // Time Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _startTimeController,
                    label: 'Start Time',
                    icon: Icons.access_time,
                    hint: '09:00',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _endTimeController,
                    label: 'End Time',
                    icon: Icons.access_time,
                    hint: '10:00',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                if (!isNew && widget.onDelete != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        widget.onDelete!();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (!isNew && widget.onDelete != null) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _handleSave,
                    icon: Icon(isNew ? Icons.add : Icons.check, size: 18),
                    label: Text(isNew ? 'Add' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C4D7B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF4C4D7B)),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4C4D7B), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _handleSave() {
    final subject = _isFree ? 'Free Period' : _subjectController.text.trim();
    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject cannot be empty')),
      );
      return;
    }

    final entry = TimetableEntry(
      period: widget.periodNumber,
      subject: subject,
      startTime: _startTimeController.text.trim(),
      endTime: _endTimeController.text.trim(),
      section: _sectionController.text.trim(),
      isFree: _isFree,
    );

    widget.onSave(entry);
    Navigator.pop(context);
  }
}
