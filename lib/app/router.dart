import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:se_hack/features/auth/auth_bloc.dart';
import 'package:se_hack/features/auth/login_screen.dart';
import 'package:se_hack/features/home/presentation/dashboard_screen.dart';
import 'package:se_hack/features/home/main_shell.dart';
import 'package:se_hack/features/group_hub/presentation/hub_screen.dart';
import 'package:se_hack/features/posts/presentation/screens/posts_screen.dart';
import 'package:se_hack/features/profile/presentation/profile_screen.dart';
import 'package:se_hack/features/calendar/bloc/calendar_bloc.dart';
import 'package:se_hack/features/calendar/presentation/calendar_screen.dart';

import 'package:se_hack/features/timetable/presentation/timetable_screen.dart';
import 'package:se_hack/features/timetable/presentation/attendance_screen.dart';
import 'package:se_hack/features/expense/bloc/expense_cubit.dart';
import 'package:se_hack/features/expense/presentation/expense_home_screen.dart';
import 'package:se_hack/features/resources/screens/offline_drive_screen.dart' as se_hack_drive;
import 'package:se_hack/features/context_switch/presentation/focus_screen.dart' as se_hack_focus;
import 'package:se_hack/features/rag/presentation/rag_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// A custom stream listener for GoRouter since AuthBloc is a stream
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final bool isLoggingIn = state.matchedLocation == '/login';

      if (authState is AuthInitial) {
        return null; 
      }
      if (authState is AuthUnauthenticated) {
        return isLoggingIn ? null : '/login';
      }
      if (authState is AuthAuthenticated) {
        if (isLoggingIn || state.matchedLocation == '/') {
          return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          backgroundColor: Color(0xFFF4F5FA),
          body: Center(child: CircularProgressIndicator(color: Color(0xFF7B61FF))),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // --- Feature Routes ---
      GoRoute(
        path: '/timetable',
        builder: (context, state) {
          final user = (authBloc.state as AuthAuthenticated).user;
          return TimetableScreen(userId: user.uid);
        },
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/expense',
        builder: (context, state) => BlocProvider(
          create: (_) => ExpenseCubit(),
          child: const ExpenseHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => BlocProvider(
          create: (_) => CalendarBloc()..add(CalendarLoadRequested()),
          child: const CalendarScreen(),
        ),
      ),
      GoRoute(
        path: '/drive',
        builder: (context, state) => const se_hack_drive.OfflineDriveScreen(),
      ),
      GoRoute(
        path: '/focus',
        builder: (context, state) => const se_hack_focus.FocusScreen(),
      ),
      GoRoute(
        path: '/rag',
        builder: (context, state) => const RagScreen(),
      ),
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final user = (authBloc.state as AuthAuthenticated).user;
          return MainShell(navigationShell: navigationShell, user: user);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) {
                  final user = (authBloc.state as AuthAuthenticated).user;
                  return HomeScreen(user: user);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/hub',
                builder: (context, state) => const HubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/posts',
                builder: (context, state) {
                  final user = (authBloc.state as AuthAuthenticated).user;
                  return PostsScreen(
                    currentUid: user.uid,
                    currentUserName: user.displayName,
                    currentUserPhotoUrl: user.photoUrl,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  final user = (authBloc.state as AuthAuthenticated).user;
                  return ProfileScreen(user: user);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
