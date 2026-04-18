import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se_hack/core/models/app_user.dart';
import 'package:se_hack/features/auth/auth_bloc.dart';
import 'package:se_hack/features/timetable/presentation/screens/bunk_analytics_wrapper.dart';
import 'package:se_hack/features/timetable/presentation/timetable_screen.dart';
import 'package:se_hack/features/expense/bloc/expense_cubit.dart';
import 'package:se_hack/features/expense/presentation/expense_home_screen.dart';
import 'package:se_hack/features/posts/presentation/screens/posts_screen.dart';
import 'package:se_hack/features/group_hub/presentation/hub_screen.dart';
import 'package:se_hack/features/context_switch/presentation/focus_screen.dart' as se_hack_focus;
import 'package:se_hack/features/context_switch/domain/cognitive_debt_service.dart';

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
    // initialize it here where the user is guaranteed to exist.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FocusService>().initialize(widget.user.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color headerColor = Color(0xFF4C4D7B);

    return Scaffold(
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
                : _buildPlaceholderTab('Profile'),

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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFF38BDF8), size: 18),
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
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                      icon: Icons.assignment_outlined,
                      title: 'Tasks',
                      color: const Color(0xFFFFD0E0),
                      iconColor: Colors.pink.shade700,
                    ),
                    _buildGridItem(
                      icon: Icons.folder_open_outlined,
                      title: 'Drive',
                      color: const Color(0xFFD0D0FF),
                      iconColor: Colors.indigo.shade700,
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
                      icon: Icons.analytics_outlined,
                      title: 'Bunk Analytics',
                      color: const Color(0xFFFFD1B3),
                      iconColor: Colors.deepOrange.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BunkAnalyticsWrapper(userId: widget.user.uid),
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

// ==== FLOATING FOCUS TIMER ====
class _FloatingFocusTimer extends StatelessWidget {
  const _FloatingFocusTimer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fs = context.watch<FocusService>();

    // Only show if focusing or on break
    if (fs.currentState == FocusState.notStarted || fs.currentState == FocusState.completed) {
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
          MaterialPageRoute(builder: (context) => const se_hack_focus.FocusScreen()),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPenalty ? Colors.redAccent : (isOnBreak ? Colors.blueAccent : const Color(0xFF4C4D7B)),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: (isPenalty ? Colors.redAccent : const Color(0xFF4C4D7B)).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPenalty ? Icons.warning_rounded : (isOnBreak ? Icons.coffee_rounded : Icons.timelapse_rounded),
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
