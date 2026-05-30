import 'package:flutter/material.dart';

class ItemBubble extends StatefulWidget {
  final int number;
  final bool isActive;
  final bool isMissing;
  final void Function(int number) onTap;

  const ItemBubble({
    super.key,
    required this.number,
    required this.isActive,
    required this.isMissing,
    required this.onTap,
  });

  @override
  State<ItemBubble> createState() => _ItemBubbleState();
}

class _ItemBubbleState extends State<ItemBubble> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    final now = DateTime.now();
    // 500ms debounce
    if (_lastTap != null && now.difference(_lastTap!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastTap = now;
    _animController.forward().then((_) => _animController.reverse());
    widget.onTap(widget.number);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMissing) {
      return Tooltip(
        message: 'Item #${widget.number} marked missing',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red.shade300, width: 2),
          ),
          child: Center(
            child: Text(
              '${widget.number}',
              style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    final bgColor = widget.isActive ? Colors.green.shade500 : Colors.grey.shade200;
    final textColor = widget.isActive ? Colors.white : Colors.grey.shade700;

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: widget.isActive
                ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(
              '${widget.number}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
