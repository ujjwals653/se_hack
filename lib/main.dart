import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:se_hack/features/home/home_screen.dart';
import 'package:se_hack/features/timetable/data/models/timetable_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (defaults to google-services.json)
  await Firebase.initializeApp();

  // Initialize Hive and open Timetable box
  await Hive.initFlutter();
  Hive.registerAdapter(TimetableEntryAdapter());
  await Hive.openBox<TimetableEntry>('timetableBox');

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard UI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4B4B6C)),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}
