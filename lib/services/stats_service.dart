import '../database/database_helper.dart';
import '../config/app_config.dart';

class StatsService {
  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String get weekStart {
    final now = DateTime.now();
    return _dateStr(now.subtract(Duration(days: now.weekday - 1)));
  }

  static String get monthStart {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  }

  static String get today => AppConfig.todayDate;

  static Future<({int count, int revenuePence})> statsForPeriod({
    required String startDate,
    required String endDate,
    int? gaNumber,
  }) async {
    final location = AppConfig.currentLocation.id;
    final db = DatabaseHelper.instance;
    final count = await db.countRentalsForPeriod(
      startDate: startDate, endDate: endDate, location: location, gaNumber: gaNumber,
    );
    final revenue = await db.sumRevenuePenceForPeriod(
      startDate: startDate, endDate: endDate, location: location, gaNumber: gaNumber,
    );
    return (count: count, revenuePence: revenue);
  }

  static Future<List<Map<String, dynamic>>> teamStatsByGA(
      String startDate, String endDate) {
    return DatabaseHelper.instance.getTeamStatsByGA(
      startDate: startDate,
      endDate: endDate,
      location: AppConfig.currentLocation.id,
    );
  }

  static String formatPence(int pence) {
    final pounds = pence ~/ 100;
    final p = pence % 100;
    return '£$pounds.${p.toString().padLeft(2, '0')}';
  }
}
