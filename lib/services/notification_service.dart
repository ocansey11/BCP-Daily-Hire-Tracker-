import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'settings_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> scheduleEndOfDayReminder(int openCount) async {
    await _plugin.cancelAll();
    if (openCount == 0) return;

    final cutoff = await SettingsService.getCutoffTime();
    final now = DateTime.now();

    // Reminder fires 30 min before cutoff
    final reminderTime = DateTime(
      now.year, now.month, now.day,
      cutoff.hour, cutoff.minute,
    ).subtract(const Duration(minutes: 30));

    if (reminderTime.isBefore(now)) return;

    const androidDetails = AndroidNotificationDetails(
      'end_of_day',
      'End of Day Reminder',
      channelDescription: 'Reminds you to close open rentals before cutoff',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      1,
      'Open Rentals',
      'You have $openCount open rental${openCount == 1 ? '' : 's'} — cutoff in 30 minutes.',
      details,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
