import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConstants {
  static const String appName = 'MediChain';

  // ─── Backend URL Config ────────────────────────────────────────────────────
  //
  // Production URL — cùng backend mà web Vercel đang dùng.
  // Ref: frontend/src/app/layout.tsx & frontend/next.config.ts
  //
  static const String _kProductionUrl =
      'https://medichain-backend-v4bo.onrender.com/api';

  // ⚠️  KHÔNG commit true lên repo — chỉ set true locally khi test Render
  static const bool _kUseProductionInDebug = true;

  static String get baseUrl {
    // Release build → luôn dùng Render production
    if (kReleaseMode) return _kProductionUrl;

    // Debug với flag bật → gọi Render (test emulator với web)
    if (_kUseProductionInDebug) return _kProductionUrl;

    // Debug + Android Emulator → 10.0.2.2 = localhost của máy host
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5000/api';

    // Debug + iOS / Web → localhost
    return 'http://localhost:5000/api';
  }

  // ─── Timeouts ─────────────────────────────────────────────────────────────
  static const int connectTimeout = 60000; // 60s — Render free tier cần 30-50s wake up
  static const int receiveTimeout = 60000;

  // ─── Storage Keys ─────────────────────────────────────────────────────────
  static const String tokenKey     = 'token';
  static const String userKey      = 'user';
  static const String viewingAsKey = 'viewing_as_userId';
}
