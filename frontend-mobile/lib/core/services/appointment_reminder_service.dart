import 'dart:io';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// AppointmentReminderService — Smart local notification cho lịch hẹn đã xác nhận.
///
/// Workflow (giống Zocdoc/MyChart):
///   1. Khi bệnh nhân load lịch hẹn CONFIRMED → scheduleReminders()
///   2. Schedule 2 notification: 24h trước + 1h trước
///   3. Khi hủy lịch → cancelReminders()
///
/// Chỉ schedule cho lịch CONFIRMED (không spam lịch PENDING chưa chắc).
class AppointmentReminderService {
  AppointmentReminderService._();
  static final instance = AppointmentReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Khởi tạo (gọi 1 lần trong main.dart) ─────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    // Set timezone mặc định về Asia/Ho_Chi_Minh
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (_) {
      // Fallback: giữ UTC nếu timezone không load được
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Xin quyền notification trên Android 13+
    if (!kIsWeb && Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint('[Reminder] NotificationService initialized');
  }

  // ── Schedule 2 reminders cho 1 lịch hẹn ──────────────────────────────────
  /// [appointmentId] dùng làm base ID (notification ID = appointmentId hashCode)
  /// [date] ISO8601 string từ backend
  Future<void> scheduleReminders({
    required String appointmentId,
    required String title,
    required String date,
  }) async {
    if (!_initialized) await initialize();

    final appointmentTime = DateTime.tryParse(date);
    if (appointmentTime == null) return;

    // Schedule reminders nếu còn trong tương lai
    final tz24h = tz.TZDateTime.from(
      appointmentTime.subtract(const Duration(hours: 24)),
      tz.local,
    );
    final tz1h = tz.TZDateTime.from(
      appointmentTime.subtract(const Duration(hours: 1)),
      tz.local,
    );

    final baseId = appointmentId.hashCode.abs() % 100000;

    // Notification 24h trước
    if (tz24h.isAfter(tz.TZDateTime.now(tz.local))) {
      await _schedule(
        id: baseId,
        title: '📅 Nhắc lịch khám ngày mai',
        body: '$title — ${_formatTime(appointmentTime)} ngày mai',
        scheduledTime: tz24h,
      );
      debugPrint('[Reminder] Scheduled 24h reminder for $appointmentId at $tz24h');
    }

    // Notification 1h trước
    if (tz1h.isAfter(tz.TZDateTime.now(tz.local))) {
      await _schedule(
        id: baseId + 1,
        title: '🏥 Lịch khám sắp đến!',
        body: '$title — còn 1 tiếng nữa (${_formatTime(appointmentTime)})',
        scheduledTime: tz1h,
      );
      debugPrint('[Reminder] Scheduled 1h reminder for $appointmentId at $tz1h');
    }
  }

  // ── Hủy reminders khi lịch bị cancel ─────────────────────────────────────
  Future<void> cancelReminders(String appointmentId) async {
    if (!_initialized) return;
    final baseId = appointmentId.hashCode.abs() % 100000;
    await _plugin.cancel(baseId);
    await _plugin.cancel(baseId + 1);
    debugPrint('[Reminder] Cancelled reminders for $appointmentId');
  }

  // ── Hủy toàn bộ (dùng khi logout) ────────────────────────────────────────
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
    debugPrint('[Reminder] All reminders cancelled');
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_reminders',
          'Nhắc lịch khám',
          channelDescription: 'Thông báo nhắc lịch hẹn với bác sĩ',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF0D9488),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
