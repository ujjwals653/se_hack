import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:se_hack/core/constants/api_keys.dart';
import 'package:se_hack/features/auth/auth_bloc.dart';
import 'package:se_hack/features/auth/google_auth_service.dart';
import 'package:se_hack/features/auth/login_screen.dart';
import 'package:se_hack/features/home/home_screen.dart';
import 'package:se_hack/features/posts/bloc/posts_bloc.dart';
import 'package:se_hack/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(authService: AuthService())..add(AuthStarted()),
        ),
        BlocProvider(
          create: (_) => PostsBloc()..add(LoadPosts()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Lumina',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4B4B6C)),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(
            const TextTheme(),
          ),
        ),
        home: const _AuthGate(),
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
