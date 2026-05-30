import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../models/inventory_type.dart';
import '../models/rental.dart';
import '../services/auto_close_service.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';
import '../widgets/item_grid.dart';
import 'review_screen.dart';
import 'settings_screen.dart';
import 'ga_select_screen.dart';
import 'stats_screen.dart';
import 'goals_screen.dart';

class HomeScreen extends StatefulWidget {
  // V3: optional greeting shown after GA login
  final String? greetingMessage;
  const HomeScreen({super.key, this.greetingMessage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<InventoryType> _types = [];
  Map<String, Set<int>> _activeMap = {};
  Map<String, Set<int>> _missingMap = {};
  int _unverifiedCount = 0;
  int _todayCount = 0;
  int _todayRevenuePence = 0;
  int _activeCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();

    // V3: show welcome greeting after first frame
    if (widget.greetingMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.greetingMessage!),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  Future<void> _init() async {
    await AutoCloseService.runIfNeeded();
    await _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final location = AppConfig.currentLocation.id;
    final today = AppConfig.todayDate;

    final types = await db.getInventoryTypes();
    final unverified = await db.getUnverifiedRentals(location);
    final todayCount = await db.countTodayRentals(today, location);
    final todayRevenue = await db.sumTodayRevenuePence(today, location);
    final activeCount = await db.countActiveRentals(location);

    final activeMap = <String, Set<int>>{};
    final missingMap = <String, Set<int>>{};
    for (final type in types) {
      final active = await db.getActiveRentalsForType(type.id, location);
      activeMap[type.id] = active.map((r) => r.itemNumber).toSet();
      final missing = await db.getMissingItemNumbers(type.id, location);
      missingMap[type.id] = missing.toSet();
    }

    // V2: reschedule pre-cutoff reminder on every state change
    NotificationService.scheduleCutoffReminder(activeCount);

    if (!mounted) return;
    setState(() {
      _types = types;
      _activeMap = activeMap;
      _missingMap = missingMap;
      _unverifiedCount = unverified.length;
      _todayCount = todayCount;
      _todayRevenuePence = todayRevenue;
      _activeCount = activeCount;
      _loading = false;

      if (_tabController == null || _tabController!.length != types.length) {
        _tabController?.dispose();
        _tabController = TabController(length: types.length, vsync: this);
      }
    });
  }

  // V2: prompt for customer initials (optional) before opening a rental
  Future<String?> _promptInitials() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customer Initials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Optional — tap Skip to open without.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLength: 2,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]'))
              ],
              decoration: const InputDecoration(
                hintText: 'e.g. KO',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (v) {
                final clean = v.trim().toUpperCase();
                Navigator.pop(
                    ctx, clean.length == 2 ? '${clean[0]}.${clean[1]}' : null);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Skip')),
          FilledButton(
            onPressed: () {
              final clean = ctrl.text.trim().toUpperCase();
              Navigator.pop(
                  ctx, clean.length == 2 ? '${clean[0]}.${clean[1]}' : null);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBubbleTap(String typeId, int itemNumber) async {
    final db = DatabaseHelper.instance;
    final location = AppConfig.currentLocation.id;
    final today = AppConfig.todayDate;
    final gaNumber = AppConfig.currentGaNumber;

    final active = await db.getActiveRental(typeId, itemNumber, location);
    if (active != null) {
      await db.updateRental(active.copyWith(
        endTime: DateTime.now(),
        closedByGa: gaNumber,
        status: RentalStatus.closedNormal,
      ));
    } else {
      // V2: collect initials before inserting
      String? initials;
      if (mounted) initials = await _promptInitials();
      await db.insertRental(Rental(
        itemTypeId: typeId,
        itemNumber: itemNumber,
        openedByGa: gaNumber,
        customerInitials: initials,
        startTime: DateTime.now(),
        status: RentalStatus.active,
        date: today,
        location: location,
      ));
    }
    await _loadData();
  }

  // V2: export today's rentals as JSON
  Future<void> _export() async {
    try {
      final path = await ExportService.exportTodayAsJson();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $path'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String _formatRevenue(int pence) {
    final pounds = pence ~/ 100;
    final p = pence % 100;
    return '£$pounds.${p.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConfig.currentLocation.displayName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              'GA ${AppConfig.currentGaNumber} — ${AppConfig.currentGaName}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
        actions: [
          // V3: per-GA stats
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'My Stats',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
          // V3: team goals
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Goals',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'switch':
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const GASelectScreen()));
                case 'export':
                  _export();
                case 'settings':
                  await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  _loadData();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'switch',
                  child: Row(children: [
                    Icon(Icons.swap_horiz, size: 20),
                    SizedBox(width: 8),
                    Text('Switch GA')
                  ])),
              PopupMenuItem(
                  value: 'export',
                  child: Row(children: [
                    Icon(Icons.download_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export today')
                  ])),
              PopupMenuItem(
                  value: 'settings',
                  child: Row(children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Settings')
                  ])),
            ],
          ),
        ],
        bottom: _loading || _types.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: _types.length > 3,
                tabs: _types.map((t) {
                  final active = _activeMap[t.id]?.length ?? 0;
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.displayName),
                        if (active > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$active',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_unverifiedCount > 0)
                  _UnverifiedBanner(
                    count: _unverifiedCount,
                    onTap: () async {
                      await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ReviewScreen()));
                      _loadData();
                    },
                  ),
                Expanded(
                  child: _types.isEmpty
                      ? const Center(child: Text('No inventory configured.'))
                      : TabBarView(
                          controller: _tabController,
                          children: _types
                              .map((type) => ItemGrid(
                                    totalCount: type.totalCount,
                                    activeNumbers:
                                        _activeMap[type.id] ?? {},
                                    missingNumbers:
                                        _missingMap[type.id] ?? {},
                                    onTap: (n) =>
                                        _handleBubbleTap(type.id, n),
                                  ))
                              .toList(),
                        ),
                ),
                _StatsFooter(
                  activeCount: _activeCount,
                  todayCount: _todayCount,
                  todayRevenuePence: _todayRevenuePence,
                  formatRevenue: _formatRevenue,
                ),
              ],
            ),
    );
  }
}

class _UnverifiedBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _UnverifiedBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: Colors.orange.shade700,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$count rental${count == 1 ? '' : 's'} from yesterday need review',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _StatsFooter extends StatelessWidget {
  final int activeCount;
  final int todayCount;
  final int todayRevenuePence;
  final String Function(int) formatRevenue;

  const _StatsFooter({
    required this.activeCount,
    required this.todayCount,
    required this.todayRevenuePence,
    required this.formatRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(
              label: 'Out now',
              value: '$activeCount',
              color: Colors.green.shade600),
          _Stat(label: 'Today', value: '$todayCount'),
          _Stat(
              label: 'Revenue',
              value: formatRevenue(todayRevenuePence),
              color: Colors.blue.shade700),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}
