import 'package:flutter/material.dart';

class ItemCounterWidget extends StatefulWidget {
  final Function(int) onAmountChanged;
  final int amount;

  const ItemCounterWidget({
    Key? key,
    required this.onAmountChanged,
    required this.amount,
  }) : super(key: key);

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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: 20),
            onPressed: amount > 1 ? decrementAmount : null,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          Container(
            width: 30,
            child: Center(
              child: Text(
                amount.toString(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 20),
            onPressed: incrementAmount,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
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
