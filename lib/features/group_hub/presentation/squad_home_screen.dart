import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/squad_repository.dart';
import '../models/squad_model.dart';
import '../models/challenge_resource_model.dart';
import 'squad_chat_screen.dart';
import 'squad_kanban_screen.dart';
import 'coin_store_screen.dart';
import 'deadline_radar_screen.dart';
import 'squad_notes_screen.dart';
import 'heatmap_wall_screen.dart';
import 'resource_vault_screen.dart';
import 'exam_prep_screen.dart';

class SquadHomeScreen extends StatefulWidget {
  final String squadId;
  final String uid;
  const SquadHomeScreen({super.key, required this.squadId, required this.uid});

  @override
  State<SquadHomeScreen> createState() => _SquadHomeScreenState();
}

class _SquadHomeScreenState extends State<SquadHomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  final _repo = SquadRepository();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Squad?>(
      stream: _repo.watchSquad(widget.squadId),
      builder: (ctx, squadSnap) {
        final squad = squadSnap.data;

        return Scaffold(
          backgroundColor: _primary,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Text(squad?.badge ?? '⚡',
                          style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              squad?.name ?? '...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              squad?.league ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Exam Prep badge
                      if (squad?.examPrepActive == true)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.deepOrange.withOpacity(0.6)),
                          ),
                          child: Text(
                            '📖 ${squad?.examPrepSubject}',
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // Coin chip
                      StreamBuilder<int>(
                        stream: _repo.watchMyCoins(),
                        builder: (_, snap) {
                          final coins = snap.data ?? 0;
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CoinStoreScreen(
                                    uid: widget.uid, repo: _repo),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.amber.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🪙',
                                      style: TextStyle(fontSize: 13)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$coins',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Stats row ─────────────────────────────────────────────
                if (squad != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: _StatsBanner(squad: squad, repo: _repo, squadId: widget.squadId),
                  ),

                // ── White area ────────────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: TabBar(
                              controller: _tabs,
                              indicator: BoxDecoration(
                                color: _primary,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey.shade600,
                              labelStyle: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: '👥 Members'),
                                Tab(text: '📋 Kanban'),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabs,
                            children: [
                              _MembersTab(
                                squadId: widget.squadId,
                                myUid: widget.uid,
                                repo: _repo,
                                squad: squad,
                              ),
                              SquadKanbanScreen(
                                squadId: widget.squadId,
                                uid: widget.uid,
                                repo: _repo,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Chat FAB ──────────────────────────────────────────────────
          floatingActionButton: FloatingActionButton(
            heroTag: 'chat_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SquadChatScreen(
                  squadId: widget.squadId,
                  uid: widget.uid,
                  repo: _repo,
                  squadName: squad?.name ?? 'Squad Chat',
                ),
              ),
            ),
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            child: const Icon(Icons.chat_bubble_outline),
          ),
        );
      },
    );
  }
}

// ─── Stats banner (trophies, health, weekly pts) ─────────────────────────────
class _StatsBanner extends StatelessWidget {
  final Squad squad;
  final SquadRepository repo;
  final String squadId;
  static const Color _primary = Color(0xFF4C4D7B);

  const _StatsBanner(
      {required this.squad, required this.repo, required this.squadId});

  @override
  Widget build(BuildContext context) {
    final healthColor = squad.healthScore >= 80
        ? Colors.greenAccent
        : squad.healthScore >= 60
            ? Colors.amber
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _S(emoji: '🏆', label: 'Trophies', value: '${squad.trophies}'),
          _vd(),
          _S(emoji: '📅', label: 'This Week', value: '${squad.weeklyPoints} pts'),
          _vd(),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 3),
                  Text(
                    '${squad.healthScore}',
                    style: TextStyle(
                      color: healthColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Text(
                'Health',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vd() => Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 1, height: 30, color: Colors.white24);
}

class _S extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _S({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── Members Tab ─────────────────────────────────────────────────────────────
class _MembersTab extends StatelessWidget {
  final String squadId;
  final String myUid;
  final SquadRepository repo;
  final Squad? squad;
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  const _MembersTab({
    required this.squadId,
    required this.myUid,
    required this.repo,
    required this.squad,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SquadMember>>(
      stream: repo.watchMembers(squadId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7B61FF)));
        }
        final members = snap.data!;
        final myMember = members.firstWhere((m) => m.uid == myUid,
            orElse: () => members.isNotEmpty ? members.first : _emptyMember());
        final myRole = myMember.role;
        final healthScore = repo.computeHealthScore(members);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          children: [
            // Daily Challenge card
            _DailyChallengeCard(
                squadId: squadId, repo: repo, memberCount: members.length),

            const SizedBox(height: 14),

            // Health score card
            _HealthCard(squad: squad, computedScore: healthScore),

            const SizedBox(height: 14),

            // Feature shortcuts
            _FeatureGrid(
              squadId: squadId,
              uid: myUid,
              repo: repo,
              myRole: myRole,
              squad: squad,
            ),

            const SizedBox(height: 16),

            // Member section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Squad Members',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E)),
                ),
                Text(
                  '${members.length}/${squad?.maxMembers ?? 15}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Role legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: SquadRole.values.map((r) => Column(
                children: [
                  Text(r.badge, style: const TextStyle(fontSize: 14)),
                  Text(r.label,
                      style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              )).toList(),
            ),

            const SizedBox(height: 12),

            // Member grid — 3 per row
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: members.length,
              itemBuilder: (_, i) => _MemberCard(
                member: members[i],
                isMe: members[i].uid == myUid,
                myRole: myRole,
                onTap: () => _showMemberActions(context, members[i], myRole),
              ),
            ),

            const SizedBox(height: 16),

            if (myRole.canAcceptRequests) _buildRequestsBtn(context),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _confirmLeave(context),
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text('Leave Squad'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  SquadMember _emptyMember() => SquadMember(
      uid: myUid, role: SquadRole.member, joinedAt: DateTime.now());

  Widget _buildRequestsBtn(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: repo.watchJoinRequests(squadId),
      builder: (_, snap) {
        final count = snap.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return ElevatedButton.icon(
          onPressed: () =>
              _showJoinRequests(context, snap.data ?? []),
          icon: const Icon(Icons.person_add_outlined),
          label: Text('$count Join Request${count > 1 ? 's' : ''}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  void _showMemberActions(
      BuildContext context, SquadMember member, SquadRole myRole) {
    if (member.uid == myUid) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: Text(member.role.badge,
                  style: const TextStyle(fontSize: 22)),
              title: Text(member.displayName ?? 'Member',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${member.role.label} · Lv.${member.level} · ${member.xp} XP'),
            ),
            const Divider(),
            if (myRole.canPromote && member.role.index > 0)
              ListTile(
                leading: const Icon(Icons.arrow_upward,
                    color: Color(0xFF7B61FF)),
                title: const Text('Promote'),
                onTap: () async {
                  Navigator.pop(context);
                  await repo.changeRole(squadId, member.uid,
                      SquadRole.values[member.role.index - 1]);
                },
              ),
            if (myRole.canKickMembers)
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text('Kick',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await repo.kickMember(squadId, member.uid);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showJoinRequests(
      BuildContext context, List<Map<String, dynamic>> requests) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Join Requests',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 8),
            ...requests.map((r) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _primary,
                    child: Text(
                      (r['displayName'] as String? ?? '?')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(r['displayName'] ?? 'Unknown'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await repo.acceptJoinRequest(squadId, r['uid']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Accept'),
                  ),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Squad?'),
        content: const Text('You will lose your role and contributions.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.leaveSquad(squadId);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

// ─── Daily Challenge Card ─────────────────────────────────────────────────────
class _DailyChallengeCard extends StatelessWidget {
  final String squadId;
  final SquadRepository repo;
  final int memberCount;
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  const _DailyChallengeCard(
      {required this.squadId,
      required this.repo,
      required this.memberCount});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MicroChallenge?>(
      stream: repo.watchTodayChallenge(squadId),
      builder: (ctx, snap) {
        final challenge = snap.data;

        if (challenge == null) {
          return GestureDetector(
            onTap: () => repo.createDailyChallenge(squadId),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No challenge today yet',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Tap to generate today\'s challenge',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.add_circle_outline, color: Color(0xFF7B61FF)),
                ],
              ),
            ),
          );
        }

        final done = challenge.completedBy.length;
        final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final alreadyDone = challenge.completedBy.contains(myUid);
        final pct = memberCount > 0 ? done / memberCount : 0.0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary.withOpacity(0.06), _accent.withOpacity(0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  const Text(
                    "Today's Challenge",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF4C4D7B)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🪙 ${challenge.coinReward}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                challenge.title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_accent),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$done / $memberCount',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: alreadyDone || challenge.status != 'active'
                      ? null
                      : () async {
                          await repo.markChallengeComplete(
                              squadId, challenge.id, memberCount);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Challenge marked complete! +XP'),
                                backgroundColor: Color(0xFF4C4D7B),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: alreadyDone ? Colors.grey.shade300 : _primary,
                    foregroundColor:
                        alreadyDone ? Colors.grey.shade600 : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    alreadyDone
                        ? '✅ Done!'
                        : challenge.status == 'completed'
                            ? '🎉 Squad Completed!'
                            : "I'm In — Mark Complete",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Health Score Card ────────────────────────────────────────────────────────
class _HealthCard extends StatelessWidget {
  final Squad? squad;
  final int computedScore;
  const _HealthCard({this.squad, required this.computedScore});

  @override
  Widget build(BuildContext context) {
    final score = squad?.healthScore ?? computedScore;
    final color = score >= 80
        ? const Color(0xFF2E7D32)
        : score >= 60
            ? const Color(0xFFEF6C00)
            : const Color(0xFFE53935);
    final bgColor = score >= 80
        ? const Color(0xFF2E7D32).withOpacity(0.08)
        : score >= 60
            ? const Color(0xFFEF6C00).withOpacity(0.08)
            : const Color(0xFFE53935).withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('❤️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text(
                'Squad Health',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1A1A2E)),
              ),
              const Spacer(),
              Text(
                '$score / 100',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score >= 80
                ? '🔥 Squad is thriving!'
                : score >= 60
                    ? '⚠️ Could be more active'
                    : '🚨 Squad needs your attention!',
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Feature Grid ─────────────────────────────────────────────────────────────
class _FeatureGrid extends StatelessWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  final SquadRole myRole;
  final Squad? squad;
  static const Color _primary = Color(0xFF4C4D7B);

  const _FeatureGrid({
    required this.squadId,
    required this.uid,
    required this.repo,
    required this.myRole,
    required this.squad,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _FItem('📅', 'Deadlines', const Color(0xFFD32F2F), () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeadlineRadarScreen(squadId: squadId, uid: uid, repo: repo),
        ),
      )),
      _FItem('📝', 'Notes Wiki', const Color(0xFF1565C0), () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SquadNotesScreen(squadId: squadId, uid: uid, repo: repo),
        ),
      )),
      _FItem('🔥', 'Heatmap', const Color(0xFF2E7D32), () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HeatmapWallScreen(squadId: squadId, repo: repo),
        ),
      )),
      _FItem('📦', 'Resources', const Color(0xFF6A1B9A), () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResourceVaultScreen(squadId: squadId, uid: uid, repo: repo),
        ),
      )),
      if (myRole.canActivateExamPrep)
        _FItem('📖', 'Exam Prep', const Color(0xFFE65100), () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamPrepScreen(
              squadId: squadId, uid: uid, repo: repo, squad: squad),
          ),
        )),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Squad Tools',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 8),
        Row(
          children: items
              .map((i) => Expanded(
                    child: GestureDetector(
                      onTap: i.onTap,
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: i.color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: i.color.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Text(i.emoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 4),
                            Text(
                              i.label,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: i.color),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _FItem {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _FItem(this.emoji, this.label, this.color, this.onTap);
}

// ─── Member Card ─────────────────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final SquadMember member;
  final bool isMe;
  final SquadRole myRole;
  final VoidCallback onTap;
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  const _MemberCard({
    required this.member,
    required this.isMe,
    required this.myRole,
    required this.onTap,
  });

  Color _levelColor(int level) {
    if (level >= 9) return const Color(0xFF7F77DD);
    if (level >= 6) return const Color(0xFFD85A30);
    if (level >= 3) return const Color(0xFF1D9E75);
    return const Color(0xFF888780);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isMe
                        ? [_accent, _primary]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                  ),
                  border: isMe
                      ? Border.all(color: _accent, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: member.photoUrl != null
                    ? ClipOval(
                        child: Image.network(member.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _initial()))
                    : _initial(),
              ),
              // Role badge
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3)
                    ],
                  ),
                  child: Center(
                    child: Text(member.role.badge,
                        style: const TextStyle(fontSize: 9)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            member.displayName?.split(' ').first ?? 'Member',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Level pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: _levelColor(member.level).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lv.${member.level}',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _levelColor(member.level)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initial() => Center(
        child: Text(
          (member.displayName?.isNotEmpty == true
                  ? member.displayName![0]
                  : '?')
              .toUpperCase(),
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
}
