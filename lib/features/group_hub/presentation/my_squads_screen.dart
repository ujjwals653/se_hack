import 'package:flutter/material.dart';
import 'package:se_hack/features/friends/data/friends_repository.dart';
import 'package:se_hack/features/group_hub/presentation/friend_chat_screen.dart';
import '../../friends/models/friend_model.dart';
import '../data/squad_repository.dart';
import '../models/squad_model.dart';
import 'squad_home_screen.dart';
import 'squad_discovery_screen.dart';
import 'create_squad_screen.dart';

class MySquadsScreen extends StatefulWidget {
  final List<String> squadIds;
  final String uid;
  final SquadRepository repo;

  const MySquadsScreen({
    super.key,
    required this.squadIds,
    required this.uid,
    required this.repo,
  });

  @override
  State<MySquadsScreen> createState() => _MySquadsScreenState();
}

class _MySquadsScreenState extends State<MySquadsScreen> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  int _selectedTab = 0; // 0: All, 1: Friends, 2: Squads
  final _friendsRepo = FriendsRepository();

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
                      // Show Friend Requests Badge logic here
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _friendsRepo.watchFriendRequests(),
                        builder: (ctx, snap) {
                          final count = snap.data?.length ?? 0;
                          if (count == 0)
                            return _headerIcon(
                              Icons.person_add_outlined,
                              _showSearchBottomSheet,
                            );
                          return Stack(
                            children: [
                              _headerIcon(
                                Icons.person_add_outlined,
                                _showSearchBottomSheet,
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      _headerIcon(
                        Icons.more_vert,
                        () => _showMoreMenu(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Tabs row
                  Row(
                    children: [
                      _TabChip(
                        label: 'All',
                        selected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'Friends',
                        selected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'Squads',
                        selected: _selectedTab == 2,
                        onTap: () => setState(() => _selectedTab = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // ── List Area ──
            Expanded(
              child: RefreshIndicator(
                color: _accent,
                onRefresh: () async {
                  // The streams update automatically, so we just provide the visual
                  // feedback of refreshing as requested
                  await Future.delayed(const Duration(seconds: 1));
                  setState(() {});
                },
                child: Container(
                  color: Colors.white,
                  child: StreamBuilder<List<Friend>>(
                    stream: _friendsRepo.watchFriends(),
                    builder: (ctx, friendsSnap) {
                      final friends = friendsSnap.data ?? [];
                      return StreamBuilder<List<Squad>>(
                        stream: widget.repo.watchMySquads(widget.squadIds),
                        builder: (ctx, squadsSnap) {
                          final squads = squadsSnap.data ?? [];

                          if (_selectedTab == 1) {
                            return _buildFriendsList(friends);
                          } else if (_selectedTab == 2) {
                            return _buildSquadsList(squads);
                          } else {
                            return _buildAllList(friends, squads);
                          }
                        },
                      );
                    },
                  ),
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

  Widget _buildFriendsList(List<Friend> friends) {
    if (friends.isEmpty)
      return const Center(child: Text("No friends yet. Search and add some!"));
    final sorted = List<Friend>.from(friends)
      ..sort((a, b) {
        final t1 = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final t2 = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return t2.compareTo(t1);
      });
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _FriendListTile(friend: sorted[i]),
    );
  }

  Widget _buildSquadsList(List<Squad> squads) {
    if (squads.isEmpty) return const SizedBox.shrink();
    final sorted = List<Squad>.from(squads)
      ..sort((a, b) {
        final t1 = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final t2 = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return t2.compareTo(t1);
      });
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) {
        final squad = sorted[i];
        return _SquadListTile(
          squad: squad,
          squadId: squad.id,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SquadHomeScreen(squadId: squad.id, uid: widget.uid),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllList(List<Friend> friends, List<Squad> squads) {
    if (friends.isEmpty && squads.isEmpty)
      return const Center(child: Text("Nothing here yet."));
    final List<dynamic> allItems = [...friends, ...squads];
    allItems.sort((a, b) {
      final t1 = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final t2 = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return t2.compareTo(t1);
    });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: allItems.length,
      itemBuilder: (_, i) {
        final item = allItems[i];
        if (item is Friend) {
          return _FriendListTile(friend: item);
        } else if (item is Squad) {
          return _SquadListTile(
            squad: item,
            squadId: item.id,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SquadHomeScreen(squadId: item.id, uid: widget.uid),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
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

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _SearchUsersSheet(),
      ),
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
              leading: Icon(Icons.person_add, color: _primary),
              title: const Text('Add Friends'),
              onTap: () {
                Navigator.pop(context);
                _showSearchBottomSheet();
              },
            ),
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

// ── Search Users Sheet ───────────────────────────────────────────────────────
class _SearchUsersSheet extends StatefulWidget {
  const _SearchUsersSheet();

  @override
  State<_SearchUsersSheet> createState() => _SearchUsersSheetState();
}

class _SearchUsersSheetState extends State<_SearchUsersSheet> {
  final _friendsRepo = FriendsRepository();
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  void _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    final res = await _friendsRepo.searchUsersByName(q);
    setState(() {
      _results = res;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add Friends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Friend Requests Section
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _friendsRepo.watchFriendRequests(),
            builder: (ctx, snap) {
              final reqs = snap.data ?? [];
              if (reqs.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Requests',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B61FF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...reqs.map(
                    (r) => ListTile(
                      leading: CircleAvatar(child: Text(r['displayName'][0])),
                      title: Text(r['displayName']),
                      trailing: ElevatedButton(
                        onPressed: () =>
                            _friendsRepo.acceptFriendRequest(r['uid']),
                        child: const Text('Accept'),
                      ),
                    ),
                  ),
                  const Divider(),
                ],
              );
            },
          ),

          // Search Bar
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: 'Search by exact name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _search,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 16),
          if (_searching) const CircularProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final usr = _results[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text((usr['displayName'] as String)[0]),
                  ),
                  title: Text(usr['displayName']),
                  trailing: OutlinedButton(
                    onPressed: () {
                      _friendsRepo.sendFriendRequest(usr['uid']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request Sent!')),
                      );
                    },
                    child: const Text('Add'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Friend List Tile ─────────────────────────────────────────────────────────
class _FriendListTile extends StatelessWidget {
  final Friend friend;

  static const Color _primary = Color(0xFF4C4D7B);

  const _FriendListTile({required this.friend});

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0 && now.day == date.day) {
      return "${date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    } else if (diff.inDays < 7 && now.weekday != date.weekday) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else {
      return "${date.day}/${date.month}";
    }
  }

  Color _getStatusColor() {
    switch (friend.status) {
      case UserStatus.online:
        return Colors.greenAccent;
      case UserStatus.idle:
        return Colors.amber;
      case UserStatus.invisible:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FriendChatScreen(friend: friend)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _primary.withOpacity(0.1),
                  backgroundImage: friend.photoUrl != null
                      ? NetworkImage(friend.photoUrl!)
                      : null,
                  child: friend.photoUrl == null
                      ? Text(
                          friend.displayName[0],
                          style: const TextStyle(color: _primary, fontSize: 20),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.lastMessage ?? 'Tap to chat',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (friend.lastMessageTime != null)
              Text(
                _formatTime(friend.lastMessageTime!),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
          ],
        ),
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

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0 && now.day == date.day) {
      return "${date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    } else if (diff.inDays < 7 && now.weekday != date.weekday) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else {
      return "${date.day}/${date.month}";
    }
  }

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
                    squad.lastMessage ?? squad.tagline,
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
            // Members pill or Time
            if (squad.lastMessageTime != null)
              Text(
                _formatTime(squad.lastMessageTime!),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group,
                      size: 12,
                      color: _primary.withOpacity(0.6),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${squad.memberCount}',
                      style: const TextStyle(
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
