import 'package:flutter/material.dart';
import 'package:se_hack/core/services/theme_service.dart';
import '../data/squad_repository.dart';
import '../models/deadline_model.dart';
import 'package:intl/intl.dart';

class DeadlineRadarScreen extends StatelessWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  const DeadlineRadarScreen(
      {super.key,
      required this.squadId,
      required this.uid,
      required this.repo});

  static const Color _primary = Color(0xFF4C4D7B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('📅 Deadline Radar',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<Deadline>>(
        stream: repo.watchDeadlines(squadId),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7B61FF)));
          }
          final all = snap.data!;
          final priority = all.where((d) => d.isSquadPriority).toList();
          final normal =
              all.where((d) => !d.isSquadPriority).toList();

          if (all.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📅', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('No deadlines added yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Add one below to get started',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (priority.isNotEmpty) ...[
                _SectionHeader(
                    label: '🔴 SQUAD PRIORITY',
                    color: const Color(0xFFD32F2F)),
                const SizedBox(height: 8),
                ...priority.map((d) => _DeadlineTile(
                    deadline: d,
                    uid: uid,
                    isSquadPriority: true,
                    onDelete: () => repo.deleteDeadline(squadId, d.id))),
                const SizedBox(height: 16),
              ],
              if (normal.isNotEmpty) ...[
                _SectionHeader(
                    label: '📌 UPCOMING',
                    color: const Color(0xFF4C4D7B)),
                const SizedBox(height: 8),
                ...normal.map((d) => _DeadlineTile(
                    deadline: d,
                    uid: uid,
                    isSquadPriority: false,
                    onDelete: () => repo.deleteDeadline(squadId, d.id))),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Deadline',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddDeadlineSheet(
          squadId: squadId, uid: uid, repo: repo),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  final Deadline deadline;
  final String uid;
  final bool isSquadPriority;
  final VoidCallback onDelete;

  const _DeadlineTile({
    required this.deadline,
    required this.uid,
    required this.isSquadPriority,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = deadline.daysLeft;
    final urgencyColor = daysLeft <= 1
        ? const Color(0xFFD32F2F)
        : daysLeft <= 3
            ? const Color(0xFFEF6C00)
            : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSquadPriority
              ? const Color(0xFFD32F2F).withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Urgency bar
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: urgencyColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  '${deadline.subject} · Due ${DateFormat('d MMM').format(deadline.dueDate)}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '👥 ${deadline.addedBy.length} member${deadline.addedBy.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (isSquadPriority) ...[
                      const SizedBox(width: 6),
                      const Text('⚡ Squad Priority',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  deadline.isOverdue
                      ? 'Overdue!'
                      : daysLeft == 0
                          ? 'Today!'
                          : '$daysLeft days',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: urgencyColor),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close,
                    size: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddDeadlineSheet extends StatefulWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  const _AddDeadlineSheet(
      {required this.squadId, required this.uid, required this.repo});

  @override
  State<_AddDeadlineSheet> createState() => _AddDeadlineSheetState();
}

class _AddDeadlineSheetState extends State<_AddDeadlineSheet> {
  static const Color _primary = Color(0xFF4C4D7B);
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  DateTime _due = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Deadline',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 14),
              TextField(
                controller: _titleCtrl,
                decoration: _dec('Assignment / task title *'),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subjectCtrl,
                decoration: _dec('Subject (e.g. OS, DBMS)'),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _due,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF4C4D7B),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _due = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Due: ${DateFormat('d MMM yyyy').format(_due)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Icon(Icons.calendar_today,
                          size: 18, color: Color(0xFF4C4D7B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          if (_titleCtrl.text.trim().isEmpty) return;
                          setState(() => _loading = true);
                          await widget.repo.addDeadline(
                            widget.squadId,
                            _titleCtrl.text.trim(),
                            _subjectCtrl.text.trim(),
                            _due,
                          );
                          if (mounted) Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Add Deadline',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
              const BorderSide(color: Color(0xFF4C4D7B), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
