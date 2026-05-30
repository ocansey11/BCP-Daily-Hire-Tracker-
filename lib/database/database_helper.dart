import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/inventory_type.dart';
import '../models/rental.dart';
import '../models/ga.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bcp_tracker.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inventory_types (
        id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        price_pence INTEGER NOT NULL,
        total_count INTEGER NOT NULL,
        is_default INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE gas (
        ga_number INTEGER PRIMARY KEY,
        display_name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE rentals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_type_id TEXT NOT NULL,
        item_number INTEGER NOT NULL,
        opened_by_ga INTEGER NOT NULL,
        closed_by_ga INTEGER,
        customer_initials TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        auto_closed_at TEXT,
        status TEXT NOT NULL,
        date TEXT NOT NULL,
        location TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE inventory_changes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        change_type TEXT NOT NULL,
        item_type_id TEXT NOT NULL,
        old_value TEXT,
        new_value TEXT,
        changed_at TEXT NOT NULL,
        changed_by_ga INTEGER,
        location TEXT NOT NULL,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE shift_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ga_number INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        location TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_active ON rentals(item_type_id, item_number, status)');
    await db.execute('CREATE INDEX idx_date ON rentals(date)');
    await db.execute('CREATE INDEX idx_location_date ON rentals(location, date)');
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Inventory Types ───────────────────────────────────────────────────────

  Future<List<InventoryType>> getInventoryTypes({bool includeArchived = false}) async {
    final db = await database;
    final where = includeArchived ? null : 'is_archived = 0';
    final rows = await db.query('inventory_types',
        where: where, orderBy: 'is_default DESC, display_name ASC');
    return rows.map(InventoryType.fromMap).toList();
  }

  Future<InventoryType?> getInventoryType(String id) async {
    final db = await database;
    final rows = await db.query('inventory_types', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : InventoryType.fromMap(rows.first);
  }

  Future<void> insertInventoryType(InventoryType type) async {
    final db = await database;
    await db.insert('inventory_types', type.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateInventoryType(InventoryType type) async {
    final db = await database;
    await db.update('inventory_types', type.toMap(),
        where: 'id = ?', whereArgs: [type.id]);
  }

  // ── GAs ───────────────────────────────────────────────────────────────────

  Future<List<GA>> getGAs() async {
    final db = await database;
    final rows = await db.query('gas', orderBy: 'ga_number ASC');
    return rows.map(GA.fromMap).toList();
  }

  Future<GA?> getGA(int gaNumber) async {
    final db = await database;
    final rows = await db.query('gas', where: 'ga_number = ?', whereArgs: [gaNumber]);
    return rows.isEmpty ? null : GA.fromMap(rows.first);
  }

  Future<void> insertGA(GA ga) async {
    final db = await database;
    await db.insert('gas', ga.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteGA(int gaNumber) async {
    final db = await database;
    await db.delete('gas', where: 'ga_number = ?', whereArgs: [gaNumber]);
  }

  Future<void> updateGA(GA ga) async {
    final db = await database;
    await db.update('gas', ga.toMap(),
        where: 'ga_number = ?', whereArgs: [ga.gaNumber]);
  }

  // ── Rentals ───────────────────────────────────────────────────────────────

  Future<int> insertRental(Rental rental) async {
    final db = await database;
    return db.insert('rentals', rental.toMap());
  }

  Future<void> updateRental(Rental rental) async {
    final db = await database;
    await db.update('rentals', rental.toMap(),
        where: 'id = ?', whereArgs: [rental.id]);
  }

  Future<Rental?> getActiveRental(
      String itemTypeId, int itemNumber, String location) async {
    final db = await database;
    final rows = await db.query(
      'rentals',
      where: 'item_type_id = ? AND item_number = ? AND location = ? AND status = ?',
      whereArgs: [itemTypeId, itemNumber, location, 'active'],
    );
    return rows.isEmpty ? null : Rental.fromMap(rows.first);
  }

  Future<List<Rental>> getActiveRentalsForType(
      String itemTypeId, String location) async {
    final db = await database;
    final rows = await db.query(
      'rentals',
      where: 'item_type_id = ? AND location = ? AND status = ?',
      whereArgs: [itemTypeId, location, 'active'],
    );
    return rows.map(Rental.fromMap).toList();
  }

  Future<List<Rental>> getAllActiveRentals(String location) async {
    final db = await database;
    final rows = await db.query(
      'rentals',
      where: 'location = ? AND status = ?',
      whereArgs: [location, 'active'],
    );
    return rows.map(Rental.fromMap).toList();
  }

  Future<List<Rental>> getUnverifiedRentals(String location) async {
    final db = await database;
    final rows = await db.query(
      'rentals',
      where: 'location = ? AND status = ?',
      whereArgs: [location, 'closedAutoUnverified'],
      orderBy: 'start_time ASC',
    );
    return rows.map(Rental.fromMap).toList();
  }

  Future<List<Rental>> getRentalsForDate(
      String date, String location) async {
    final db = await database;
    final rows = await db.query(
      'rentals',
      where: 'date = ? AND location = ?',
      whereArgs: [date, location],
      orderBy: 'start_time ASC',
    );
    return rows.map(Rental.fromMap).toList();
  }

  Future<int> countActiveRentals(String location) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM rentals WHERE location = ? AND status = ?',
      [location, 'active'],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> countTodayRentals(String date, String location) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM rentals WHERE date = ? AND location = ?',
      [date, location],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> sumTodayRevenuePence(String date, String location) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(it.price_pence) as total
      FROM rentals r
      JOIN inventory_types it ON r.item_type_id = it.id
      WHERE r.date = ? AND r.location = ? AND r.status != ?
      ''',
      [date, location, 'active'],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> autoCloseAllActive(String location, DateTime cutoffTime) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final cutoff = cutoffTime.toIso8601String();
    await db.rawUpdate(
      '''
      UPDATE rentals
      SET status = 'closedAutoUnverified', end_time = ?, auto_closed_at = ?
      WHERE location = ? AND status = 'active'
      ''',
      [cutoff, now, location],
    );
  }

  // ── Stats (V2+V3) ───────────────────────────────────────────────────────

  Future<int> sumRevenuePenceForPeriod({
    required String startDate,
    required String endDate,
    required String location,
    int? gaNumber,
  }) async {
    final db = await database;
    final gaClause = gaNumber != null ? 'AND r.opened_by_ga = ?' : '';
    final args = [
      startDate, endDate, location, 'active',
      if (gaNumber != null) gaNumber,
    ];
    final result = await db.rawQuery(
      '''
      SELECT SUM(it.price_pence) as total
      FROM rentals r
      JOIN inventory_types it ON r.item_type_id = it.id
      WHERE r.date >= ? AND r.date <= ? AND r.location = ?
      AND r.status != ? $gaClause
      ''',
      args,
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> countRentalsForPeriod({
    required String startDate,
    required String endDate,
    required String location,
    int? gaNumber,
  }) async {
    final db = await database;
    final gaClause = gaNumber != null ? 'AND opened_by_ga = ?' : '';
    final args = [
      startDate, endDate, location,
      if (gaNumber != null) gaNumber,
    ];
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM rentals
      WHERE date >= ? AND date <= ? AND location = ? $gaClause
      ''',
      args,
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getTeamStatsByGA({
    required String startDate,
    required String endDate,
    required String location,
  }) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT r.opened_by_ga, COUNT(*) as rental_count,
             SUM(it.price_pence) as revenue_pence
      FROM rentals r
      JOIN inventory_types it ON r.item_type_id = it.id
      WHERE r.date >= ? AND r.date <= ? AND r.location = ?
      AND r.status != 'active'
      GROUP BY r.opened_by_ga
      ORDER BY revenue_pence DESC
      ''',
      [startDate, endDate, location],
    );
  }

  // ── Shift Log ─────────────────────────────────────────────────────────────

  Future<int> startShift(int gaNumber, String location) async {
    final db = await database;
    return db.insert('shift_log', {
      'ga_number': gaNumber,
      'started_at': DateTime.now().toIso8601String(),
      'location': location,
    });
  }

  Future<void> endCurrentShift(int gaNumber, String location) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE shift_log SET ended_at = ?
      WHERE ga_number = ? AND location = ? AND ended_at IS NULL
      ORDER BY started_at DESC LIMIT 1
      ''',
      [DateTime.now().toIso8601String(), gaNumber, location],
    );
  }

  // ── Inventory Changes ─────────────────────────────────────────────────────

  Future<void> logInventoryChange({
    required String changeType,
    required String itemTypeId,
    required String location,
    String? oldValue,
    String? newValue,
    int? changedByGa,
    String? notes,
  }) async {
    final db = await database;
    await db.insert('inventory_changes', {
      'change_type': changeType,
      'item_type_id': itemTypeId,
      'old_value': oldValue,
      'new_value': newValue,
      'changed_at': DateTime.now().toIso8601String(),
      'changed_by_ga': changedByGa,
      'location': location,
      'notes': notes,
    });
  }

  // ── Missing Items ─────────────────────────────────────────────────────────

  Future<List<int>> getMissingItemNumbers(
      String itemTypeId, String location) async {
    final db = await database;
    final rows = await db.query(
      'rentals',
      columns: ['item_number'],
      where: 'item_type_id = ? AND location = ? AND status = ?',
      whereArgs: [itemTypeId, location, 'missing'],
    );
    return rows.map((r) => r['item_number'] as int).toList();
  }
}
