import 'package:flutter/material.dart';
import '../../models/beach_location.dart';

class LocationScreen extends StatefulWidget {
  final void Function(BeachLocation) onNext;
  const LocationScreen({super.key, required this.onNext});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  BeachLocation? _selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('Your Beach', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'This cannot be changed after setup.',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: BeachLocation.values.map((loc) {
                  final selected = _selected == loc;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: selected ? Colors.blue.shade50 : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected ? Colors.blue.shade700 : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      title: Text(loc.displayName),
                      trailing: selected
                          ? Icon(Icons.check_circle, color: Colors.blue.shade700)
                          : null,
                      onTap: () => setState(() => _selected = loc),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected == null ? null : () => widget.onNext(_selected!),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Next', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
