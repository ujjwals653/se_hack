import 'package:flutter/material.dart';
import '../data/squad_repository.dart';
import '../models/squad_model.dart';
import 'squad_chat_screen.dart';
import 'squad_kanban_screen.dart';
import 'deadline_radar_screen.dart';
import 'squad_notes_screen.dart';
import 'resource_vault_screen.dart';
import 'user_profile_view_screen.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/models/friend_model.dart';

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

  // 5 tabs: Chat, Taskboard, Deadlines, Notes Wiki, Resources
  static const _tabLabels = [
    ('💬', 'Chat'),
    ('📋', 'Taskboard'),
    ('📅', 'Deadlines'),
    ('📝', 'Notes Wiki'),
    ('📦', 'Resources'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabLabels.length, vsync: this);
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
                // ── App Bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        squad?.badge ?? '⚡',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              squad?.name ?? '…',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              squad?.tagline ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (squad?.examPrepActive == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.deepOrange.withOpacity(0.5),
                            ),
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
                      const SizedBox(width: 6),
                      // Members count pill
                      GestureDetector(
                        onTap: () {
                          if (squad != null) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              backgroundColor: Colors.white,
                              builder: (ctx) => FractionallySizedBox(
                                heightFactor: 0.85,
                                child: Scaffold(
                                  backgroundColor: Colors.transparent,
                                  body: Column(
                                    children: [
                                      const SizedBox(height: 12),
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: _MembersTab(
                                          squadId: widget.squadId,
                                          myUid: widget.uid,
                                          repo: _repo,
                                          squad: squad,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.group,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${squad?.memberCount ?? '…'}/${squad?.maxMembers ?? 15}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Horizontally Scrollable Tab Bar ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: _primary,
                    unselectedLabelColor: Colors.white.withOpacity(0.7),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 13),
                    dividerColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    tabs: _tabLabels
                        .map(
                          (t) => Tab(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    t.$1,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(t.$2),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

                // ── Tab Content ──────────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(0),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        // 0 – Chat (full screen pushed, but embedded here too)
                        _EmbeddedChat(
                          squadId: widget.squadId,
                          uid: widget.uid,
                          repo: _repo,
                          squadName: squad?.name ?? 'Squad Chat',
                        ),
                        // 1 – Taskboard (Kanban)
                        SquadKanbanScreen(
                          squadId: widget.squadId,
                          uid: widget.uid,
                          repo: _repo,
                        ),
                        // 2 – Deadlines
                        DeadlineRadarScreen(
                          squadId: widget.squadId,
                          uid: widget.uid,
                          repo: _repo,
                        ),
                        // 3 – Notes Wiki
                        SquadNotesScreen(
                          squadId: widget.squadId,
                          uid: widget.uid,
                          repo: _repo,
                        ),
                        // 4 – Resources
                        ResourceVaultScreen(
                          squadId: widget.squadId,
                          uid: widget.uid,
                          repo: _repo,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Embedded Chat Wrapper ───────────────────────────────────────────────────
/// Wraps SquadChatScreen but removes its own Scaffold so it lives inside the tab.
class _EmbeddedChat extends StatelessWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  final String squadName;
  const _EmbeddedChat({
    required this.squadId,
    required this.uid,
    required this.repo,
    required this.squadName,
  });

  @override
  Widget build(BuildContext context) {
    return SquadChatScreen(
      squadId: squadId,
      uid: uid,
      repo: repo,
      squadName: squadName,
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
            child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
          );
        }
        final members = snap.data!;
        final myMember = members.firstWhere(
          (m) => m.uid == myUid,
          orElse: () => members.isNotEmpty ? members.first : _emptyMember(),
        );
        final myRole = myMember.role;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Member count header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Squad Members',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Row(
                  children: [
                     if (myRole.canAcceptRequests)
                       IconButton(
                          icon: Icon(Icons.person_add_alt_1, color: _accent),
                          tooltip: 'Invite friend to squad',
                          onPressed: () => _showInviteToSquad(context, members),
                       ),
                     IconButton(
                        icon: Icon(Icons.search, color: _primary),
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the Search in the main Hub screen to add new people.')));
                        },
                     ),
                     Container(
                       padding: const EdgeInsets.symmetric(
                         horizontal: 10,
                         vertical: 4,
                       ),
                       decoration: BoxDecoration(
                         color: _primary.withOpacity(0.08),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Text(
                         '${members.length} / ${squad?.maxMembers ?? 15}',
                         style: TextStyle(
                           color: _primary,
                           fontWeight: FontWeight.bold,
                           fontSize: 13,
                         ),
                       ),
                     ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Role legend
            Wrap(
              spacing: 12,
              children: SquadRole.values
                  .map(
                    (r) => Chip(
                      avatar: Text(
                        r.badge,
                        style: const TextStyle(fontSize: 13),
                      ),
                      label: Text(
                        r.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.grey.shade100,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 14),

            // Member list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (_, i) => _MemberListTile(
                member: members[i],
                isMe: members[i].uid == myUid,
                myRole: myRole,
                onTap: () {
                   if (members[i].uid != myUid) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileViewScreen(uid: members[i].uid)));
                   }
                },
              ),
            ),

            const SizedBox(height: 20),

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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  SquadMember _emptyMember() =>
      SquadMember(uid: myUid, role: SquadRole.member, joinedAt: DateTime.now());

  void _showInviteToSquad(BuildContext context, List<SquadMember> currentMembers) {
    final friendsRepo = FriendsRepository();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Invite Friend to Squad',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<Friend>>(
                stream: friendsRepo.watchFriends(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF7B61FF)));
                  }
                  final currentMemberUids = currentMembers.map((m) => m.uid).toSet();
                  final friends = snap.data!.where((f) => !currentMemberUids.contains(f.uid)).toList();

                  if (friends.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No friends to invite',
                            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add friends first from the Group Hub.',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: friends.length,
                    itemBuilder: (_, i) {
                      final f = friends[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _primary.withOpacity(0.1),
                          backgroundImage: f.photoUrl != null ? NetworkImage(f.photoUrl!) : null,
                          child: f.photoUrl == null
                              ? Text(f.displayName[0], style: TextStyle(color: _primary, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(f.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          f.status == UserStatus.online ? '🟢 Online' :
                          f.status == UserStatus.idle ? '🟡 Idle' : '⚫ Invisible',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: _InviteButton(
                          friendUid: f.uid,
                          squadId: squadId,
                          squadName: squad?.name ?? 'Squad',
                          squadBadge: squad?.badge ?? '⚔️',
                          friendsRepo: friendsRepo,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsBtn(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: repo.watchJoinRequests(squadId),
      builder: (_, snap) {
        final count = snap.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ElevatedButton.icon(
            onPressed: () => _showJoinRequests(context, snap.data ?? []),
            icon: const Icon(Icons.person_add_outlined),
            label: Text('$count Join Request${count > 1 ? 's' : ''}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMemberActions(
    BuildContext context,
    SquadMember member,
    SquadRole myRole,
  ) {
    if (member.uid == myUid) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: Text(
                member.role.badge,
                style: const TextStyle(fontSize: 22),
              ),
              title: Text(
                member.displayName ?? 'Member',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(member.role.label),
            ),
            const Divider(),
            if (myRole.canPromote && member.role.index > 1)
              ListTile(
                leading: const Icon(
                  Icons.arrow_upward,
                  color: Color(0xFF7B61FF),
                ),
                title: const Text('Promote'),
                onTap: () async {
                  Navigator.pop(context);
                  await repo.changeRole(
                    squadId,
                    member.uid,
                    SquadRole.values[member.role.index - 1],
                  );
                },
              ),
            if (myRole.canDemote &&
                member.role.index > 0 &&
                member.role.index < SquadRole.values.length - 1)
              ListTile(
                leading: const Icon(Icons.arrow_downward, color: Colors.orange),
                title: const Text('Demote'),
                onTap: () async {
                  Navigator.pop(context);
                  await repo.changeRole(
                    squadId,
                    member.uid,
                    SquadRole.values[member.role.index + 1],
                  );
                },
              ),
            if (myRole.canKickMembers)
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text('Kick', style: TextStyle(color: Colors.red)),
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
    BuildContext context,
    List<Map<String, dynamic>> requests,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Join Requests',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 8),
            ...requests.map(
              (r) => ListTile(
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.leaveSquad(squadId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

// ─── Member List Tile ────────────────────────────────────────────────────────
class _MemberListTile extends StatelessWidget {
  final SquadMember member;
  final bool isMe;
  final SquadRole myRole;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  const _MemberListTile({
    required this.member,
    required this.isMe,
    required this.myRole,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isMe
                    ? [_accent, _primary]
                    : [Colors.grey.shade300, Colors.grey.shade400],
              ),
              border: isMe ? Border.all(color: _accent, width: 2) : null,
            ),
            child: member.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      member.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initial(),
                    ),
                  )
                : _initial(),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  member.role.badge,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        member.displayName ?? 'Member',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A2E),
        ),
      ),
      subtitle: Text(
        isMe ? '${member.role.label} (You)' : member.role.label,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      trailing: isMe
          ? null
          : const Icon(Icons.more_vert, size: 20, color: Colors.grey),
    );
  }

  Widget _initial() => Center(
    child: Text(
      (member.displayName?.isNotEmpty == true ? member.displayName![0] : '?')
          .toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// ─── Invite Button ────────────────────────────────────────────────────────────
class _InviteButton extends StatefulWidget {
  final String friendUid;
  final String squadId;
  final String squadName;
  final String squadBadge;
  final FriendsRepository friendsRepo;

  const _InviteButton({
    required this.friendUid,
    required this.squadId,
    required this.squadName,
    required this.squadBadge,
    required this.friendsRepo,
  });

  @override
  State<_InviteButton> createState() => _InviteButtonState();
}

class _InviteButtonState extends State<_InviteButton> {
  static const Color _accent = Color(0xFF7B61FF);

  bool _sent = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withOpacity(0.4)),
        ),
        child: const Text(
          'Invited ✓',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: _loading ? null : _invite,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Invite',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _invite() async {
    setState(() => _loading = true);
    try {
      await widget.friendsRepo.sendSquadInvite(
        targetUid: widget.friendUid,
        squadId: widget.squadId,
        squadName: widget.squadName,
        squadBadge: widget.squadBadge,
      );
      if (mounted) setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invite: $e')),
        );
      }
    }
  }
}
