import 'package:flutter/material.dart';

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
    return Expanded(
      
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: 15),
            onPressed: amount > 1 ? decrementAmount : null,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 10, minHeight: 10),
          ),
          SizedBox(
            width: 15,
            child: Center(
              child: Text(
                amount.toString(),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Container(
            
            child: IconButton(
              icon: Icon(Icons.add, size: 15),
              onPressed: incrementAmount,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 10, minHeight: 10),
            ),
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
