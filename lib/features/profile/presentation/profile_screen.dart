import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_bloc.dart';
import '../../../core/models/app_user.dart';
import '../../../core/services/theme_service.dart';
import '../data/profile_repository.dart';
import '../models/user_profile_model.dart';
import '../../friends/models/friend_model.dart';
import '../../friends/data/friends_repository.dart';
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
  final _friendsRepo = FriendsRepository();
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
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
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
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
                                  color: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
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
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.bio,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
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
                    StreamBuilder<int>(
                      stream: _friendsRepo.watchFriendsCount(widget.user.uid),
                      builder: (ctx, snap) {
                        if (snap.hasError) return _StatItem('Friends', '!', '👥');
                        return _StatItem('Friends', (snap.data ?? 0).toString(), '👥');
                      },
                    ),
                    _StatItem(
                      'Squads',
                      profile.squadIds.length.toString(),
                      '⚔️',
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Divider(
                  color: isDark ? Colors.grey.shade800 : null,
                ),
                const SizedBox(height: 16),

                // Badges section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                profile.badges.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "No badges earned yet. Keep going!",
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.black87,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 110,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: profile.badges.length,
                          itemBuilder: (c, i) =>
                              _BadgeCard(badgeId: profile.badges[i]),
                        ),
                      ),

                const SizedBox(height: 24),

                // Chart section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Points History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _PointsChart(uid: widget.user.uid),

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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : null,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final themeNotifier = context.read<ThemeNotifier>();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: isDark ? Colors.amber : Colors.grey.shade700,
              ),
              title: Text(
                'Dark mode',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              value: isDark,
              activeColor: _accent,
              onChanged: (_) {
                themeNotifier.toggle();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.person,
                color: isDark ? Colors.white70 : null,
              ),
              title: Text(
                'Edit profile info',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {}, // placeholder
            ),
            Divider(color: isDark ? Colors.grey.shade800 : null),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                showDialog(
                  context: ctx,
                  builder: (c) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF2A2A2A) : null,
                    title: Text(
                      'Logout?',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to log out?',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade300 : Colors.black87,
                      ),
                    ),
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
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
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
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String badgeId;
  const _BadgeCard({required this.badgeId});

  // Maps badge IDs to their icon emoji and display name.
  // Must match the `id` values in _catalog inside badge_store_screen.dart.
  static const _badgeInfo = <String, Map<String, String>>{
    'badge_early_bird':   {'icon': '🌅', 'label': 'Early Bird'},
    'badge_night_owl':    {'icon': '🦉', 'label': 'Night Owl'},
    'badge_focus_master': {'icon': '🧘', 'label': 'Focus Master'},
    'badge_1_percent':    {'icon': '💎', 'label': 'Top 1%'},
    'badge_grinder':      {'icon': '⚙️', 'label': 'Grinder'},
    'badge_scholar':      {'icon': '🎓', 'label': 'Scholar'},
    // Legacy / earned outside store
    'focus_master':       {'icon': '🏆', 'label': 'Focus Master'},
    'streak_7':           {'icon': '🔥', 'label': '7-Day Streak'},
    'streak_30':          {'icon': '🌟', 'label': '30-Day Streak'},
    'squad_leader':       {'icon': '👑', 'label': 'Squad Leader'},
    'night_owl':          {'icon': '🦉', 'label': 'Night Owl'},
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = _badgeInfo[badgeId];
    final icon  = info?['icon']  ?? '🎖️';
    final label = info?['label'] ?? badgeId;

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2518) : const Color(0xFFFFF0C0),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.amber.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.amber.shade200 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsChart extends StatelessWidget {
  final String uid;

  const _PointsChart({required this.uid});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<Map<DateTime, int>>(
      stream: ProfileRepository().watchActivityLog(uid),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        }
        
        final log = snap.data!;
        if (log.isEmpty) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'No points history yet!',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.black87,
                ),
              ),
            ),
          );
        }

        // Sort keys explicitly
        final sortedDates = log.keys.toList()..sort();
        
        final List<FlSpot> spots = [];
        double maxPoints = 0;
        
        for (int i = 0; i < sortedDates.length; i++) {
          final pts = log[sortedDates[i]]!.toDouble();
          if (pts > maxPoints) maxPoints = pts;
          spots.add(FlSpot(i.toDouble(), pts));
        }

        // If only 1 data point, add a dummy initial 0 point so the line renders
        if (spots.length == 1) {
          spots.insert(0, FlSpot(-1, 0));
        }

        return Container(
          height: 200,
          padding: const EdgeInsets.only(right: 24, left: 8, top: 24, bottom: 12),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                    reservedSize: 36,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: spots.length == 2 && spots[0].x == -1 ? -1 : 0,
              maxX: (spots.length - 1).toDouble(),
              minY: 0,
              maxY: maxPoints < 10 ? 10 : maxPoints + (maxPoints * 0.2),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF7B61FF),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF7B61FF).withOpacity(isDark ? 0.25 : 0.15),
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
