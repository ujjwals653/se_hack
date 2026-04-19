import 'package:flutter/material.dart';
import 'package:se_hack/core/services/theme_service.dart';
import '../data/squad_repository.dart';
import '../models/squad_model.dart';

class SquadDiscoveryScreen extends StatefulWidget {
  const SquadDiscoveryScreen({super.key});

  @override
  State<SquadDiscoveryScreen> createState() => _SquadDiscoveryScreenState();
}

class _SquadDiscoveryScreenState extends State<SquadDiscoveryScreen> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  final _repo = SquadRepository();
  final _searchCtrl = TextEditingController();
  List<Squad> _squads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final result = await _repo.searchSquads(q);
    if (mounted) setState(() {
      _squads = result;
      _loading = false;
    });
  }

  Future<void> _join(Squad squad) async {
    try {
      await _repo.joinSquad(squad.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(squad.type == SquadType.open
              ? 'Joined ${squad.name}! 🎉'
              : 'Join request sent to ${squad.name}'),
          backgroundColor: _primary,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
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
          'Find a Squad',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search bar in header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search squads...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon:
                    Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // List area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.scaffoldBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF7B61FF)))
                  : _squads.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🔍',
                                  style: TextStyle(fontSize: 48)),
                              SizedBox(height: 12),
                              Text(
                                'No squads found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _squads.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final s = _squads[i];
                            return _SquadCard(squad: s, onJoin: _join);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquadCard extends StatelessWidget {
  final Squad squad;
  final void Function(Squad) onJoin;
  const _SquadCard({required this.squad, required this.onJoin});

  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary.withOpacity(0.1), _accent.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(squad.badge,
                  style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      squad.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _TypeBadge(type: squad.type),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  squad.tagline,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('👥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '${squad.memberCount}/${squad.maxMembers} members',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: squad.memberCount >= squad.maxMembers
                ? null
                : () => onJoin(squad),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text(
              squad.type == SquadType.open ? 'Join' : 'Request',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final SquadType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final label = type == SquadType.open
        ? '🌍'
        : type == SquadType.inviteOnly
            ? '🔒'
            : '🚫';
    return Text(label, style: const TextStyle(fontSize: 11));
  }
}
