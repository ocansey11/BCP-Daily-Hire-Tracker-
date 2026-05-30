import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/ga.dart';
import '../services/shift_service.dart';
import '../services/settings_service.dart';
import '../config/app_config.dart';
import 'home_screen.dart';

class GASelectScreen extends StatefulWidget {
  const GASelectScreen({super.key});

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
    final gas = await DatabaseHelper.instance.getGAs();
    setState(() {
      _gas = gas;
      _loading = false;
    });
  }

  Future<void> _selectGA(GA ga) async {
    await ShiftService.startShift(ga);
    if (!mounted) return;
    // V3: pass greeting to home screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            HomeScreen(greetingMessage: 'Welcome back, ${ga.displayName}!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Who are you?'),
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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _gas.length,
                    itemBuilder: (_, i) {
                      final ga = _gas[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade700,
                            child: Text(
                              '#${ga.gaNumber}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(ga.displayName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectGA(ga),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
