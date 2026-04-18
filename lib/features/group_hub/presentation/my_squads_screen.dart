import 'package:flutter/material.dart';
import '../data/squad_repository.dart';
import '../models/squad_model.dart';
import 'squad_home_screen.dart';
import 'squad_discovery_screen.dart';
import 'create_squad_screen.dart';

class MySquadsScreen extends StatelessWidget {
  final List<String> squadIds;
  final String uid;
  final SquadRepository repo;

  const MySquadsScreen({
    super.key,
    required this.squadIds,
    required this.uid,
    required this.repo,
  });

  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── WhatsApp-style header ──
            Container(
              color: _primary,
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Group Hub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      _headerIcon(Icons.search, () {}),
                      _headerIcon(Icons.more_vert, () {
                        _showMoreMenu(context);
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Tabs row (like WhatsApp's Chats / Status / Calls)
                  Row(
                    children: [
                      _TabChip(label: 'All', selected: true, onTap: () {}),
                      const SizedBox(width: 8),
                      _TabChip(label: 'Study', selected: false, onTap: () {}),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'Projects',
                        selected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // ── Squad list ──
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 0, bottom: 100),
                  itemCount: squadIds.length,
                  itemBuilder: (ctx, i) {
                    final sId = squadIds[i];
                    return StreamBuilder<Squad?>(
                      stream: repo.watchSquad(sId),
                      builder: (ctx, snap) {
                        if (!snap.hasData) {
                          return _buildShimmerItem();
                        }
                        final squad = snap.data;
                        if (squad == null) return const SizedBox.shrink();
                        return _SquadListTile(
                          squad: squad,
                          squadId: sId,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SquadHomeScreen(squadId: sId, uid: uid),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Small FAB for join
            FloatingActionButton.small(
              heroTag: 'join',
              backgroundColor: _primary.withOpacity(0.85),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SquadDiscoveryScreen()),
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            // Main FAB for create
            FloatingActionButton(
              heroTag: 'create',
              backgroundColor: _accent,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateSquadScreen()),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
      onPressed: onTap,
      splashRadius: 20,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.search, color: _primary),
              title: const Text('Browse & Join Squads'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SquadDiscoveryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: _primary),
              title: const Text('Create New Squad'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateSquadScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab filter chips (WhatsApp style) ────────────────────────────────────────
class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Squad tile (WhatsApp chat item style) ────────────────────────────────────
class _SquadListTile extends StatelessWidget {
  final Squad squad;
  final String squadId;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  const _SquadListTile({
    required this.squad,
    required this.squadId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _accent.withOpacity(0.15),
                    _primary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(squad.badge, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    squad.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    squad.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Members pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group, size: 12, color: _primary.withOpacity(0.6)),
                  const SizedBox(width: 3),
                  Text(
                    '${squad.memberCount}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
