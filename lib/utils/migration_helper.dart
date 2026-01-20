import '../models/app_state.dart';

/// Helper utility for migrating sample data to Firebase
/// This can be called once to populate your Firestore database
/// 
/// Usage example:
/// ```dart
/// final appState = Provider.of<AppState>(context, listen: false);
/// await appState.migrateSampleDataToFirebase();
/// ```
/// 
/// Note: Make sure Firebase is initialized before calling this method
class MigrationHelper {
  /// Migrate sample books to Firebase Firestore
  /// Call this method once to populate your database with initial data
  static Future<void> migrateBooksToFirebase(AppState appState) async {
    await appState.migrateSampleDataToFirebase();
  }
}

