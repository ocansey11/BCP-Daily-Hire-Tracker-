import '../database/database_helper.dart';
import '../models/beach_location.dart';
import '../models/inventory_type.dart';
import '../models/ga.dart';
import '../config/app_config.dart';

class SettingsService {
  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyLocation = 'location';
  static const _keyCutoffHour = 'cutoff_hour';
  static const _keyCutoffMinute = 'cutoff_minute';

  static Future<bool> isOnboardingComplete() async {
    final value = await DatabaseHelper.instance.getSetting(_keyOnboardingComplete);
    return value == '1';
  }

  static Future<BeachLocation?> getLocation() async {
    final value = await DatabaseHelper.instance.getSetting(_keyLocation);
    if (value == null) return null;
    return BeachLocation.fromId(value);
  }

  static Future<({int hour, int minute})> getCutoffTime() async {
    final hourStr = await DatabaseHelper.instance.getSetting(_keyCutoffHour);
    final minStr = await DatabaseHelper.instance.getSetting(_keyCutoffMinute);
    return (
      hour: hourStr != null ? int.parse(hourStr) : 18,
      minute: minStr != null ? int.parse(minStr) : 0,
    );
  }

  static Future<void> setCutoffTime(int hour, int minute) async {
    await DatabaseHelper.instance.setSetting(_keyCutoffHour, hour.toString());
    await DatabaseHelper.instance.setSetting(_keyCutoffMinute, minute.toString());
  }

  static Future<void> completeOnboarding({
    required BeachLocation location,
    required List<InventoryType> inventoryTypes,
    required List<GA> gas,
  }) async {
    final db = DatabaseHelper.instance;
    await db.setSetting(_keyLocation, location.id);
    for (final type in inventoryTypes) {
      await db.insertInventoryType(type);
    }
    for (final ga in gas) {
      await db.insertGA(ga);
    }
    await db.setSetting(_keyCutoffHour, '18');
    await db.setSetting(_keyCutoffMinute, '0');
    await db.setSetting(_keyOnboardingComplete, '1');
    AppConfig.setLocation(location);
  }

  static Future<void> initAppConfig() async {
    final location = await getLocation();
    if (location != null) {
      AppConfig.setLocation(location);
    }
  }
}
