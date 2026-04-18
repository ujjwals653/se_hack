import 'package:flutter/material.dart';
import '../data/squad_repository.dart';
import '../models/squad_model.dart';

class CreateSquadScreen extends StatefulWidget {
  const CreateSquadScreen({super.key});

  @override
  State<CreateSquadScreen> createState() => _CreateSquadScreenState();
}

class _CreateSquadScreenState extends State<CreateSquadScreen> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  final _repo = SquadRepository();
  final _nameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  SquadType _type = SquadType.open;
  String _badge = '⚡';
  bool _loading = false;

  static const _badges = [
    '⚡', '🔥', '🏆', '📚', '🚀', '🧠', '🎯', '💡', '⚔️', '🛡️',
    '✨', '🦁', '🐉', '🦅', '🌊', '⚗️', '🎓', '🌙', '☀️', '💎',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a squad name')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.createSquad(
        name: _nameCtrl.text.trim(),
        tagline: _taglineCtrl.text.trim().isEmpty
            ? 'A rising squad!'
            : _taglineCtrl.text.trim(),
        badge: _badge,
        type: _type,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Squad',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 8),

                  // Badge picker
                  const Text(
                    'Choose a Badge',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _badges.map((b) {
                      final selected = b == _badge;
                      return GestureDetector(
                        onTap: () => setState(() => _badge = b),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: selected
                                ? _accent.withOpacity(0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? _accent : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child:
                                Text(b, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Preview card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primary, _accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(_badge,
                            style: const TextStyle(fontSize: 40)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameCtrl.text.isEmpty
                                    ? 'Your Squad Name'
                                    : _nameCtrl.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _taglineCtrl.text.isEmpty
                                    ? 'Your epic tagline here...'
                                    : _taglineCtrl.text,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Name field
                  _buildLabel('Squad Name *'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    maxLength: 30,
                    decoration: _inputDecoration('e.g. Deep Work Guild'),
                  ),

                  const SizedBox(height: 16),

                  // Tagline field
                  _buildLabel('Tagline'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _taglineCtrl,
                    onChanged: (_) => setState(() {}),
                    maxLength: 60,
                    decoration: _inputDecoration(
                        'e.g. "No notes without focus" 🔥'),
                  ),

                  const SizedBox(height: 16),

                  // Type
                  _buildLabel('Privacy'),
                  const SizedBox(height: 8),
                  ...[
                    [
                      SquadType.open,
                      '🌍 Open',
                      'Anyone can join without approval'
                    ],
                    [
                      SquadType.inviteOnly,
                      '🔒 Invite Only',
                      'Join requests need approval'
                    ],
                    [
                      SquadType.closed,
                      '🚫 Closed',
                      "Squad is not discoverable"
                    ],
                  ].map((opt) {
                    final type = opt[0] as SquadType;
                    final label = opt[1] as String;
                    final desc = opt[2] as String;
                    return GestureDetector(
                      onTap: () => setState(() => _type = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _type == type
                              ? _accent.withOpacity(0.08)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _type == type
                                ? _accent
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _type == type
                                          ? _primary
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    desc,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Radio<SquadType>(
                              value: type,
                              groupValue: _type,
                              activeColor: _accent,
                              onChanged: (v) =>
                                  setState(() => _type = v!),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _create,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Create Squad 🚀',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Color(0xFF1A1A2E),
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF7B61FF), width: 2),
        ),
        counterStyle:
            TextStyle(fontSize: 11, color: Colors.grey.shade400),
      );
}
