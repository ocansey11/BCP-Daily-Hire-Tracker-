import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/stats_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;
  late ({int count, int revenuePence}) _today;
  late ({int count, int revenuePence}) _week;
  late ({int count, int revenuePence}) _month;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final gaNumber = AppConfig.currentGaNumber;
    final todayStr = StatsService.today;
    final weekStr = StatsService.weekStart;
    final monthStr = StatsService.monthStart;

    final results = await Future.wait([
      StatsService.statsForPeriod(startDate: todayStr, endDate: todayStr, gaNumber: gaNumber),
      StatsService.statsForPeriod(startDate: weekStr, endDate: todayStr, gaNumber: gaNumber),
      StatsService.statsForPeriod(startDate: monthStr, endDate: todayStr, gaNumber: gaNumber),
    ]);

    setState(() {
      _today = results[0];
      _week = results[1];
      _month = results[2];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Stats')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade700,
                          child: Text(
                            '#${AppConfig.currentGaNumber}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppConfig.currentGaName,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            Text(AppConfig.currentLocation.displayName,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _StatPeriodCard(
                    period: 'TODAY',
                    count: _today.count,
                    revenuePence: _today.revenuePence,
                    color: Colors.blue.shade700),
                const SizedBox(height: 8),
                _StatPeriodCard(
                    period: 'THIS WEEK',
                    count: _week.count,
                    revenuePence: _week.revenuePence,
                    color: Colors.green.shade700),
                const SizedBox(height: 8),
                _StatPeriodCard(
                    period: 'THIS MONTH',
                    count: _month.count,
                    revenuePence: _month.revenuePence,
                    color: Colors.purple.shade700),
              ],
            ),
    );
  }
}

class _StatPeriodCard extends StatelessWidget {
  final String period;
  final int count;
  final int revenuePence;
  final Color color;

  const _StatPeriodCard({
    required this.period,
    required this.count,
    required this.revenuePence,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count',
                          style: TextStyle(
                              fontSize: 34, fontWeight: FontWeight.bold, color: color)),
                      Text('rentals', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StatsService.formatPence(revenuePence),
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold, color: color),
                      ),
                      Text('revenue', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
