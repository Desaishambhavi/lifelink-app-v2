import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_notification.dart';
import '../models/medication_reminder.dart';

/// Fires real OS (local) notifications: immediate ones for fall/SOS/other
/// in-app alerts, and scheduled ones for medication reminders.
///
/// Everything is a no-op on web (the plugin is mobile-only), so the rest of the
/// app can call these methods unconditionally.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const AndroidNotificationChannel _alertsChannel =
      AndroidNotificationChannel(
    'lifelink_alerts',
    'Emergency alerts',
    description: 'Fall detection and emergency SOS alerts',
    importance: Importance.max,
  );
  static const AndroidNotificationChannel _remindersChannel =
      AndroidNotificationChannel(
    'lifelink_reminders',
    'Medication reminders',
    description: 'Scheduled medication reminders',
    importance: Importance.high,
  );
  static const AndroidNotificationChannel _generalChannel =
      AndroidNotificationChannel(
    'lifelink_general',
    'Updates',
    description: 'Vitals, reports and other updates',
    importance: Importance.defaultImportance,
  );

  /// Initialise the plugin, timezone data, channels and permissions. Safe to
  /// call once at startup; a no-op on web.
  static Future<void> init() async {
    if (kIsWeb) return;

    tzdata.initializeTimeZones();
    try {
      // Set the device's local zone so scheduled reminders fire at the right
      // wall-clock time. Different flutter_timezone versions return a String or
      // a TimezoneInfo, so read it defensively.
      final dynamic info = await FlutterTimezone.getLocalTimezone();
      final String name = info is String ? info : (info.identifier as String);
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Leave tz.local at its UTC default if the zone can't be resolved.
    }

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(_alertsChannel);
      await androidImpl.createNotificationChannel(_remindersChannel);
      await androidImpl.createNotificationChannel(_generalChannel);
    }

    _ready = true;
    await requestPermissions();
  }

  /// Ask for notification (and exact-alarm) permission where the OS requires it.
  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    final IOSFlutterLocalNotificationsPlugin? iosImpl =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // --- immediate notifications (fall, SOS, and everything else) -------------

  /// Mirrors an in-app [AppNotification] to a real OS notification.
  static Future<void> showForNotification(AppNotification n) async {
    if (kIsWeb || !_ready) return;
    final AndroidNotificationChannel channel = _channelFor(n.kind);
    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: Priority.high,
        category: _categoryFor(n.kind),
        styleInformation: BigTextStyleInformation(n.body),
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(_eventId(n.id), n.title, n.body, details);
  }

  // --- scheduled medication reminders ---------------------------------------

  /// (Re)schedules a reminder. Cancels first, then schedules if it's enabled,
  /// so this is safe to call on every load / edit / toggle.
  ///
  /// A reminder that repeats on specific weekdays becomes several OS
  /// notifications — one per chosen day — because each scheduled notification
  /// can only match a single day-of-week.
  static Future<void> scheduleReminder(MedicationReminder r) async {
    if (kIsWeb || !_ready) return;
    await cancelReminder(r.id);
    if (!r.enabled) return;

    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _remindersChannel.id,
        _remindersChannel.name,
        channelDescription: _remindersChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final String title = 'Time for ${r.medicationName}';
    final String body = r.dosage.trim().isEmpty
        ? 'Medication reminder'
        : 'Take ${r.dosage}';

    if (r.days.isEmpty) {
      // One-time: fire once at the next occurrence, no repeat match.
      await _scheduleOne(
          _reminderDayId(r.id, 0), title, body, r.nextOccurrence(), null, details);
    } else if (r.days.length == 7) {
      // Every day: a single daily-repeating schedule.
      await _scheduleOne(_reminderDayId(r.id, 0), title, body,
          r.nextOccurrence(), DateTimeComponents.time, details);
    } else {
      // Selected days: one weekly-repeating schedule per chosen weekday.
      for (final d in r.days) {
        await _scheduleOne(_reminderDayId(r.id, d), title, body,
            r.nextOccurrenceForWeekday(d), DateTimeComponents.dayOfWeekAndTime,
            details);
      }
    }
  }

  static Future<void> _scheduleOne(
    int id,
    String title,
    String body,
    DateTime when,
    DateTimeComponents? match,
    NotificationDetails details,
  ) async {
    final tz.TZDateTime scheduled = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        id, title, body, scheduled, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: match,
      );
    } catch (_) {
      // Exact alarms may be disallowed (Android 12+ without permission); fall
      // back to an inexact schedule rather than failing the reminder.
      await _plugin.zonedSchedule(
        id, title, body, scheduled, details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: match,
      );
    }
  }

  static Future<void> cancelReminder(String reminderId) async {
    if (kIsWeb) return;
    // Cancel every possible day-variant (0 = one-time/daily, 1–7 = weekdays).
    for (var w = 0; w <= 7; w++) {
      await _plugin.cancel(_reminderDayId(reminderId, w));
    }
  }

  // --- helpers ---------------------------------------------------------------

  static AndroidNotificationChannel _channelFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.fall:
      case NotificationKind.sos:
        return _alertsChannel;
      case NotificationKind.reminder:
        return _remindersChannel;
      case NotificationKind.vitals:
      case NotificationKind.report:
      case NotificationKind.system:
        return _generalChannel;
    }
  }

  static AndroidNotificationCategory? _categoryFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.fall:
      case NotificationKind.sos:
        return AndroidNotificationCategory.alarm;
      case NotificationKind.reminder:
        return AndroidNotificationCategory.reminder;
      case NotificationKind.vitals:
      case NotificationKind.report:
      case NotificationKind.system:
        return AndroidNotificationCategory.status;
    }
  }

  // Stable, namespaced ids. A reminder can schedule several notifications (one
  // per selected weekday), so its id embeds the weekday (0 = one-time / daily)
  // in the low 3 bits. All reminder ids stay in the low range (≤ 0x07FFFFFF),
  // clear of event ids (≥ 0x40000000), so the two never collide.
  static int _reminderDayId(String id, int weekday) =>
      ((id.hashCode & 0x00ffffff) << 3) | (weekday & 0x7);
  static int _eventId(String id) => 0x40000000 | (id.hashCode & 0x3fffffff);
}
