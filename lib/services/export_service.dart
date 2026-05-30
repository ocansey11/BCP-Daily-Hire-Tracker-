import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../config/app_config.dart';

class ExportService {
  static Future<String> exportTodayAsJson() async {
    final location = AppConfig.currentLocation.id;
    final today = AppConfig.todayDate;

    final rentals = await DatabaseHelper.instance.getRentalsForDate(today, location);
    final types = await DatabaseHelper.instance.getInventoryTypes(includeArchived: true);

    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'location': location,
      'date': today,
      'total_rentals': rentals.length,
      'inventory_types': types.map((t) => t.toMap()).toList(),
      'rentals': rentals.map((r) => r.toMap()).toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bcp_rentals_${today}_$location.json');
    await file.writeAsString(json);
    return file.path;
  }
}
