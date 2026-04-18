import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/auth_bloc.dart';
import '../../../core/models/app_user.dart';
import '../data/profile_repository.dart';
import '../models/user_profile_model.dart';
import '../../friends/models/friend_model.dart';
import 'package:fl_chart/fl_chart.dart'; // We could use fl_chart or manually draw a heatmap grid.
// For a github style heatmap grid, building a manual widget is best for a true heatmap grid if no external lib is provided. We'll build a simple grid.

class ProfileScreen extends StatefulWidget {
  final AppUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileRepo = ProfileRepository();
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: StreamBuilder<UserProfile>(
        stream: _profileRepo.watchProfile(widget.user.uid),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snap.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // Avatar & Info
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: _primary.withOpacity(0.1),
                            backgroundImage: profile.photoUrl != null
                                ? NetworkImage(profile.photoUrl!)
                                : null,
                            child: profile.photoUrl == null
                                ? Text(
                                    profile.displayName[0],
                                    style: const TextStyle(fontSize: 40),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _getStatusColor(profile.status),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.bio,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Status segmented chip
                      _StatusSelector(
                        currentStatus: profile.status,
                        onStatusChanged: (s) => _profileRepo.updateStatus(s),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem('Points', profile.points.toString(), '🔥'),
                    _StatItem('Friends', profile.friendsCount.toString(), '👥'),
                    _StatItem(
                      'Squads',
                      profile.squadIds.length.toString(),
                      '⚔️',
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Badges section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Achievements',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                profile.badges.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("No badges earned yet. Keep going!"),
                      )
                    : SizedBox(
                        height: 110,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: profile.badges.length,
                          itemBuilder: (c, i) =>
                              _BadgeCard(name: profile.badges[i]),
                        ),
                      ),

                const SizedBox(height: 24),

                // Heatmap Map section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Activity Heatmap',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                _HeatmapGrid(uid: widget.user.uid),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme settings'),
            onTap: () {}, // placeholder
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit profile info'),
            onTap: () {}, // placeholder
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: ctx,
                builder: (c) => AlertDialog(
                  title: const Text('Logout?'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(c);
                        Navigator.pop(ctx);
                        context.read<AuthBloc>().add(AuthSignOutRequested());
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return Colors.greenAccent;
      case UserStatus.idle:
        return Colors.amber;
      case UserStatus.invisible:
        return Colors.grey;
    }
  }
}

class _StatusSelector extends StatelessWidget {
  final UserStatus currentStatus;
  final Function(UserStatus) onStatusChanged;

  static const Color _primary = Color(0xFF4C4D7B);

  const _StatusSelector({
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: UserStatus.values.map((s) {
          final isSelected = s == currentStatus;
          return GestureDetector(
            onTap: () => onStatusChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                s.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String name;
  const _BadgeCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0C0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final String uid;

  const _HeatmapGrid({required this.uid});

  @override
  Widget build(BuildContext context) {
    // 12 weeks * 7 days grid
    return StreamBuilder<Map<DateTime, int>>(
      stream: ProfileRepository().watchActivityLog(uid),
      builder: (ctx, snap) {
        final log = snap.data ?? {};

        // Build the blocks representing past 84 days
        final today = DateTime.now();
        final startDate = today.subtract(const Duration(days: 83));

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(12, (colIndex) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: List.generate(7, (rowIndex) {
                    final offsetDays = (colIndex * 7) + rowIndex;
                    final date = startDate.add(Duration(days: offsetDays));

                    // Normalize to check matching
                    final DateKey = DateTime(date.year, date.month, date.day);
                    int pts = 0;
                    log.forEach((k, v) {
                      if (k.year == DateKey.year &&
                          k.month == DateKey.month &&
                          k.day == DateKey.day) {
                        pts += v;
                      }
                    });

                    return Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: _getHeatColor(pts),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Color _getHeatColor(int points) {
    if (points == 0) return Colors.grey.shade200;
    if (points < 5) return Colors.purple.shade100;
    if (points < 10) return Colors.purple.shade300;
    if (points < 20) return Colors.purple;
    return Colors.purple.shade900;
  }
}

