/// デモ用エントリーポイント（Firebase不要・モックデータで動作）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'demo/demo_home_screen.dart';

void main() {
  runApp(const ProviderScope(child: WorkoutTrackerDemoApp()));
}

class WorkoutTrackerDemoApp extends StatelessWidget {
  const WorkoutTrackerDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '筋トレ記録 - デモ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
      ),
      home: const DemoHomeScreen(),
    );
  }
}
