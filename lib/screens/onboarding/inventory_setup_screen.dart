import 'package:flutter/material.dart';
import '../../models/inventory_type.dart';

class InventorySetupScreen extends StatefulWidget {
  final List<InventoryType> initialTypes;
  final void Function(List<InventoryType>) onNext;

  const InventorySetupScreen({
    super.key,
    required this.initialTypes,
    required this.onNext,
  });

  @override
  State<InventorySetupScreen> createState() => _InventorySetupScreenState();
}

class _InventorySetupScreenState extends State<InventorySetupScreen> {
  late List<InventoryType> _types;
  final Map<String, TextEditingController> _countControllers = {};

  @override
  void initState() {
    super.initState();
    _types = List.from(widget.initialTypes);
    for (final t in _types) {
      _countControllers[t.id] = TextEditingController(
        text: t.totalCount > 0 ? t.totalCount.toString() : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _countControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canProceed => _types.any((t) => t.totalCount > 0);

  void _updateCount(String id, String value) {
    final count = int.tryParse(value) ?? 0;
    setState(() {
      _types = _types.map((t) => t.id == id ? t.copyWith(totalCount: count) : t).toList();
    });
  }

  void _showAddCustomDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final countCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item name', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price (e.g. 5.00)', prefixText: '£', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: countCtrl,
              decoration: const InputDecoration(labelText: 'Total count', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final priceText = priceCtrl.text.trim();
              final count = int.tryParse(countCtrl.text.trim()) ?? 0;
              if (name.isEmpty || priceText.isEmpty || count <= 0) return;
              final pricePounds = double.tryParse(priceText) ?? 0;
              final pricePence = (pricePounds * 100).round();
              final id = name.toLowerCase().replaceAll(' ', '_');
              final newType = InventoryType(
                id: id,
                displayName: name,
                pricePence: pricePence,
                totalCount: count,
                isDefault: false,
              );
              setState(() {
                _types = [..._types, newType];
                _countControllers[id] = TextEditingController(text: count.toString());
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
            Text('Inventory', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Enter how many of each item your beach has.', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  ..._types.map((type) => _InventoryCard(
                    type: type,
                    controller: _countControllers[type.id]!,
                    onChanged: (v) => _updateCount(type.id, v),
                  )),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _showAddCustomDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add custom item'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canProceed ? () => widget.onNext(_types.where((t) => t.totalCount > 0).toList()) : null,
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

class _InventoryCard extends StatelessWidget {
  final InventoryType type;
  final TextEditingController controller;
  final void Function(String) onChanged;

  const _InventoryCard({
    required this.type,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(type.priceDisplay, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            SizedBox(
              width: 72,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  hintText: '0',
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
