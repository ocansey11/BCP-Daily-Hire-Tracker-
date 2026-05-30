import 'package:flutter/material.dart';
import '../../models/ga.dart';

class GASetupScreen extends StatefulWidget {
  final void Function(List<GA>) onFinish;
  const GASetupScreen({super.key, required this.onFinish});

  @override
  State<GASetupScreen> createState() => _GASetupScreenState();
}

class _GASetupScreenState extends State<GASetupScreen> {
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final List<GA> _gas = [];
  String? _error;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addGA() {
    final number = int.tryParse(_numberCtrl.text.trim());
    final name = _nameCtrl.text.trim();
    if (number == null || name.isEmpty) {
      setState(() => _error = 'Enter a valid number and name.');
      return;
    }
    if (_gas.any((g) => g.gaNumber == number)) {
      setState(() => _error = 'GA #$number already added.');
      return;
    }
    setState(() {
      _gas.add(GA(gaNumber: number, displayName: name));
      _numberCtrl.clear();
      _nameCtrl.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('Team Setup', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Add the GAs who will use this device.', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _numberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'GA #',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addGA(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _addGA,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(minimumSize: const Size(48, 56)),
                ),
              ],
            ),
            if (_error != null) ...
              [
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
              ],
            const SizedBox(height: 16),
            Expanded(
              child: _gas.isEmpty
                  ? Center(
                      child: Text('No GAs added yet.', style: TextStyle(color: Colors.grey.shade400)),
                    )
                  : ListView.builder(
                      itemCount: _gas.length,
                      itemBuilder: (_, i) {
                        final ga = _gas[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('#${ga.gaNumber}')),
                            title: Text(ga.displayName),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              onPressed: () => setState(() => _gas.removeAt(i)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _gas.isEmpty ? null : () => widget.onFinish(_gas),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Finish Setup', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
