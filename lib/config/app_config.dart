import '../models/beach_location.dart';

class AppConfig {
  static BeachLocation? _currentLocation;
  static int? _currentGaNumber;
  static String? _currentGaName;

  static BeachLocation get currentLocation => _currentLocation!;
  static int get currentGaNumber => _currentGaNumber!;
  static String get currentGaName => _currentGaName ?? 'GA $_currentGaNumber';

  static bool get isLocationSet => _currentLocation != null;
  static bool get isGaSet => _currentGaNumber != null;

  static void setLocation(BeachLocation location) {
    _currentLocation = location;
  }

  static void setCurrentGa(int gaNumber, String gaName) {
    _currentGaNumber = gaNumber;
    _currentGaName = gaName;
  }

  static void clearGa() {
    _currentGaNumber = null;
    _currentGaName = null;
  }

  static String get todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
