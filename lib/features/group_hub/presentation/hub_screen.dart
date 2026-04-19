import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/squad_repository.dart';
import 'squad_discovery_screen.dart';
import 'create_squad_screen.dart';
import 'my_squads_screen.dart';

/// Entry point for the Group Hub tab.
/// Shows either "Join/Create Squad" onboarding OR directly jumps to your squad.
class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final _repo = SquadRepository();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F5FA),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
            ),
          );
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        final squadIds = List<String>.from(data?['squadIds'] ?? []);
        if (data != null &&
            data.containsKey('squadId') &&
            data['squadId'] != null) {
          if (!squadIds.contains(data['squadId'])) {
            squadIds.add(data['squadId']);
          }
        }

        if (squadIds.isNotEmpty) {
          return MySquadsScreen(squadIds: squadIds, uid: _uid, repo: _repo);
        }
        return _NoSquadScreen(repo: _repo, uid: _uid);
      },
    );
  }
}

// ─── No Squad Onboarding ─────────────────────────────────────────────────────
class _NoSquadScreen extends StatelessWidget {
  final SquadRepository repo;
  final String uid;
  const _NoSquadScreen({required this.repo, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pastel Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚔️', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        'Squad Mode',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF7B61FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Group Hub',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A1A2E),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Study together. Win together.',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ── White Card Panel ─────────────────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get Started',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Action Cards ──────────────────────────────────────────
                    _ActionCard(
                      icon: Icons.search_rounded,
                      iconBg: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                      iconColor: const Color(0xFF7B61FF),
                      title: 'Browse & Join a Squad',
                      subtitle: 'Find study squads that match your interests',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SquadDiscoveryScreen())),
                    ),
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.group_add_rounded,
                      iconBg: const Color(0xFF43E0A3).withValues(alpha: 0.1),
                      iconColor: const Color(0xFF3DBF8A),
                      title: 'Create a Squad',
                      subtitle: 'Start your own study group and invite friends',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CreateSquadScreen())),
                    ),
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconBg: const Color(0xFF3BCAE5).withValues(alpha: 0.1),
                      iconColor: const Color(0xFF1EA8C4),
                      title: 'Add a Friend',
                      subtitle: 'Start a private 1-on-1 chat',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MySquadsScreen(squadIds: const [], uid: uid, repo: repo),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    Text(
                      'What you can do',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Feature Grid ──────────────────────────────────────────
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        _FeatureGridCard(
                          emoji: '💬',
                          title: 'Squad Chat',
                          subtitle: 'Real-time messaging',
                          color: Color(0xFF7B61FF),
                        ),
                        _FeatureGridCard(
                          emoji: '📅',
                          title: 'Deadline Radar',
                          subtitle: 'Shared calendar',
                          color: Color(0xFFFFAB61),
                        ),
                        _FeatureGridCard(
                          emoji: '🏆',
                          title: 'Study Wars',
                          subtitle: 'Compete & earn XP',
                          color: Color(0xFF43E0A3),
                        ),
                        _FeatureGridCard(
                          emoji: '📋',
                          title: 'Kanban Board',
                          subtitle: 'Task management',
                          color: Color(0xFF3BCAE5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Action Card ─────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ─── Feature Grid Card ────────────────────────────────────────────────────────
class _FeatureGridCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureGridCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
