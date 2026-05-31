import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../models/ga.dart';
import '../services/stats_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _loading = true;
  int _weeklyGoalPence = 50000;
  int _teamRevenuePence = 0;
  List<_GAProgress> _gaProgress = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goalStr = await DatabaseHelper.instance.getSetting('weekly_goal_pence');
    final goal = goalStr != null ? int.parse(goalStr) : 50000;

    final weekStart = StatsService.weekStart;
    final today = StatsService.today;

    final teamRevenue = await DatabaseHelper.instance.sumRevenuePenceForPeriod(
      startDate: weekStart,
      endDate: today,
      location: AppConfig.currentLocation.id,
    );

    final teamStats = await StatsService.teamStatsByGA(weekStart, today);
    final gas = await DatabaseHelper.instance.getGAs();
    final gaMap = {for (final g in gas) g.gaNumber: g};

    final progress = teamStats.map((row) {
      final gaNum = row['opened_by_ga'] as int;
      final ga = gaMap[gaNum];
      return _GAProgress(
        gaNumber: gaNum,
        name: ga?.displayName ?? 'GA #$gaNum',
        revenuePence: (row['revenue_pence'] as int?) ?? 0,
        rentalCount: (row['rental_count'] as int?) ?? 0,
      );
    }).toList();

    setState(() {
      _weeklyGoalPence = goal;
      _teamRevenuePence = teamRevenue;
      _gaProgress = progress;
      _loading = false;
    });
  }

  Future<void> _editGoal() async {
    final ctrl = TextEditingController(
      text: (_weeklyGoalPence ~/ 100).toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Weekly Team Goal'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '£',
            border: OutlineInputBorder(),
            hintText: '500',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final pounds = int.tryParse(ctrl.text.trim());
              if (pounds != null && pounds > 0) Navigator.pop(ctx, pounds * 100);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await DatabaseHelper.instance.setSetting('weekly_goal_pence', result.toString());
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Goals'),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Set goal',
              onPressed: _editGoal),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TeamProgressCard(
                  goalPence: _weeklyGoalPence,
                  revenuePence: _teamRevenuePence,
                ),
                const SizedBox(height: 16),
                if (_gaProgress.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'TEAM BREAKDOWN',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                          letterSpacing: 1),
                    ),
                  ),
                  ..._gaProgress.map((p) => _GAProgressTile(
                        progress: p,
                        goalPence: _weeklyGoalPence,
                        isCurrentUser: AppConfig.isGaSet &&
                            p.gaNumber == AppConfig.currentGaNumber,
                      )),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'No closed rentals this week yet.',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TeamProgressCard extends StatelessWidget {
  final int goalPence;
  final int revenuePence;
  const _TeamProgressCard({required this.goalPence, required this.revenuePence});

  @override
  Widget build(BuildContext context) {
    final progress =
        goalPence > 0 ? (revenuePence / goalPence).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);
    final onTarget = progress >= 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Team This Week',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: onTarget ? Colors.green.shade100 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: onTarget ? Colors.green.shade700 : Colors.blue.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                    onTarget ? Colors.green.shade500 : Colors.blue.shade500),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(StatsService.formatPence(revenuePence),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text('Goal: ${StatsService.formatPence(goalPence)}',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GAProgressTile extends StatelessWidget {
  final _GAProgress progress;
  final int goalPence;
  final bool isCurrentUser;

  const _GAProgressTile({
    required this.progress,
    required this.goalPence,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final fraction =
        goalPence > 0 ? (progress.revenuePence / goalPence).clamp(0.0, 1.0) : 0.0;
    return Card(
      color: isCurrentUser ? Colors.blue.shade50 : null,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  isCurrentUser ? Colors.blue.shade700 : Colors.grey.shade300,
              child: Text(
                '#${progress.gaNumber}',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? Colors.white : Colors.grey.shade700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(progress.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(StatsService.formatPence(progress.revenuePence),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progress.rentalCount} rental${progress.rentalCount == 1 ? '' : 's'}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GAProgress {
  final int gaNumber;
  final String name;
  final int revenuePence;
  final int rentalCount;

  const _GAProgress({
    required this.gaNumber,
    required this.name,
    required this.revenuePence,
    required this.rentalCount,
  });
}
