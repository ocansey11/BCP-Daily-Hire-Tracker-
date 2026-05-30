import '../database/database_helper.dart';
import '../models/ga.dart';
import '../config/app_config.dart';

class ShiftService {
  static int? _currentShiftId;

  static Future<void> startShift(GA ga) async {
    final location = AppConfig.currentLocation.id;

    if (AppConfig.isGaSet) {
      await DatabaseHelper.instance.endCurrentShift(AppConfig.currentGaNumber, location);
    }

    _currentShiftId = await DatabaseHelper.instance.startShift(ga.gaNumber, location);
    AppConfig.setCurrentGa(ga.gaNumber, ga.displayName);
  }

  static Future<void> endShift() async {
    if (!AppConfig.isGaSet) return;
    await DatabaseHelper.instance.endCurrentShift(
      AppConfig.currentGaNumber,
      AppConfig.currentLocation.id,
    );
    AppConfig.clearGa();
    _currentShiftId = null;
  }
}
