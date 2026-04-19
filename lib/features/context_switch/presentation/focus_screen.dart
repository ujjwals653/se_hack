import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/cognitive_debt_service.dart';
import 'leaderboard_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScaleAnimation;
  late Animation<double> _pulseOpacityAnimation;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _dripController;
  late AnimationController _splashController;


  // Scroll wheel controllers
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;

  final TextEditingController _goalController = TextEditingController();

  int _selectedHours = 0;
  int _selectedMinutes = 30;

  static const List<String> _quotes = [
    "Deep work is the superpower of the 21st century.",
    "Focus on being productive instead of busy.",
    "Starve your distractions, feed your focus.",
    "Great acts are made up of small deeds.",
    "The secret of your future is hidden in your daily routine.",
    "Discipline is choosing between what you want now and what you want most.",
    "Amateurs sit and wait for inspiration, the rest just go to work.",
    "Don't stop when you're tired. Stop when you're done."
  ];

  @override
  void initState() {
    super.initState();
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController = FixedExtentScrollController(initialItem: _selectedMinutes);

    // Deep Breathing Ring Animation (4s cycle)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _pulseOpacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _pulseController.addStatusListener((status) {
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

    _dripController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _dripController.dispose();
    _splashController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.watch<FocusService>();

    // Drive shake animation on penalty
    if (fs.showPenaltyAnimation && !_shakeController.isAnimating) {
      _shakeController.forward(from: 0.0);
    }

    if (fs.currentState == FocusState.completed) {
      if (!_splashController.isAnimating && !_splashController.isCompleted) {
        _splashController.forward(from: 0.0);
      }
    } else {
      _splashController.reset();
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

  // ===== SETUP VIEW =====
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Study until the ice melts down to score points.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
              ),
            ),
            const SizedBox(height: 32),

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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Hours', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                      Text('Minutes', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 140,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: _hoursController,
                            itemExtent: 50,
                            perspective: 0.003,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) => setState(() => _selectedHours = index),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 6,
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
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: _minutesController,
                            itemExtent: 50,
                            perspective: 0.003,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) => setState(() => _selectedMinutes = index),
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
            
            const SizedBox(height: 32),

            // Rules / Instructions block
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1), // softer yellow-orange
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'How it works:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• The ice melts dynamically as you focus.\n• If you switch to distracting apps (e.g. Instagram, YT), points will be penalized immediately!\n• Complete the session to claim your rewards.',
                    style: TextStyle(fontSize: 13, color: Colors.orange.shade900, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                final totalMinutes = (_selectedHours * 60) + _selectedMinutes;
                if (totalMinutes < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least 1 minute')),
                  );
                  return;
                }
                
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Set Your Goal'),
                    content: TextField(
                      controller: _goalController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Reading Chapter 5',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          fs.startFocusSession(context, totalMinutes, 'Deep Focus Session');
                        },
                        child: const Text('Skip'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C4D7B)),
                        onPressed: () {
                          final goalText = _goalController.text.trim();
                          final finalGoal = goalText.isNotEmpty ? goalText : 'Deep Focus Session';
                          Navigator.pop(ctx);
                          fs.startFocusSession(context, totalMinutes, finalGoal);
                        },
                        child: const Text('Start', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
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
          ],
        ),
      ),
    );
  }

  // ===== ACTIVE VIEW =====
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

    // Quote rotation
    final quoteIndex = (fs.elapsedSeconds ~/ 60) % _quotes.length;
    final currentQuote = _quotes[quoteIndex];

    // Pips calculation (1 pip per 5 mins = 300s)
    final totalPips = fs.targetSeconds ~/ 300;
    final earnedPips = fs.elapsedSeconds ~/ 300;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Stack(
        children: [
          // Ambient Intensity Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(const Color(0xFF4C4D7B).withOpacity(0.3)),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Top row: Goal Anchor & Streak
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            'Completing: \n${fs.currentGoal ?? 'Deep Focus Session'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C4D7B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0C0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Text(
                              '${fs.consecutiveSessions}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange.shade900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Status Badge
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

                  const SizedBox(height: 36),

                  // 🧊 Ice Melt Timer
                  AnimatedBuilder(
                    animation: _dripController,
                    builder: (context, _) {
                      return SizedBox(
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ice melt visual
                            CustomPaint(
                              size: const Size(220, 260),
                              painter: _IceMeltPainter(
                                progress: progress,
                                dripValue: _dripController.value,
                                isPenalty: isPenalty,
                              ),
                            ),
                            // Timer text overlaid on ice
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (h > 0) ...[
                                      _buildTimeDigit(h.toString().padLeft(2, '0')),
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: Text(' : ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4C4D7B))),
                                      ),
                                    ],
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
                                  isOnBreak ? 'B R E A K' : 'R E M A I N I N G',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade400,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 36),

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

                  const SizedBox(height: 36),

                  // Micro-milestone Pips
                  if (totalPips > 0)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(totalPips, (i) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < earnedPips ? const Color(0xFF4C4D7B) : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                  
                  const SizedBox(height: 24),

                  // Motivational Quote
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      '"$currentQuote"',
                      key: ValueKey<int>(quoteIndex),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Break Button
                  _buildDynamicBreakButton(fs, isOnBreak),

                  const SizedBox(height: 16),

                  // Give Up
                  TextButton(
                    onPressed: () => _showGiveUpDialog(context, fs),
                    child: const Text('Give Up', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDynamicBreakButton(FocusService fs, bool isOnBreak) {
    if (isOnBreak) {
      return Container(); // No break button while on break
    }

    final isBreakAllowed = fs.isBreakAllowed;
    // Time remaining until break is allowed, in seconds
    final waitRemainingSeconds = max(0, 1500 - fs.elapsedSeconds);
    final wMins = waitRemainingSeconds ~/ 60;
    final wSecs = waitRemainingSeconds % 60;
    final waitLabel = '${wMins.toString().padLeft(2, '0')}:${wSecs.toString().padLeft(2, '0')}';

    return ElevatedButton.icon(
      onPressed: isBreakAllowed ? () => fs.takeBreak() : null,
      icon: const Icon(Icons.coffee_rounded, size: 20),
      label: Text(
        isBreakAllowed ? 'TAKE 5 MIN BREAK' : 'Break in $waitLabel',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        disabledBackgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildTimeDigit(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 42,
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _splashController,
                  builder: (context, _) => CustomPaint(
                    size: const Size(200, 200),
                    painter: _SplashPainter(_splashController.value),
                  ),
                ),
                Icon(Icons.check_circle_rounded, size: 60, color: Colors.green.shade600),
              ],
            ),
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
        content: const Text('You will lose all points earned in this session, and your streak will reset to 0!'),
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

// ── Ice Melt Custom Painter ──────────────────────────────────────────────────
class _IceMeltPainter extends CustomPainter {
  final double progress;   // 0.0 = full ice, 1.0 = fully melted
  final double dripValue;  // 0.0–1.0 repeating drip animation
  final bool isPenalty;    // turns ice red on distraction penalty

  const _IceMeltPainter({
    required this.progress,
    required this.dripValue,
    this.isPenalty = false,
  });

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double maxIceH = size.height * 0.70;
    final double iceW = size.width * 0.62;
    final double baseY = size.height * 0.78;
    final double currentIceH = maxIceH * (1.0 - progress).clamp(0.0, 1.0);
    final double iceTopY = baseY - currentIceH;
    final double iceLeft = cx - iceW / 2;
    final double iceRight = cx + iceW / 2;

    // ── Puddle ────────────────────────────────────────────────────────────────
    final double puddleRx = _lerp(iceW * 0.22, iceW * 0.80, progress);
    final double puddleRy = _lerp(5.0, 20.0, progress);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + puddleRy * 0.5),
        width: puddleRx * 2,
        height: puddleRy * 2,
      ),
      Paint()
        ..color = (isPenalty
            ? Color.lerp(const Color(0x33FFCDD2), const Color(0x77FFCDD2), progress)!
            : Color.lerp(const Color(0x3389CFF0), const Color(0x7789CFF0), progress)!),
    );

    // ── Ice block (only if some remains) ─────────────────────────────────────
    if (currentIceH > 2) {
      final double br = _lerp(14, 50, progress);
      final iceRRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(iceLeft, iceTopY, iceRight, baseY),
        Radius.circular(br),
      );

      // Body gradient
      final Color c1 = isPenalty
          ? Color.lerp(const Color(0xFFFFCDD2), const Color(0xA0FFCDD2), progress)!
          : Color.lerp(const Color(0xFFD6F0FF), const Color(0xA0D6F0FF), progress)!;
      final Color c2 = isPenalty
          ? Color.lerp(const Color(0xFFEF9A9A), const Color(0x80EF9A9A), progress)!
          : Color.lerp(const Color(0xFF89CFF0), const Color(0x8089CFF0), progress)!;

      canvas.drawRRect(
        iceRRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c1, c2],
          ).createShader(Rect.fromLTRB(iceLeft, iceTopY, iceRight, baseY)),
      );

      // Border
      canvas.drawRRect(
        iceRRect,
        Paint()
          ..color = isPenalty
              ? Color.lerp(const Color(0xFFE57373), const Color(0x50E57373), progress)!
              : Color.lerp(const Color(0xFF55A7C8), const Color(0x5055A7C8), progress)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // Shine (top-left glint)
      if (currentIceH > 35) {
        final shinePath = Path()
          ..moveTo(iceLeft + 18, iceTopY + 12)
          ..lineTo(iceLeft + 46, iceTopY + 12)
          ..lineTo(iceLeft + 28, iceTopY + 30)
          ..lineTo(iceLeft + 4, iceTopY + 30)
          ..close();
        canvas.drawPath(
          shinePath,
          Paint()..color = Colors.white.withOpacity(0.28 * (1.0 - progress)),
        );
      }

      // Drip drops
      if (progress > 0.05 && currentIceH > 12) {
        final Paint dropPaint = Paint()
          ..color = isPenalty
              ? const Color(0xAAEF9A9A)
              : const Color(0xAA89CFF0);
        for (int i = 0; i < 2; i++) {
          final double phase = (dripValue + i * 0.5) % 1.0;
          if (phase > 0.85) continue;
          final double dropY = _lerp(baseY, baseY + puddleRy * 2.2, phase);
          final double dropX = cx + (i == 0 ? -14.0 : 13.0);
          final double dropSize = _lerp(5.5, 2.0, phase);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(dropX, dropY),
              width: dropSize,
              height: dropSize * 1.5,
            ),
            dropPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_IceMeltPainter old) =>
      old.progress != progress ||
      old.dripValue != dripValue ||
      old.isPenalty != isPenalty;
}

// ── Water Splash Custom Painter for Completion ────────────────────────────────
class _SplashPainter extends CustomPainter {
  final double progress;
  const _SplashPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Expand a central ripple
    final rippleRadius = progress * 80;
    final rippleOpacity = (1.0 - progress).clamp(0.0, 1.0);
    paint.color = const Color(0xFF89CFF0).withOpacity(rippleOpacity * 0.4);
    canvas.drawCircle(Offset(cx, cy), rippleRadius, paint);
    
    // Small splash drops bursting outward
    const numDrops = 8;
    paint.color = const Color(0xFF38BDF8).withOpacity(rippleOpacity);
    for (int i = 0; i < numDrops; i++) {
      final angle = (i * 2 * pi) / numDrops;
      // Use easing for velocity: drops shoot out fast, then slow down
      final easeOutProgress = 1.0 - pow(1.0 - progress, 3); 
      final distance = 40 + (easeOutProgress * 60);
      final dx = cx + cos(angle) * distance;
      final dy = cy + sin(angle) * distance;
      final dropRadius = 6.0 * (1.0 - progress);
      
      canvas.drawCircle(Offset(dx, dy), dropRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_SplashPainter old) => old.progress != progress;
}
