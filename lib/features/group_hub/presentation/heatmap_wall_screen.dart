import 'package:flutter/material.dart';
import '../data/squad_repository.dart';
import '../models/squad_model.dart';
import 'package:intl/intl.dart';

class HeatmapWallScreen extends StatefulWidget {
  final String squadId;
  final SquadRepository repo;
  const HeatmapWallScreen(
      {super.key, required this.squadId, required this.repo});

  @override
  State<HeatmapWallScreen> createState() => _HeatmapWallScreenState();
}

class _HeatmapWallScreenState extends State<HeatmapWallScreen> {
  static const Color _primary = Color(0xFF4C4D7B);
  Map<String, Map<String, int>>? _heatmap;
  List<SquadMember> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memberStream = widget.repo.watchMembers(widget.squadId);
    memberStream.first.then((members) async {
      final hm = await widget.repo.fetchSquadHeatmap(members);
      if (mounted) {
        setState(() {
          _members = members;
          _heatmap = hm;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('🔥 Focus Heatmap',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7B61FF)))
          : _members.isEmpty
              ? const Center(child: Text('No members found'))
              : Column(
                  children: [
                    // Legend
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          const Text(
                            'Study Intensity:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          ..._cellColors.entries.map((e) => Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 2),
                                    decoration: BoxDecoration(
                                      color: e.value,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Text(e.key,
                                      style: const TextStyle(fontSize: 9)),
                                  const SizedBox(width: 6),
                                ],
                              )),
                        ],
                      ),
                    ),

                    // Day headers
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(96, 8, 16, 4),
                      child: Row(
                        children: List.generate(5, (i) {
                          final day = DateTime.now()
                              .subtract(Duration(days: 29 - (i * 6)));
                          return Expanded(
                            child: Text(
                              DateFormat('d/M').format(day),
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }),
                      ),
                    ),

                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                        itemCount: _members.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final m = _members[i];
                          final log = _heatmap?[m.uid] ?? {};
                          return _HeatmapRow(member: m, log: log);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  static const _cellColors = {
    'None': Color(0xFFF1EFE8),
    '<30m': Color(0xFF9FE1CB),
    '<1h': Color(0xFF1D9E75),
    '<2h': Color(0xFF0F6E56),
    '2h+': Color(0xFF085041),
  };
}

class _HeatmapRow extends StatelessWidget {
  final SquadMember member;
  final Map<String, int> log;
  const _HeatmapRow({required this.member, required this.log});

  Color _cellColor(int minutes) {
    if (minutes == 0) return const Color(0xFFF1EFE8);
    if (minutes < 30) return const Color(0xFF9FE1CB);
    if (minutes < 60) return const Color(0xFF1D9E75);
    if (minutes < 120) return const Color(0xFF0F6E56);
    return const Color(0xFF085041);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Member name
        SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.displayName?.split(' ').first ?? '?',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Lv.${member.level}',
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        // 30-day grid
        Expanded(
          child: Row(
            children: List.generate(30, (i) {
              final day =
                  DateTime.now().subtract(Duration(days: 29 - i));
              final key = DateFormat('yyyy-MM-dd').format(day);
              final mins = log[key] ?? 0;
              return Expanded(
                child: Tooltip(
                  message: '$key: ${mins}m',
                  child: Container(
                    height: 14,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: _cellColor(mins),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
