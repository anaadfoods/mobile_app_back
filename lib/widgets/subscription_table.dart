import 'package:flutter/material.dart';

class SubscriptionTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade300),
            ),
            columnWidths: const {
              0: FixedColumnWidth(80),
              1: FixedColumnWidth(100),
              2: FixedColumnWidth(100),
              3: FixedColumnWidth(130),
              4: FixedColumnWidth(180),
              5: FixedColumnWidth(50),
            },
            children: [
              _buildTableRow("Active","Plan", "Duration", "Pricing", "Tagline",
                  Icon(Icons.link, color: Colors.white),
                  isHeader: true),
              _buildTableRow( "No","AARAMBH", "1 month", "For 15 days",
                  "Try Before Trust", Icon(Icons.link, color: Colors.green)),
              _buildTableRow("No","PATHIK", "3 months", "15% + 8% off", "Gut Cleanse",
                  Icon(Icons.link, color: Colors.green)),
              _buildTableRow("No","TAPASVI", "6 months", "15% + 12% off",
                  "Clean Habits", Icon(Icons.link, color: Colors.green)),
              _buildTableRow("No","SIDDH", "12 months", "15% + 18% off",
                  "Max Savings, Max Healing", Icon(Icons.link, color: Colors.green)),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(
    String col6,
    String col1,
    String col2,
    String col3,
    String col4,
    Icon col5, {
    bool isHeader = false,
  }) {
    final textStyle = TextStyle(
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      fontSize: isHeader ? 16 : 14,
      color: isHeader ? Colors.white : Colors.black87,
    );

    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFF4CAF50) : Colors.transparent,
      ),
      children: [
        _buildCell(col6, textStyle),
        _buildCell(col1, textStyle),
        _buildCell(col2, textStyle),
        _buildCell(col3, textStyle),
        _buildCell(col4, textStyle),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(child: col5),
        ),
      ],
    );
  }

  Widget _buildCell(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: style,
        textAlign: TextAlign.center,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
