import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static const String transactionsBox = 'transactions';
  static const String meetingsBox = 'meetings';
  static const String userProfileBox = 'user_profile';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes
    await Hive.openBox(transactionsBox);
    await Hive.openBox(meetingsBox);
    await Hive.openBox(userProfileBox);
  }

  // Helper methods for offline sync can be added here
}
