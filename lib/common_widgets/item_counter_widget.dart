import 'package:flutter/material.dart';

class ItemCounterWidget extends StatefulWidget {
  final Function(int) onAmountChanged;
  final int amount;
  final double scale;

  const ItemCounterWidget({
    super.key,
    required this.onAmountChanged,
    required this.amount,
    this.scale = 1.0,
  });

  @override
  _ItemCounterWidgetState createState() => _ItemCounterWidgetState();
}

class _ItemCounterWidgetState extends State<ItemCounterWidget> {
  late int amount;

  @override
  void initState() {
    super.initState();
    amount = widget.amount;
  }

  @override
  void didUpdateWidget(ItemCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount != amount) {
      setState(() {
        amount = widget.amount;
      });
    }
  }

  void incrementAmount() {
    setState(() {
      amount++;
      widget.onAmountChanged(amount);
    });
  }

  void decrementAmount() {
    if (amount > 0) {
      setState(() {
        amount--;
        widget.onAmountChanged(amount);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final double baseHeight = 32 * widget.scale;
    final double iconSize = 16 * widget.scale;
    final double buttonSize = 28 * widget.scale;
    final double horizontalPadding = 4 * widget.scale;

    return Container(
      height: baseHeight,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(30 * widget.scale),
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            context,
            icon: Icons.remove,
            onPressed: amount > 0 ? decrementAmount : null,
            buttonSize: buttonSize,
            iconSize: iconSize,
          ),
          SizedBox(
            width: 28 * widget.scale,
            child: Center(
              // AnimatedSwitcher for smooth number transitions
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Text(
                  amount.toString(),
                  key: ValueKey<int>(amount),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                    fontSize: 14 * widget.scale,
                  ),
                ),
              ),
            ),
          ),
          _buildActionButton(
            context,
            icon: Icons.add,
            onPressed: incrementAmount,
            buttonSize: buttonSize,
            iconSize: iconSize,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required double buttonSize,
    required double iconSize,
    VoidCallback? onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: colorScheme.onPrimary.withValues(
          alpha: onPressed == null ? 0.1 : 0.2,
        ),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(icon, size: iconSize, color: colorScheme.onPrimary),
        ),
      ),
    );
  }
}
