import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/squad_repository.dart';
import '../models/squad_model.dart';

class ExamPrepScreen extends StatefulWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  final Squad? squad;
  const ExamPrepScreen({
    super.key,
    required this.squadId,
    required this.uid,
    required this.repo,
    this.squad,
  });

  @override
  State<ExamPrepScreen> createState() => _ExamPrepScreenState();
}

class _ExamPrepScreenState extends State<ExamPrepScreen> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _orange = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Squad?>(
      stream: widget.repo.watchSquad(widget.squadId),
      builder: (ctx, snap) {
        final squad = snap.data ?? widget.squad;
        final active = squad?.examPrepActive ?? false;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A1A2E),
            elevation: 0,
            title: const Text('📖 Exam Prep Mode',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: active
              ? _ActiveView(squad: squad, repo: widget.repo, squadId: widget.squadId)
              : _InactiveView(repo: widget.repo, squadId: widget.squadId),
        );
      },
    );
  }
}

// ─── Inactive / Activate ─────────────────────────────────────────────────────
class _InactiveView extends StatefulWidget {
  final SquadRepository repo;
  final String squadId;
  const _InactiveView({required this.repo, required this.squadId});

  @override
  State<_InactiveView> createState() => _InactiveViewState();
}

class _InactiveViewState extends State<_InactiveView> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _orange = Color(0xFFE65100);
  final _subjectCtrl = TextEditingController();
  DateTime _examDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFBF360C), Color(0xFFE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📖', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 10),
              const Text(
                'Exam Prep Mode',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Activate to get 1.5× XP on tagged focus sessions, auto-generate Kanban template, and pin an exam countdown in chat.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Benefits
        ..._benefits.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(b[0], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      b[1],
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            )),

        const SizedBox(height: 24),

        // Form
        const Text(
          'Activate Exam Prep',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _subjectCtrl,
          decoration: _dec('Subject (e.g. Operating Systems, DBMS)'),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _examDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                      primary: Color(0xFFE65100)),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _examDate = picked);
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
                  'Exam Date: ${DateFormat('d MMM yyyy').format(_examDate)}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.calendar_today, size: 18, color: Color(0xFFE65100)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading
                ? null
                : () async {
                    if (_subjectCtrl.text.trim().isEmpty) return;
                    setState(() => _loading = true);
                    await widget.repo.activateExamPrep(
                        widget.squadId,
                        _subjectCtrl.text.trim(),
                        _examDate);
                    if (mounted) Navigator.pop(context);
                  },
            icon: const Icon(Icons.rocket_launch_outlined),
            label: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Activate Exam Prep',
                    style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  static const _benefits = [
    ['⚡', '1.5× XP multiplier for focus sessions tagged to this subject'],
    ['📋', 'Auto-creates a Kanban template with prep zones (Todo, In Progress, Revised, Confident)'],
    ['📌', 'Exam countdown pinned in squad chat'],
    ['🏆', '+20 squad trophies awarded when leader marks subject as Ready'],
  ];

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE65100), width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ─── Active View ──────────────────────────────────────────────────────────────
class _ActiveView extends StatelessWidget {
  final Squad? squad;
  final SquadRepository repo;
  final String squadId;
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _orange = Color(0xFFE65100);

  const _ActiveView(
      {required this.squad, required this.repo, required this.squadId});

  @override
  Widget build(BuildContext context) {
    final subject = squad?.examPrepSubject ?? 'Unknown';
    final examDate = squad?.examPrepDate;
    final daysLeft = examDate != null
        ? examDate.difference(DateTime.now()).inDays
        : 0;
    final urgencyColor =
        daysLeft <= 2 ? Colors.red : daysLeft <= 5 ? _orange : _primary;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Active card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [urgencyColor, urgencyColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🔴', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text(
                    'EXAM PREP ACTIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subject,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                examDate != null
                    ? '📅 Exam on ${DateFormat('d MMM yyyy').format(examDate)}'
                    : '',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('⏳', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    daysLeft <= 0 ? 'TODAY!' : '$daysLeft days remaining',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Stats box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _orange.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _StatRow('⚡ XP Multiplier', '1.5×'),
              const Divider(height: 12),
              _StatRow('📋 Kanban Mode', '$subject focused'),
              const Divider(height: 12),
              _StatRow('🏆 Completion Bonus', '+20 squad trophies'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Tips
        const Text('Prep Tips',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ..._tips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t[0], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(t[1],
                          style: const TextStyle(fontSize: 13, height: 1.4))),
                ],
              ),
            )),

        const SizedBox(height: 24),

        // Mark as ready
        OutlinedButton.icon(
          onPressed: () => _confirmDeactivate(context),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Mark as Ready — Deactivate Prep',
              style: TextStyle(fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: const BorderSide(color: Color(0xFF4C4D7B)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  static const _tips = [
    ['📖', 'Log focus sessions tagged to this subject to earn 1.5× XP automatically'],
    ['📋', 'Use the Kanban board to track topics from Backlog → Confident'],
    ['👥', 'Schedule a squad group-study call via the chat FAB'],
    ['📊', 'Check the heatmap wall to ensure everyone is contributing'],
    ['🎯', 'Share PYQs and notes in the Resource Vault for the squad'],
  ];

  void _confirmDeactivate(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Exam Prep?'),
        content: const Text(
            'This awards +20 squad trophies and resets XP multiplier.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.deactivateExamPrep(squadId);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
