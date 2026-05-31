import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/ga.dart';
import '../services/shift_service.dart';
import '../services/settings_service.dart';
import '../config/app_config.dart';
import 'home_screen.dart';

class GASelectScreen extends StatefulWidget {
  final bool isSwitchMode;
  const GASelectScreen({super.key, this.isSwitchMode = false});

  @override
  State<GASelectScreen> createState() => _GASelectScreenState();
}

class _GASelectScreenState extends State<GASelectScreen> {
  List<GA> _gas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SettingsService.initAppConfig();
    var gas = await DatabaseHelper.instance.getGAs();
    if (widget.isSwitchMode && AppConfig.isGaSet) {
      gas = gas.where((g) => g.gaNumber != AppConfig.currentGaNumber).toList();
    }
    setState(() {
      _gas = gas;
      _loading = false;
    });
  }

  Future<void> _selectGA(GA ga) async {
    await ShiftService.startShift(ga);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            HomeScreen(greetingMessage: 'Welcome back, ${ga.displayName}!'),
      ),
      (route) => false,
    );
  }

  Future<void> _showAddGADialog() async {
    final numCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final newGA = await showDialog<GA>(
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
              final ga = GA(gaNumber: num, displayName: name);
              await DatabaseHelper.instance.insertGA(ga);
              Navigator.pop(ctx, ga);
            },
            child: const Text('Add & Switch'),
          ),
        ],
      ),
    );
    if (newGA != null && mounted) {
      await _selectGA(newGA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSwitchMode ? 'Switch GA' : 'Who are you?'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (AppConfig.isLocationSet)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          AppConfig.currentLocation.displayName,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _gas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_off_outlined, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                widget.isSwitchMode
                                    ? 'No other GAs on shift.\nAdd a teammate to hand over.'
                                    : 'No GAs yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                icon: const Icon(Icons.person_add_outlined),
                                label: const Text('Add GA'),
                                onPressed: _showAddGADialog,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _gas.length,
                          itemBuilder: (_, i) {
                            final ga = _gas[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade700,
                                  child: Text(
                                    '#${ga.gaNumber}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(ga.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _selectGA(ga),
                              ),
                            );
                          },
                        ),
                ),
                if (_gas.isNotEmpty && widget.isSwitchMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextButton.icon(
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add GA'),
                      onPressed: _showAddGADialog,
                    ),
                  ),
              ],
            ),
    );
  }
}
