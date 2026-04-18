import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se_hack/core/models/app_user.dart';
import 'package:se_hack/features/auth/auth_bloc.dart';
import 'package:se_hack/features/calendar/bloc/calendar_bloc.dart';
import 'package:se_hack/features/calendar/presentation/calendar_screen.dart';
import 'package:se_hack/features/timetable/presentation/timetable_screen.dart';
import 'package:se_hack/features/expense/bloc/expense_cubit.dart';
import 'package:se_hack/features/expense/presentation/expense_home_screen.dart';
import 'package:se_hack/features/posts/presentation/screens/posts_screen.dart';
import 'package:se_hack/features/group_hub/presentation/hub_screen.dart';
import 'package:se_hack/features/profile/presentation/profile_screen.dart';
import 'package:se_hack/features/context_switch/presentation/focus_screen.dart'
    as se_hack_focus;
import 'package:se_hack/features/resources/screens/offline_drive_screen.dart'
    as se_hack_drive;
import 'package:se_hack/features/context_switch/domain/cognitive_debt_service.dart';
import 'package:se_hack/features/friends/data/friends_repository.dart';
import 'package:se_hack/features/attendance/domain/attendance_service.dart';
import 'package:se_hack/features/timetable/presentation/attendance_screen.dart';
import 'package:se_hack/features/rag/presentation/rag_screen.dart';

class MainHomeScreen extends StatefulWidget {
  final AppUser user;
  const MainHomeScreen({super.key, required this.user});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // FocusService is created before auth completes, so we must
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attService = context.read<AttendanceService>();
      attService.initialize(widget.user.uid);
      context.read<FocusService>().initialize(widget.user.uid, attService);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color headerColor = Color(0xFF4C4D7B);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: headerColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ── Tab content ──
            _currentIndex == 0
                ? _buildHomeTab(headerColor)
                : _currentIndex == 1
                ? const HubScreen()
                : _currentIndex == 2
                ? PostsScreen(
                    currentUid: widget.user.uid,
                    currentUserName: widget.user.displayName,
                    currentUserPhotoUrl: widget.user.photoUrl,
                  )
                : ProfileScreen(user: widget.user),

            // FLOATING FOCUS TIMER OVERLAY
            const Positioned(
              right: 20,
              bottom: 120, // Above bottom nav bar
              child: _FloatingFocusTimer(),
            ),

            // Custom Bottom Navigation Bar
            Positioned(
              left: 20,
              right: 20,
              bottom: 24, // floating slightly above bottom
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                height: 72,
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, 'Home', true),
                    _buildNavItem(1, Icons.group_outlined, 'Group Hub', false),
                    _buildNavItem(2, Icons.post_add_outlined, 'Posts', false),
                    _buildNavItem(3, Icons.person_outline, 'Profile', false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The original home dashboard content.
  Widget _buildHomeTab(Color headerColor) {
    return Column(
      children: [
        // Top Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              GestureDetector(
                onLongPress: () {
                  // Long-press avatar to sign out
                  _showSignOutDialog(context);
                },
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  backgroundImage: widget.user.photoUrl != null
                      ? NetworkImage(widget.user.photoUrl!)
                      : null,
                  child: widget.user.photoUrl == null
                      ? Text(
                          widget.user.firstName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.user.email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFF38BDF8),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.watch<FocusService>().lifetimePoints.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _NotificationBell(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Main Content Area with rounded corners
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: ListView(
              padding: const EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: 100,
              ),
              children: [
                const Text(
                  'My Favourites',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Dashboards',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Action Grid
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _buildGridItem(
                      icon: Icons.class_outlined,
                      title: 'My classes',
                      color: const Color(0xFFD0F0C0),
                      iconColor: Colors.green.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TimetableScreen(userId: widget.user.uid),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      icon: Icons.how_to_reg,
                      title: 'Attendance',
                      color: const Color(0xFFC0E8F8),
                      iconColor: Colors.blue.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendanceScreen(),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Expense tracking',
                      color: const Color(0xFFFFF0C0),
                      iconColor: Colors.orange.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => ExpenseCubit(),
                              child: const ExpenseHomeScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      icon: Icons.calendar_month_outlined,
                      title: 'Calendar',
                      color: const Color(0xFFFFD0E0),
                      iconColor: Colors.pink.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => CalendarBloc()
                                ..add(CalendarLoadRequested()),
                              child: const CalendarScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      icon: Icons.folder_open_outlined,
                      title: 'Drive',
                      color: const Color(0xFFD0D0FF),
                      iconColor: Colors.indigo.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const se_hack_drive.OfflineDriveScreen(),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      icon: Icons.center_focus_strong_outlined,
                      title: 'focus Mode',
                      color: const Color(0xFFFFD0FF),
                      iconColor: Colors.purple.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const se_hack_focus.FocusScreen(),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      icon: Icons.auto_awesome,
                      title: 'Study AI',
                      color: const Color(0xFFEDE9FE),
                      iconColor: const Color(0xFF7C3AED),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RagScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Placeholder widget for tabs not yet built.
  Widget _buildPlaceholderTab(String label) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coming soon',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: Text('Sign out as ${widget.user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C4D7B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem({
    required String date,
    required String month,
    required Color color,
    required String title,
    required String time,
    required String room,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Date Box
          Container(
            width: 54,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  month,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Timeline indicator
          Column(
            children: [
              Container(width: 2, height: 20, color: color.withOpacity(0.3)),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              Container(width: 2, height: 20, color: color.withOpacity(0.3)),
            ],
          ),
          const SizedBox(width: 12),

          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      room,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _currentIndex == index ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _currentIndex == index
                  ? const Color(0xFF4C4D7B)
                  : Colors.white70,
              size: 24,
            ),
            if (_currentIndex == index) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4C4D7B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==== NOTIFICATION BELL ====
class _NotificationBell extends StatelessWidget {
  _NotificationBell();

  final _repo = FriendsRepository();

  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _repo.watchAllNotifications(),
      builder: (ctx, snap) {
        final notifications = snap.data ?? [];
        final count = notifications.length;

        return GestureDetector(
          onTap: () => _showNotificationPanel(context),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 20,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none,
                  color: Colors.black,
                  size: 22,
                ),
                if (count > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
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

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationPanel(repo: _repo),
    );
  }
}

// ==== NOTIFICATION PANEL ====
class _NotificationPanel extends StatelessWidget {
  final FriendsRepository repo;

  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  const _NotificationPanel({required this.repo});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: repo.watchAllNotifications(),
        builder: (ctx, snap) {
          final live = snap.data ?? [];
          final isLoading =
              snap.connectionState == ConnectionState.waiting && live.isEmpty;

          return Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (live.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${live.length} new',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              // List
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7B61FF),
                        ),
                      )
                    : live.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 56,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'All caught up!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No new notifications.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: live.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (ctx, i) {
                          final n = live[i];
                          final type = n['type'] as String?;
                          if (type == 'friendRequest') {
                            return _FriendRequestTile(
                              notification: n,
                              repo: repo,
                              onAction: () => Navigator.pop(context),
                            );
                          } else if (type == 'squadInvite') {
                            return _SquadInviteTile(
                              notification: n,
                              repo: repo,
                              onAction: () => Navigator.pop(context),
                            );
                          }
                          // Unknown type — show a generic dismiss tile
                          return ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: Text(
                              n['type']?.toString() ?? 'Notification',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => repo.dismissNotification(
                                n['id'] as String? ?? '',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FriendRequestTile extends StatefulWidget {
  final Map<String, dynamic> notification;
  final FriendsRepository repo;
  final VoidCallback onAction;

  const _FriendRequestTile({
    required this.notification,
    required this.repo,
    required this.onAction,
  });

  @override
  State<_FriendRequestTile> createState() => _FriendRequestTileState();
}

class _FriendRequestTileState extends State<_FriendRequestTile> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.notification['displayName'] as String? ?? 'Someone';
    final photoUrl = widget.notification['photoUrl'] as String?;
    final uid = widget.notification['uid'] as String? ?? widget.notification['id'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: _primary.withOpacity(0.1),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' sent you a friend request'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '👥 Friend Request',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action buttons
          Column(
            children: [
              SizedBox(
                height: 32,
                width: 72,
                child: ElevatedButton(
                  onPressed: _isAccepting
                      ? null
                      : () async {
                          setState(() => _isAccepting = true);
                          await widget.repo.acceptFriendRequest(uid);
                          await Future.delayed(const Duration(seconds: 2));
                          if (mounted) {
                            setState(() => _isAccepting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$name is now your friend!')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _accent.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Accept', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 28,
                child: OutlinedButton(
                  onPressed: _isAccepting
                      ? null
                      : () async {
                          await widget.repo.declineFriendRequest(uid);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SquadInviteTile extends StatefulWidget {
  final Map<String, dynamic> notification;
  final FriendsRepository repo;
  final VoidCallback onAction;

  const _SquadInviteTile({
    required this.notification,
    required this.repo,
    required this.onAction,
  });

  @override
  State<_SquadInviteTile> createState() => _SquadInviteTileState();
}

class _SquadInviteTileState extends State<_SquadInviteTile> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final squadName = widget.notification['squadName'] as String? ?? 'a Squad';
    final squadBadge = widget.notification['squadBadge'] as String? ?? '⚔️';
    final fromName = widget.notification['fromName'] as String? ?? 'Someone';
    final squadId = widget.notification['squadId'] as String? ?? '';
    final notifId = widget.notification['id'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Squad badge avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_accent.withOpacity(0.15), _primary.withOpacity(0.1)],
              ),
            ),
            child: Center(
              child: Text(squadBadge, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: fromName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' invited you to '),
                      TextSpan(
                        text: squadName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '⚔️ Squad Invite',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              SizedBox(
                height: 32,
                width: 60,
                child: ElevatedButton(
                  onPressed: _isJoining
                      ? null
                      : () async {
                          if (squadId.isEmpty || notifId.isEmpty) return;
                          setState(() => _isJoining = true);
                          await widget.repo.acceptSquadInvite(notifId, squadId);
                          await Future.delayed(const Duration(seconds: 2));
                          if (mounted) {
                            setState(() => _isJoining = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Joined $squadName!')),
                            );
                            widget.onAction();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primary.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Join', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 28,
                child: OutlinedButton(
                  onPressed: _isJoining
                      ? null
                      : () async {
                          if (notifId.isEmpty) return;
                          await widget.repo.dismissNotification(notifId);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==== FLOATING FOCUS TIMER ====
class _FloatingFocusTimer extends StatelessWidget {
  const _FloatingFocusTimer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fs = context.watch<FocusService>();

    // Only show if focusing or on break
    if (fs.currentState == FocusState.notStarted ||
        fs.currentState == FocusState.completed) {
      return const SizedBox.shrink();
    }

    final isPenalty = fs.showPenaltyAnimation;
    final isOnBreak = fs.currentState == FocusState.onBreak;

    final remaining = isOnBreak
        ? fs.breakSecondsRemaining
        : (fs.targetSeconds - fs.elapsedSeconds).clamp(0, fs.targetSeconds);

    final h = remaining ~/ 3600;
    final m = (remaining % 3600) ~/ 60;
    final s = remaining % 60;
    final timeStr = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () {
        // Return to Focus Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const se_hack_focus.FocusScreen(),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPenalty
              ? Colors.redAccent
              : (isOnBreak ? Colors.blueAccent : const Color(0xFF4C4D7B)),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: (isPenalty ? Colors.redAccent : const Color(0xFF4C4D7B))
                  .withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPenalty
                  ? Icons.warning_rounded
                  : (isOnBreak
                        ? Icons.coffee_rounded
                        : Icons.timelapse_rounded),
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'RobotoMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
