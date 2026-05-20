class AppConstants {
  static const String appName = 'MediChain';

  // ─── Backend URL Config ────────────────────────────────────────────────────
  //
  // Default URL — cùng backend Render mà web/Vercel đang dùng.
  // Ref: frontend/src/app/layout.tsx & frontend/next.config.ts
  //
  static const String _kProductionUrl =
      'https://medichain-backend-v4bo.onrender.com/api';

  // Local dev override, ví dụ:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
  static const String _kApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _kProductionUrl,
  );

  static String get baseUrl => _kApiBaseUrl;

  // ─── Timeouts ─────────────────────────────────────────────────────────────
  static const int connectTimeout =
      60000; // 60s — Render free tier cần 30-50s wake up
  static const int receiveTimeout = 60000;

  // ─── Storage Keys ─────────────────────────────────────────────────────────
  static const String tokenKey = 'token';
  static const String userKey = 'user';
  static const String viewingAsKey = 'viewing_as_userId';
}
