import 'package:flutter/material.dart';

class SubscriptionTable extends StatefulWidget {
  @override
  State<SubscriptionTable> createState() => _SubscriptionTableState();
}

class _SubscriptionTableState extends State<SubscriptionTable> {
  double _scale = 1.0;
  final double _minScale = 0.8;
  final double _maxScale = 1.5;

  // Sample data structure - This would come from your backend
  final List<Map<String, dynamic>> tableData = [
    {
      'rowName': 'Duration',
      'aarambh': '1 month',
      'pathik': '3 months',
      'tapasvi': '6 months',
      'siddh': '12 months',
    },
    {
      'rowName': 'Pricing',
      'aarambh': 'For 15 days',
      'pathik': '15% + 8% off',
      'tapasvi': '15% + 12% off',
      'siddh': '15% + 18% off',
    },
    {
      'rowName': 'Tagline',
      'aarambh': 'Try Before Trust',
      'pathik': 'Gut Cleanse',
      'tapasvi': 'Clean Habits',
      'siddh': 'Max Savings, Max Healing',
    },
  ];

  // Sample eligible products - This would come from your backend
  final Map<String, List<String>> eligibleProducts = {
    'aarambh': ['Organic Fruits', 'Fresh Vegetables', 'Mixed Basket'],
    'pathik': [
      'Organic Fruits',
      'Fresh Vegetables',
      'Mixed Basket',
      'Seasonal Fruits',
    ],
    'tapasvi': [
      'Organic Fruits',
      'Fresh Vegetables',
      'Mixed Basket',
      'Seasonal Fruits',
      'Organic Greens',
    ],
    'siddh': [
      'Organic Fruits',
      'Fresh Vegetables',
      'Mixed Basket',
      'Seasonal Fruits',
      'Organic Greens',
      'Exotic Fruits',
      'Local Produce',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Zoom controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.zoom_out),
                onPressed: () {
                  setState(() {
                    _scale = (_scale - 0.1).clamp(_minScale, _maxScale);
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.zoom_in),
                onPressed: () {
                  setState(() {
                    _scale = (_scale + 0.1).clamp(_minScale, _maxScale);
                  });
                },
              ),
            ],
          ),
        ),
        // Table
        Transform.scale(
          scale: _scale,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              columnWidths: {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(2),
              },
              children: [
                // Header row
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                  ),
                  children: [
                    _buildHeaderCell('AARAMBH'),
                    _buildHeaderCell('PATHIK'),
                    _buildHeaderCell('TAPASVI'),
                    _buildHeaderCell('SIDDH'),
                  ],
                ),
                // Data rows
                ...tableData.map(
                  (row) => TableRow(
                    children: [
                      _buildDataCell(row['aarambh']),
                      _buildDataCell(row['pathik']),
                      _buildDataCell(row['tapasvi']),
                      _buildDataCell(row['siddh']),
                    ],
                  ),
                ),
                // Products dropdown row
                TableRow(
                  children: [
                    _buildProductDropdownCell('aarambh'),
                    _buildProductDropdownCell('pathik'),
                    _buildProductDropdownCell('tapasvi'),
                    _buildProductDropdownCell('siddh'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildProductDropdownCell(String plan) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          isExpanded: true,
          underline: SizedBox(),
          hint: Text('Select Product'),
          items:
              eligibleProducts[plan]?.map((String product) {
                return DropdownMenuItem<String>(
                  value: product,
                  child: Text(product, style: TextStyle(fontSize: 14)),
                );
              }).toList(),
          onChanged: (String? newValue) {
            // Handle product selection
            print('Selected $newValue for $plan');
          },
        ),
      ),
    );
  }
}
