import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/app_usage_repository.dart';

enum FocusState { notStarted, focusing, onBreak, completed }

class FocusService extends ChangeNotifier with WidgetsBindingObserver {
  final AppUsageRepository _appUsageRepo = AppUsageRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  FocusState _currentState = FocusState.notStarted;
  
  int _targetSeconds = 0;
  int _elapsedSeconds = 0;
  int _lastBreakTimestamp = 0; // The _elapsedSeconds when the last break ended
  
  // Timer for 5 minute break 
  int _breakSecondsRemaining = 0;
  
  // Points
  int _lifetimePoints = 0; // Real total from Firebase
  int _sessionPoints = 0; // Points accrued in the CURRENT session
  
  Timer? _ticker;
  // Variables for robust background tracking
  
  // Variables for robust background tracking
  int _lastCheckedTimeMillis = DateTime.now().millisecondsSinceEpoch;
  DateTime? _lastTickTime;
 // Track what we last synced to avoid unnecessary writes
  
  final Set<String> distractionApps = {
    'com.instagram.android',
    'com.zhiliaoapp.musically',
    'com.google.android.youtube',
    'com.whatsapp',
    'com.snapchat.android',
  };

  final String currentAppPackageBase = 'com.scoders.lumina';
  final String currentAppPackageFallback = 'com.example.se_hack';



  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  DateTime? _pausedTime;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_currentState != FocusState.notStarted && _currentState != FocusState.completed && _pausedTime != null) {
        final deltaSeconds = DateTime.now().difference(_pausedTime!).inSeconds;
        if (deltaSeconds > 0) {
          if (_currentState == FocusState.focusing) {
            _elapsedSeconds += deltaSeconds;
            if (_elapsedSeconds >= _targetSeconds) {
              _completeSession();
            }
          } else if (_currentState == FocusState.onBreak) {
            _breakSecondsRemaining -= deltaSeconds;
            if (_breakSecondsRemaining <= 0) {
              _endBreak();
            }
          }
        }
        
        // Critically: check what they did while backgrounded
        _checkDistractions(isFromResume: true);
        notifyListeners();
      }
    }
  }


  String? _userId;
  
  String? lastPenaltyMessage;
  bool showPenaltyAnimation = false;
  int _penaltyCooldown = 0;

  FocusState get currentState => _currentState;
  int get sessionPoints => _sessionPoints;
  int get lifetimePoints => _lifetimePoints;
  int get elapsedSeconds => _elapsedSeconds;
  int get targetSeconds => _targetSeconds;
  int get breakSecondsRemaining => _breakSecondsRemaining;
  String? get userId => _userId;
  
  // A break is allowed if 30 minutes (1800s) have passed since the start or last break
  bool get isBreakAllowed => _currentState == FocusState.focusing && 
                             (_elapsedSeconds - _lastBreakTimestamp) >= 1800;

  FocusService() {
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      initialize(user.uid);
    }
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  Future<void> _showPenaltyNotification(int pointsLost) async {
    const androidDetails = AndroidNotificationDetails(
      'focus_penalties',
      'Focus Penalties',
      channelDescription: 'Notifications when you lose focus points',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      0,
      'Focus Broken!',
      'You lost $pointsLost points for switching apps. Stay focused!',
      details,
    );
  }

  void initialize(String userId) {
    _userId = userId;
    // Load lifetime points
    _firestore.collection('users').doc(_userId).snapshots().listen((doc) {
      if (doc.exists) {
        _lifetimePoints = doc.data()?['focusPoints'] ?? 0;
        notifyListeners();
      }
    });
  }

  Future<void> startFocusSession(BuildContext context, int durationMinutes) async {
    // Request notification permission for penalties
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    bool hasPermission = await _appUsageRepo.checkUsagePermission();
    if (!context.mounted) return;
    
    if (!hasPermission) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Usage Access Required", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Lumina needs Android 'Usage Access' to check if you switch apps while studying.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _appUsageRepo.requestUsagePermission();
              },
              child: const Text("Settings"),
            ),
          ],
        ),
      );
      return;
    }

    _lastCheckedTimeMillis = DateTime.now().millisecondsSinceEpoch;
    _targetSeconds = durationMinutes * 60;
    _elapsedSeconds = 0;
    _lastBreakTimestamp = 0;
    _sessionPoints = 0;
    _currentState = FocusState.focusing;
    lastPenaltyMessage = null;
    showPenaltyAnimation = false;
    notifyListeners();

    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentState == FocusState.focusing) {
        _elapsedSeconds++;
        
        // Every 5 seconds, check the foreground app for penalties/rewards
        if (_elapsedSeconds % 5 == 0) {
          _checkDistractions();
        }

        // Completion Check
        if (_elapsedSeconds >= _targetSeconds) {
          _completeSession();
        }
      } else if (_currentState == FocusState.onBreak) {
        _breakSecondsRemaining--;
        if (_breakSecondsRemaining <= 0) {
          _endBreak();
        }
      }
      notifyListeners();
    });
  }

  void _syncPointsToFirebase(int pointsToSync) {
    if (_userId == null || pointsToSync == 0) return;
    _firestore.collection('users').doc(_userId).set({
      'focusPoints': FieldValue.increment(pointsToSync),
      'focusLastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _checkDistractions({bool isFromResume = false}) async {
    bool punished = false;
    
    if (isFromResume) {
        // Query everything they used while away
        final nowMillis = DateTime.now().millisecondsSinceEpoch;
        final apps = await _appUsageRepo.getForegroundAppsSince(_lastCheckedTimeMillis);
        _lastCheckedTimeMillis = nowMillis;
        
        for (final packageName in apps) {
            if (distractionApps.contains(packageName)) {
                punished = true;
                break;
            }
        }
    } else {
        // Regular 5 second tracker - poll latest accurate app via Android
        final appInfo = await _appUsageRepo.getLatestForegroundApp();
        if (appInfo != null) {
            final packageName = appInfo['packageName'];
            if (distractionApps.contains(packageName)) {
                punished = true;
            } else if (packageName == currentAppPackageBase || packageName == currentAppPackageFallback) {
                _updateSessionPoints(5); // Actively using Lumina yields coins!
            }
        }
    }
    
    if (punished) {
        lastPenaltyMessage = "You got distracted! (-10 pts)";
        showPenaltyAnimation = true;
        _penaltyCooldown = 4;
        _updateSessionPoints(-10);
        _showPenaltyNotification(10);
    } else {
        if (_penaltyCooldown <= 0) {
            showPenaltyAnimation = false;
        } else {
            _penaltyCooldown--;
        }
    }
  }

  void _updateSessionPoints(int delta) {
    if (delta == 0) return;
    if (_sessionPoints + delta < 0) {
      _sessionPoints = 0;
    } else {
      _sessionPoints += delta;
    }
  }

  void takeBreak() {
    if (!isBreakAllowed) return;
    _currentState = FocusState.onBreak;
    _breakSecondsRemaining = 300; // 5 minutes
    showPenaltyAnimation = false;
    notifyListeners();
  }

  void _endBreak() {
    _currentState = FocusState.focusing;
    _lastBreakTimestamp = _elapsedSeconds; // Reset 30 min wait
    notifyListeners();
  }

  void giveUp() {
    _ticker?.cancel();
    _currentState = FocusState.notStarted;
    _sessionPoints = 0;
    showPenaltyAnimation = false;
    notifyListeners();
  }

  void _completeSession() {
    _ticker?.cancel();
    _currentState = FocusState.completed;
    
    // Final sync — sync the full session points now!
    if (_sessionPoints > 0) {
      _syncPointsToFirebase(_sessionPoints);
    }
    notifyListeners();
  }
  
  void resetSession() {
      _currentState = FocusState.notStarted;
      notifyListeners();
  }
}
