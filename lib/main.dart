import 'package:flutter/material.dart';
import 'ui/home_screen.dart';
import 'ui/difficulty_screen.dart';
import 'ui/game_screen.dart';

// App-wide colors
class AppColors {
  static const green = Color(0xFF3F835D); // page background
  static const board = Color(0xFF2B2A2A); // dark tiles
  static const textOnGreen = Colors.white;
}

void main() => runApp(const TicTacToeApp());

// Main app widget with routes and theme
class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.dark,
    );

    // Use 'surface' instead of deprecated 'background'
    final scheme = baseScheme.copyWith(
      surface: AppColors.green,
      // If you had background previously
      // background: AppColors.green
      onSurface: AppColors.textOnGreen,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tic-Tac-Toe',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.green,
        textTheme: const TextTheme(
          displaySmall: TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 18),
          bodyLarge: TextStyle(fontSize: 16),
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ),
      routes: {
        '/': (_) => const HomeScreen(),
        '/difficulty': (_) => const DifficultyScreen(),
        '/game': (_) => const GameScreen(),
      },
    );
  }
}
