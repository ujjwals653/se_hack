import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/cognitive_debt_service.dart';
import 'leaderboard_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({Key? key}) : super(key: key);

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Scroll wheel controllers
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;

  int _selectedHours = 0;
  int _selectedMinutes = 30;

  @override
  void initState() {
    super.initState();
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController = FixedExtentScrollController(initialItem: _selectedMinutes);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _pulseController.reverse();
        if (status == AnimationStatus.dismissed) _pulseController.forward();
      });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.watch<FocusService>();

    // Drive animations
    if (fs.currentState == FocusState.focusing && !fs.showPenaltyAnimation) {
      if (!_pulseController.isAnimating) _pulseController.forward();
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
    if (fs.showPenaltyAnimation && !_shakeController.isAnimating) {
      _shakeController.forward(from: 0.0);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4C4D7B),
        foregroundColor: Colors.white,
        title: const Text('Focus Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            tooltip: 'Leaderboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildBody(fs),
    );
  }

  Widget _buildBody(FocusService fs) {
    switch (fs.currentState) {
      case FocusState.notStarted:
        return _buildSetupView(fs);
      case FocusState.focusing:
      case FocusState.onBreak:
        return _buildActiveView(fs);
      case FocusState.completed:
        return _buildCompletedView(fs);
    }
  }

  // ===== SETUP VIEW (Scroll Picker) =====
  Widget _buildSetupView(FocusService fs) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          const Icon(Icons.self_improvement_rounded, size: 60, color: Color(0xFF4C4D7B)),
          const SizedBox(height: 16),
          const Text(
            'Set Your Focus Duration',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stay focused, earn coins!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Scroll wheel picker
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Labels
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Hours', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                    Text('Minutes', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: Row(
                    children: [
                      // Hours wheel
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _hoursController,
                          itemExtent: 50,
                          perspective: 0.003,
                          diameterRatio: 1.5,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() => _selectedHours = index);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 6, // 0-5 hours
                            builder: (context, index) {
                              final isSelected = index == _selectedHours;
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: isSelected ? 40 : 24,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
                                    color: isSelected ? const Color(0xFF4C4D7B) : Colors.grey.shade400,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const Text(':', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF4C4D7B))),
                      // Minutes wheel
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _minutesController,
                          itemExtent: 50,
                          perspective: 0.003,
                          diameterRatio: 1.5,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() => _selectedMinutes = index);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 60,
                            builder: (context, index) {
                              final isSelected = index == _selectedMinutes;
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: isSelected ? 40 : 24,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
                                    color: isSelected ? const Color(0xFF4C4D7B) : Colors.grey.shade400,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              final totalMinutes = (_selectedHours * 60) + _selectedMinutes;
              if (totalMinutes < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least 1 minute')),
                );
                return;
              }
              fs.startFocusSession(context, totalMinutes);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C4D7B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 6,
              shadowColor: const Color(0xFF4C4D7B).withOpacity(0.4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 24),
                SizedBox(width: 8),
                Text('START FOCUS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          _buildInstructionsCard(),
        ],
      ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'How Focus Mode Works',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Stay inside this app while the timer runs to earn Focus Coins.\n'
            '• A break is unlocked after 30 minutes of continuous focus.\n'
            '• PENALTY: Using distracting external apps (like Instagram, TikTok, YouTube) will shake the screen and instantly deduct 10 coins!\n'
            '• Coins are added to your lifetime total when the session ends.',
            style: TextStyle(fontSize: 13, color: Colors.blue.shade800, height: 1.5),
          ),
        ],
      ),

    );
  }

  // ===== ACTIVE VIEW (Timer + Penalty) =====
  Widget _buildActiveView(FocusService fs) {
    final isPenalty = fs.showPenaltyAnimation;
    final isOnBreak = fs.currentState == FocusState.onBreak;

    final remaining = isOnBreak
        ? fs.breakSecondsRemaining
        : (fs.targetSeconds - fs.elapsedSeconds).clamp(0, fs.targetSeconds);
    final h = remaining ~/ 3600;
    final m = (remaining % 3600) ~/ 60;
    final s = remaining % 60;

    final progress = fs.targetSeconds > 0
        ? (fs.elapsedSeconds / fs.targetSeconds).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Status badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isPenalty
                    ? Colors.red.shade50
                    : (isOnBreak ? Colors.blue.shade50 : Colors.green.shade50),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPenalty
                      ? Colors.redAccent
                      : (isOnBreak ? Colors.blueAccent : Colors.green),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPenalty ? Icons.warning_rounded
                        : (isOnBreak ? Icons.coffee_rounded : Icons.eco_rounded),
                    color: isPenalty ? Colors.redAccent
                        : (isOnBreak ? Colors.blueAccent : Colors.green),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPenalty ? 'DISTRACTED!'
                        : (isOnBreak ? 'BREAK TIME' : 'FOCUSING'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPenalty ? Colors.redAccent
                          : (isOnBreak ? Colors.blueAccent : Colors.green),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Circular progress + timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: isOnBreak ? (fs.breakSecondsRemaining / 300.0) : progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      isPenalty ? Colors.redAccent
                          : (isOnBreak ? Colors.blueAccent : const Color(0xFF4C4D7B)),
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Timer display
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildTimeDigit(h.toString().padLeft(2, '0')),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(' : ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4C4D7B))),
                          ),
                          _buildTimeDigit(m.toString().padLeft(2, '0')),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(' : ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4C4D7B))),
                          ),
                          _buildTimeDigit(s.toString().padLeft(2, '0')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isOnBreak ? 'BREAK' : 'REMAINING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Session points
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    fs.sessionPoints.toString(),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A)),
                  ),
                  const SizedBox(width: 4),
                  const Text('pts', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),

            // Penalty message
            if (isPenalty && fs.lastPenaltyMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      fs.lastPenaltyMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showGiveUpDialog(context, fs),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('GIVE UP'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: fs.isBreakAllowed ? () => fs.takeBreak() : null,
                  icon: const Icon(Icons.coffee_rounded),
                  label: const Text('TAKE BREAK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            if (!fs.isBreakAllowed && !isOnBreak)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Break available after 30 mins of focus',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDigit(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: Color(0xFF2D2D3A),
        fontFamily: 'RobotoMono',
      ),
    );
  }

  // ===== COMPLETED VIEW =====
  Widget _buildCompletedView(FocusService fs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade50,
            ),
            child: Icon(Icons.check_circle_rounded, size: 60, color: Colors.green.shade600),
          ),
          const SizedBox(height: 24),
          const Text(
            'Session Complete!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 32),
                const SizedBox(width: 8),
                Text(
                  '+' + fs.sessionPoints.toString(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4C4D7B),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('coins', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              fs.resetSession();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C4D7B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('BACK TO HOME', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGiveUpDialog(BuildContext context, FocusService fs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Give Up?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('You will lose all points earned in this session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Going', style: TextStyle(color: Colors.green)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              fs.giveUp();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Give Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
