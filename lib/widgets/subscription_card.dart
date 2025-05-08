import 'package:flutter/material.dart';

class SubscriptionCard extends StatelessWidget {
  final List<Map<String, String>> products = [
    {"name": "Banana", "type": "fruit"},
    {"name": "Apple", "type": "fruit"},
    {"name": "Pepper", "type": "fruit"},
  ];

   SubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Subscriptions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 4),
            Text(
              'AARAMBH',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                _buildButton(Icons.view_list, 'View Plan' , ()=> _showSubscriptionDetails(context)),
                SizedBox(width: 8),
                _buildButton(Icons.pause_circle_filled, 'Pause', ()=>print("Pause/ Play Subscription")),
              ],
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _showProductList(context);
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: Colors.indigo[900],
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildButton(IconData icon, String label, VoidCallback handleButton) {
  return ElevatedButton.icon(
    onPressed: handleButton,
    icon: Icon(icon, color: Colors.indigo[900], size: 18),
    label: Text(label, style: TextStyle(color: Colors.indigo[900])),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[200],
      shape: StadiumBorder(),
      elevation: 0,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
  );
}


  void _showProductList(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'All Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final item = products[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      item['name']![0],
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(item['name']!),
                  subtitle: Text(item['type']!),
                  trailing: IconButton(
                    icon: Icon(Icons.info_outline, color: Colors.indigo),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('More info about ${item['name']}'),
                      ));
                    },
                  ),
                  onTap: () {
                    // Optional tap behavior
                  },
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
void _showSubscriptionDetails(BuildContext context) {
  final Map<String, String> details = {
    'Time Remaining': '15 days',
    'Start Date': '2025-04-20',
    'End Date': '2025-05-20',
    'Money Paid': '\$49.99',
  };

  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Subscription Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 16),
            ...details.entries.map((entry) {
              return ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.indigo),
                title: Text(entry.key),
                subtitle: Text(entry.value),
              );
            }).toList(),
          ],
        ),
      );
    },
  );
}


}