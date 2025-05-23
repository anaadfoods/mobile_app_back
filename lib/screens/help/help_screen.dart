import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  final String? orderNumber;

  const HelpScreen({Key? key, this.orderNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help & Support'), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (orderNumber != null) ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Reference',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Order #$orderNumber',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
              Text('Contact Us', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              _buildContactCard(
                context,
                icon: Icons.phone,
                title: 'Phone Support',
                subtitle: 'Available Mon-Sat, 9 AM - 6 PM',
                action: '+91 1234567890',
                onTap: () {
                  // TODO: Implement phone call
                },
              ),
              SizedBox(height: 12),
              _buildContactCard(
                context,
                icon: Icons.email,
                title: 'Email Support',
                subtitle: 'We\'ll respond within 24 hours',
                action: 'support@anaadfoods.com',
                onTap: () {
                  // TODO: Implement email
                },
              ),
              SizedBox(height: 12),
              _buildContactCard(
                context,
                icon: Icons.chat,
                title: 'WhatsApp Support',
                subtitle: 'Chat with us directly',
                action: 'Chat Now',
                onTap: () {
                  // TODO: Implement WhatsApp
                },
              ),
              SizedBox(height: 24),
              Text(
                'Frequently Asked Questions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              _buildFAQExpansionTile(
                'How can I track my order?',
                'You can track your order in the Orders section. We\'ll also send you updates via SMS and email.',
              ),
              _buildFAQExpansionTile(
                'What is your return policy?',
                'We have a 7-day return policy for unopened items. Please contact our support team for assistance.',
              ),
              _buildFAQExpansionTile(
                'How long does delivery take?',
                'Delivery typically takes 2-3 business days depending on your location.',
              ),
              _buildFAQExpansionTile(
                'Can I cancel my order?',
                'You can cancel your order if it hasn\'t been shipped yet. Go to order details and use the cancel button.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).primaryColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Text(
                action,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQExpansionTile(String title, String content) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              content,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
