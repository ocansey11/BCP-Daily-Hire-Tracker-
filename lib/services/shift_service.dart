import '../database/database_helper.dart';
import '../models/ga.dart';
import '../config/app_config.dart';

class ShiftService {
  static int? _currentShiftId;

  static Future<void> startShift(GA ga) async {
    final location = AppConfig.currentLocation.id;

    if (AppConfig.isGaSet) {
      await DatabaseHelper.instance.pauseCurrentShift(AppConfig.currentGaNumber, location);
    }

    _currentShiftId = await DatabaseHelper.instance.startShift(ga.gaNumber, location);
    AppConfig.setCurrentGa(ga.gaNumber, ga.displayName);
  }

  static Future<void> pauseShift() async {
    if (!AppConfig.isGaSet) return;
    await DatabaseHelper.instance.pauseCurrentShift(
      AppConfig.currentGaNumber,
      AppConfig.currentLocation.id,
    );
    AppConfig.clearGa();
    _currentShiftId = null;
  }
}
