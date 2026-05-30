import '../database/database_helper.dart';
import '../config/app_config.dart';
import 'settings_service.dart';

class AutoCloseService {
  static Future<bool> runIfNeeded() async {
    final cutoff = await SettingsService.getCutoffTime();
    final now = DateTime.now();
    final cutoffTime = DateTime(now.year, now.month, now.day, cutoff.hour, cutoff.minute);

    // Only auto-close if we're past the cutoff and it's a new day
    final lastAutoClose = await DatabaseHelper.instance.getSetting('last_auto_close_date');
    final today = AppConfig.todayDate;

    if (now.isAfter(cutoffTime) && lastAutoClose != today) {
      await DatabaseHelper.instance.autoCloseAllActive(
        AppConfig.currentLocation.id,
        cutoffTime,
      );
      await DatabaseHelper.instance.setSetting('last_auto_close_date', today);
      return true;
    }
    return false;
  }
}
