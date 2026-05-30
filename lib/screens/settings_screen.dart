import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../models/ga.dart';
import '../models/inventory_type.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<GA> _gas = [];
  List<InventoryType> _types = [];
  int _cutoffHour = 18;
  int _cutoffMinute = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final gas = await db.getGAs();
    final types = await db.getInventoryTypes(includeArchived: true);
    final cutoff = await SettingsService.getCutoffTime();
    setState(() {
      _gas = gas;
      _types = types;
      _cutoffHour = cutoff.hour;
      _cutoffMinute = cutoff.minute;
      _loading = false;
    });
  }

  // --- GA management ---

  void _showAddGADialog() {
    final numCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add GA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'GA Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final num = int.tryParse(numCtrl.text.trim());
              final name = nameCtrl.text.trim();
              if (num == null || name.isEmpty) return;
              await DatabaseHelper.instance.insertGA(GA(gaNumber: num, displayName: name));
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGA(GA ga) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove GA?'),
        content: Text('Remove ${ga.displayName} (GA #${ga.gaNumber})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteGA(ga.gaNumber);
      _load();
    }
  }

  // --- Inventory management ---

  void _showEditInventoryDialog(InventoryType type) {
    final countCtrl = TextEditingController(text: type.totalCount.toString());
    final priceCtrl = TextEditingController(text: (type.pricePence / 100).toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${type.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total count', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price', prefixText: '£', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newCount = int.tryParse(countCtrl.text.trim());
              final newPricePounds = double.tryParse(priceCtrl.text.trim());
              if (newCount == null || newPricePounds == null) return;

              final location = AppConfig.currentLocation.id;
              // Guard: cannot reduce below current active count
              final activeRentals = await DatabaseHelper.instance.getActiveRentalsForType(type.id, location);
              if (newCount < activeRentals.length) {
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Return ${type.displayName}s ${activeRentals.map((r) => '#${r.itemNumber}').join(', ')} first.',
                    ),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
                return;
              }

              final newPricePence = (newPricePounds * 100).round();
              await DatabaseHelper.instance.logInventoryChange(
                changeType: 'edit',
                itemTypeId: type.id,
                location: location,
                oldValue: '${type.totalCount}/${type.pricePence}',
                newValue: '$newCount/$newPricePence',
                changedByGa: AppConfig.isGaSet ? AppConfig.currentGaNumber : null,
              );
              await DatabaseHelper.instance.updateInventoryType(
                type.copyWith(totalCount: newCount, pricePence: newPricePence),
              );
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveType(InventoryType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Archive ${type.displayName}?'),
        content: const Text('This item type will be hidden from the home screen but rental history will be preserved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Archive')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.updateInventoryType(type.copyWith(isArchived: true));
      _load();
    }
  }

  Future<void> _unarchiveType(InventoryType type) async {
    await DatabaseHelper.instance.updateInventoryType(type.copyWith(isArchived: false));
    _load();
  }

  // --- Cutoff time ---

  Future<void> _showCutoffPicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _cutoffHour, minute: _cutoffMinute),
      helpText: 'Set end-of-day cutoff',
    );
    if (picked != null) {
      await SettingsService.setCutoffTime(picked.hour, picked.minute);
      setState(() {
        _cutoffHour = picked.hour;
        _cutoffMinute = picked.minute;
      });
    }
  }

  String _cutoffDisplay() {
    final h = _cutoffHour.toString().padLeft(2, '0');
    final m = _cutoffMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Location (read-only)
                _SectionHeader('Beach Location'),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(AppConfig.currentLocation.displayName),
                  subtitle: const Text('Cannot be changed'),
                  trailing: const Icon(Icons.lock_outline, size: 18),
                ),
                const Divider(),

                // Cutoff time
                _SectionHeader('End-of-Day Cutoff'),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Auto-close time'),
                  trailing: Text(_cutoffDisplay(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: _showCutoffPicker,
                ),
                const Divider(),

                // GAs
                _SectionHeader('General Assistants'),
                ..._gas.map((ga) => ListTile(
                  leading: CircleAvatar(child: Text('#${ga.gaNumber}', style: const TextStyle(fontSize: 12))),
                  title: Text(ga.displayName),
                  trailing: ga.gaNumber == (AppConfig.isGaSet ? AppConfig.currentGaNumber : -1)
                      ? const Chip(label: Text('You'))
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteGA(ga),
                        ),
                )),
                ListTile(
                  leading: const Icon(Icons.person_add_outlined),
                  title: const Text('Add GA'),
                  onTap: _showAddGADialog,
                ),
                const Divider(),

                // Inventory
                _SectionHeader('Inventory'),
                ..._types.map((type) => ListTile(
                  title: Text(
                    type.displayName,
                    style: TextStyle(
                      color: type.isArchived ? Colors.grey.shade400 : null,
                      decoration: type.isArchived ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text('${type.totalCount} items · ${type.priceDisplay}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!type.isArchived)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditInventoryDialog(type),
                        ),
                      if (!type.isDefault && !type.isArchived)
                        IconButton(
                          icon: const Icon(Icons.archive_outlined),
                          onPressed: () => _archiveType(type),
                        ),
                      if (type.isArchived)
                        TextButton(
                          onPressed: () => _unarchiveType(type),
                          child: const Text('Restore'),
                        ),
                    ],
                  ),
                )),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1),
      ),
    );
  }
}
