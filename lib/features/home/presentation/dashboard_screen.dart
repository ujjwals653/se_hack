import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:se_hack/core/models/app_user.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:se_hack/features/auth/auth_bloc.dart';

class HomeScreen extends StatelessWidget {
  final AppUser user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final String todayDate = DateFormat('dd MMMM').format(DateTime.now());
    final String todayDay = DateFormat('EEEE').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Top Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayDay,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todayDate,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: const Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onLongPress: () {
                         context.read<AuthBloc>().add(AuthSignOutRequested());
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                        backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.firstName[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7B61FF)),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Greeting
            Text(
              'Hi ${user.firstName}.',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your workspace is ready',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),

            // Featured Card (Study AI or Classes)
            GestureDetector(
              onTap: () => context.push('/rag'),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B78FF), Color(0xFF624BFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF624BFF).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Study AI', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Information Architecture',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to ask questions & study notes',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        onPressed: () => context.push('/rag'),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Monthly Preview Section (Grid)
            Text(
              'App Modules',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            
            // 2×2 Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.05,
              children: [
                _buildGridCard(
                  title: 'Timetable',
                  value: 'My Classes',
                  color: const Color(0xFF7B61FF),
                  icon: Icons.class_rounded,
                  onTap: () => context.push('/timetable'),
                ),
                _buildGridCard(
                  title: 'Attendance',
                  value: 'Details',
                  color: const Color(0xFF43E0A3),
                  icon: Icons.how_to_reg_rounded,
                  onTap: () => context.push('/attendance'),
                ),
                _buildGridCard(
                  title: 'Calendar',
                  value: 'Schedule',
                  color: const Color(0xFFFF527A),
                  icon: Icons.calendar_month_rounded,
                  onTap: () => context.push('/calendar'),
                ),
                _buildGridCard(
                  title: 'Drive',
                  value: 'Offline Hub',
                  color: const Color(0xFF3BCAE5),
                  icon: Icons.folder_rounded,
                  onTap: () => context.push('/drive'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Focus Mode
            _buildHorizontalCard(
              title: 'Focus Mode',
              subtitle: 'Block distractions, earn points',
              icon: Icons.self_improvement_rounded,
              color: const Color(0xFFCE93D8),
              onTap: () => context.push('/focus'),
            ),

            const SizedBox(height: 16),

            // Expense horizontal card since it was displaced from the grid
            _buildHorizontalCard(
              title: 'Expense Tracking',
              subtitle: 'Monitor your spending',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFFFFAB61),
              onTap: () => context.push('/expense'),
            ),

            const SizedBox(height: 140), // Padding for floating nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
