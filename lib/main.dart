import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Models
import 'models/app_state.dart';

// Services
import 'services/auth_state.dart';

// Screens
import 'screens/auth/auth_gate.dart';

/// Application entry point
/// Initializes Firebase and sets up state management providers
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for authentication and backend services
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up Provider pattern for state management
  // AuthState: Manages user authentication status
  // AppState: Manages book data and user shelves
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const SummerReadingApp(),
    ),
  );
}

/// Root application widget
/// Configures Material Design 3 theme and navigation
class SummerReadingApp extends StatelessWidget {
  const SummerReadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopkins Reads',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        // Custom typography system for consistent text styling
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
        // Card styling with rounded corners and elevation
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        // Button styling with consistent padding and rounded corners
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Page transition animations for smooth navigation
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      // AuthGate handles authentication routing (shows sign-in or home screen)
      home: const AuthGate(),
    );
  }
}
