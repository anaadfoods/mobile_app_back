import 'package:flutter/material.dart';
import 'package:grocery_app/styles/colors.dart';

class ItemCounterWidget extends StatefulWidget {
  final Function(int) onAmountChanged;
  final int amount;

  const ItemCounterWidget({
    super.key,
    required this.onAmountChanged,
    required this.amount,
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
  Widget build(BuildContext context) {
    return Container( // Outer Container for background and rounded corners
      decoration: BoxDecoration(
        color: AppColors.bottonBackgroundColor, // Background color from your image
        borderRadius: BorderRadius.circular(30), // Highly rounded corners
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5), // Inner padding
      child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min, // Keep the row content size minimal
        children: [
          _buildActionButton(
            icon: Icons.remove,
            onPressed: amount > 1 ? decrementAmount : null,
          ),
          const SizedBox(width: 8), // Spacing between button and text
          SizedBox(
            width: 30, // Fixed width for the number to ensure consistent spacing
            child: Center(
              child: Text(
                amount.toString(),
                style: const TextStyle(
                  fontSize: 18, // Slightly larger font for the number
                  fontWeight: FontWeight.w500,
                  color: Colors.white, // White text color
                ),
              ),
            ),
          ),
          const SizedBox(width: 8), // Spacing between text and button
          _buildActionButton(
            icon: Icons.add,
            onPressed: incrementAmount,
          ),
        ],
      ),
    );
  }

  // Helper method to build consistent circular action buttons
  Widget _buildActionButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      width: 36, // Fixed width for circular button
      height: 36, // Fixed height for circular button
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Slightly transparent white for the circles
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 20), // Slightly larger icon size
        onPressed: onPressed,
        color: Colors.white, // White icon color
        padding: EdgeInsets.zero, // Remove default padding
        constraints: const BoxConstraints(), // Remove default constraints
      ),
    );
  }

  void incrementAmount() {
    setState(() {
      amount = amount + 1;
      widget.onAmountChanged(amount);
    });
  }

  void decrementAmount() {
    if (amount <= 1) return;
    setState(() {
      amount = amount - 1;
      widget.onAmountChanged(amount);
    });
  }
}