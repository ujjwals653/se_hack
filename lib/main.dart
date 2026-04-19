import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:se_hack/core/services/theme_service.dart';
import 'package:se_hack/core/constants/api_keys.dart';
import 'package:se_hack/features/auth/auth_bloc.dart';
import 'package:se_hack/features/context_switch/domain/cognitive_debt_service.dart';
import 'package:se_hack/features/auth/google_auth_service.dart';
import 'package:se_hack/features/auth/login_screen.dart';
import 'package:se_hack/features/home/home_screen.dart';
import 'package:se_hack/features/posts/bloc/posts_bloc.dart';
import 'package:se_hack/features/attendance/domain/attendance_service.dart';
import 'package:se_hack/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:se_hack/features/resources/models/cached_resource.dart';

import 'package:se_hack/core/services/notification_service.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  
  await Hive.initFlutter();
  Hive.registerAdapter(CachedResourceAdapter());
  await Hive.openBox<CachedResource>('resource_cache');

  // Initialize Global Notifications
  GlobalNotificationService();

  // Add global observer immediately
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());

  runApp(const MainApp());
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Default to offline when detached
    String status = 'offline';
    if (state == AppLifecycleState.resumed) {
      status = 'online';
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      status = 'idle';
    }

    // Fire and forget update
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'status': status})
        .catchError((_) {}); // Ignore errors if offline
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              AuthBloc(authService: AuthService())..add(AuthStarted()),
        ),
        BlocProvider(create: (_) => PostsBloc()..add(LoadPosts())),
        ChangeNotifierProvider(create: (_) => AttendanceService()),
        ChangeNotifierProvider(create: (_) => FocusService()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: Builder(
        builder: (context) {
          final themeNotifier = context.watch<ThemeNotifier>();
          return MaterialApp(
            navigatorKey: globalNavigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Lumina',
            themeMode: themeNotifier.mode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4B4B6C),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.interTextTheme(const TextTheme()),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4B4B6C),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212),
              textTheme: GoogleFonts.interTextTheme(
                ThemeData.dark().textTheme,
              ),
            ),
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// Listens to AuthBloc and routes between LoginScreen and MainHomeScreen.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return MainHomeScreen(user: state.user);
        }
        if (state is AuthInitial) {
          // Splash / loading while checking persisted auth
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A2E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
            ),
          );
        }
        return const LoginScreen();
      },
    );
  }
}
