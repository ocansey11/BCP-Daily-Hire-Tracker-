import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'settings_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  // V2: Schedule a notification 30 min before cutoff if there are open rentals.
  // Called every time rental state changes.
  static Future<void> scheduleCutoffReminder(int openCount) async {
    await _plugin.cancel(1);
    if (openCount == 0) return;

    final cutoff = await SettingsService.getCutoffTime();
    final now = tz.TZDateTime.now(tz.local);

    final reminderTime = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      cutoff.hour, cutoff.minute,
    ).subtract(const Duration(minutes: 30));

    if (reminderTime.isBefore(now)) return;

    const androidDetails = AndroidNotificationDetails(
      'pre_cutoff',
      'Pre-Cutoff Reminder',
      channelDescription: 'Fires 30 minutes before the end-of-day cutoff',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      1,
      'Open Rentals',
      '$openCount rental${openCount == 1 ? '' : 's'} still out — cutoff in 30 minutes.',
      reminderTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}
