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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up Provider pattern for state management
  // AuthState: Manages user authentication status
  // AppState: Manages book data and user shelves
  final authState = AuthState();
  final appState = AppState();
  authState.setAppState(appState);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authState),
        ChangeNotifierProvider(create: (_) => appState),
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
        // Soft, modern color palette with subtle shadows and gentle tones
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF2D3748), // Soft dark blue-gray
          onPrimary: Colors.white,
          background: const Color(0xFFF7FAFC), // Very light gray
          onBackground: const Color(0xFF2D3748),
          surface: Colors.white,
          onSurface: const Color(0xFF2D3748),
          secondary: const Color(0xFF718096), // Muted blue-gray
          onSecondary: Colors.white,
          primaryContainer: Colors.white,
          onPrimaryContainer: const Color(0xFF2D3748),
          outline: const Color(0xFFE2E8F0), // Light border color
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        // Modern typography with clean weights and improved readability
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700, // Slightly lighter than bold
            letterSpacing: -0.5,
            height: 1.2,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 1.3,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            height: 1.3,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400, // Regular weight for body text
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        // Modern card styling with subtle shadows and rounded corners
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.0), // Sleek organic corners
            side: BorderSide.none, // Remove harsh borders
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        // Modern pill-shaped buttons with subtle shadows
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.15),
            backgroundColor: const Color(0xFF2D3748),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0), // Pill shape
            ),
          ),
        ),
        // Modern AppBar with subtle background and soft shadows
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2D3748),
          elevation: 1,
          shadowColor: Color(0x0A000000), // Very subtle shadow
          centerTitle: false,
        ),
        // Modern popup styling with subtle shadows
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          elevation: 3,
          shadowColor: Color(0x0A000000),
          textStyle: TextStyle(color: Color(0xFF2D3748)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        // Tab bar styling with modern colors
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFF2D3748),
          unselectedLabelColor: Color(0xFF718096),
          indicatorColor: Color(0xFF2D3748),
          indicatorSize: TabBarIndicatorSize.tab,
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
