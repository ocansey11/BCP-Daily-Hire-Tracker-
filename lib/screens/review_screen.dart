import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../models/rental.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<Rental> _rentals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rentals = await DatabaseHelper.instance.getUnverifiedRentals(
      AppConfig.currentLocation.id,
    );
    setState(() {
      _rentals = rentals;
      _loading = false;
    });
  }

  Future<void> _markReturned(Rental rental) async {
    await DatabaseHelper.instance.updateRental(
      rental.copyWith(status: RentalStatus.closedConfirmedAfterReview),
    );
    setState(() => _rentals.removeWhere((r) => r.id == rental.id));
  }

  Future<void> _markMissing(Rental rental) async {
    await DatabaseHelper.instance.updateRental(
      rental.copyWith(status: RentalStatus.missing),
    );
    setState(() => _rentals.removeWhere((r) => r.id == rental.id));
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Morning Review'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rentals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                      const SizedBox(height: 16),
                      const Text('All rentals reviewed.', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'These rentals were open at cutoff. Mark each one as returned or missing.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _rentals.length,
                        itemBuilder: (_, i) {
                          final rental = _rentals[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '#${rental.itemNumber}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        rental.itemTypeId,
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                                      ),
                                      const Spacer(),
                                      Text(
                                        rental.date,
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Rented at ${_formatTime(rental.startTime)} by GA ${rental.openedByGa}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.check, size: 18),
                                          label: const Text('Returned'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.green.shade700,
                                            side: BorderSide(color: Colors.green.shade400),
                                          ),
                                          onPressed: () => _markReturned(rental),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.search_off, size: 18),
                                          label: const Text('Missing'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red.shade700,
                                            side: BorderSide(color: Colors.red.shade300),
                                          ),
                                          onPressed: () => _markMissing(rental),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
