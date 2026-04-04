import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConstants {
  static const String appName = 'MediChain';

  // API URL logic:
  // - Web: dùng localhost
  // - Android Emulator: dùng 10.0.2.2
  // - Khác (iOS/Desktop): dùng localhost
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  // Timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  // Storage Keys
  static const String tokenKey = 'token';
  static const String userKey = 'user';
  static const String viewingAsKey = 'viewing_as_userId';
}
