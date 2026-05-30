import 'package:flutter/material.dart';
import 'item_bubble.dart';

class ItemGrid extends StatelessWidget {
  final int totalCount;
  final Set<int> activeNumbers;
  final Set<int> missingNumbers;
  final void Function(int number) onTap;

  const ItemGrid({
    super.key,
    required this.totalCount,
    required this.activeNumbers,
    required this.missingNumbers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) {
      return const Center(
        child: Text('No items configured for this beach.'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount(totalCount),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: totalCount,
      itemBuilder: (_, i) {
        final number = i + 1;
        return ItemBubble(
          number: number,
          isActive: activeNumbers.contains(number),
          isMissing: missingNumbers.contains(number),
          onTap: onTap,
        );
      },
    );
  }

  int _crossAxisCount(int total) {
    if (total <= 20) return 4;
    if (total <= 50) return 6;
    return 8;
  }
}
