import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_ce/hive.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/user.dart' as app;

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Preferences box
  static late Box<bool> _prefsBox;

  // Preference keys
  static const String morningKey = 'morning_enabled';
  static const String missionsKey = 'missions_enabled';
  static const String streakKey = 'streak_enabled';

  // Fixed notification IDs
  static const int _streakReminderId = 1;
  static const int _morningMotivationId = 2;
  static const int _missionsReadyId = 3;
  static const int _streakCelebrationId = 4;

  // Android channel
  static const String _channelId = 'rush_reminders';
  static const String _channelName = 'Rush Reminders';
  static const String _channelDesc =
      'Recordatorios motivacionales para tus carreras';

  /// Initialize the notification plugin and request permissions.
  /// Call once in main() before runApp.
  static Future<void> init() async {
    // Initialize timezone database
    tzdata.initializeTimeZones();

    // Open preferences box
    _prefsBox = await Hive.openBox<bool>('notification_prefs');

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings — request permission on init
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _instance._plugin.initialize(initSettings);

    // Create Android notification channel
    await _instance._plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    debugPrint('NotificationService initialized');
  }

  // ── Preferences ───────────────────────────────────────────────────

  /// Check if a notification type is enabled (defaults to true).
  static bool isEnabled(String key) {
    return _prefsBox.get(key, defaultValue: true) ?? true;
  }

  /// Enable or disable a notification type and reschedule.
  static Future<void> setEnabled(String key, bool value) async {
    await _prefsBox.put(key, value);
  }

  // ── Scheduling ────────────────────────────────────────────────────

  /// Cancel all scheduled notifications and re-schedule based on current user state.
  /// Call on app startup (after user is loaded) and after each run completes.
  static Future<void> scheduleAllNotifications(app.User user) async {
    await _instance._plugin.cancelAll();

    // 1. Morning motivation — 8:00 AM daily
    if (isEnabled(morningKey)) {
      await _scheduleMorningMotivation();
    }

    // 2. Missions ready — 8:30 AM daily
    if (isEnabled(missionsKey)) {
      await _scheduleMissionsReady();
    }

    // 3. Streak reminder — 8:00 PM (only if user hasn't run today)
    if (isEnabled(streakKey)) {
      await _scheduleStreakReminder(user);
    }

    debugPrint('Notifications scheduled for user ${user.name}');
  }

  /// Show an instant notification celebrating an active streak.
  /// Called after processRun() when streak >= 2.
  static Future<void> showStreakCelebration(int streakDays) async {
    if (streakDays < 2) return;

    await _instance._plugin.show(
      _streakCelebrationId,
      'Llevas $streakDays dias de racha!',
      'Sigue asi! La consistencia es clave para subir de nivel.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ── Private scheduling methods ──────────────────────────────────────

  static Future<void> _scheduleMorningMotivation() async {
    await _instance._plugin.zonedSchedule(
      _morningMotivationId,
      'No te pierdas tu carrera!',
      'Un nuevo dia, una nueva oportunidad de superar tu record. A correr!',
      _nextInstanceOfTime(8, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleMissionsReady() async {
    await _instance._plugin.zonedSchedule(
      _missionsReadyId,
      'Tus misiones diarias estan listas!',
      'Revisa los retos de hoy y gana XP extra.',
      _nextInstanceOfTime(8, 30),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleStreakReminder(app.User user) async {
    // If the user already ran today, skip the reminder
    final now = DateTime.now();
    if (user.lastRunAt != null) {
      final lastRun = user.lastRunAt!;
      if (lastRun.year == now.year &&
          lastRun.month == now.month &&
          lastRun.day == now.day) {
        debugPrint('User already ran today — skipping streak reminder');
        return;
      }
    }

    final streakText = user.currentStreak > 0
        ? 'Tienes una racha de ${user.currentStreak} dias. Sal a correr!'
        : 'Comienza una nueva racha hoy!';

    await _instance._plugin.zonedSchedule(
      _streakReminderId,
      'No pierdas tu racha!',
      streakText,
      _nextInstanceOfTime(20, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  /// Returns the next occurrence of [hour]:[minute] today or tomorrow.
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
