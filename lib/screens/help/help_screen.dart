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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Reference',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Order #$orderNumber',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 22),
              ],
              Text(
                'Contact Us',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              SizedBox(height: 8),
              Divider(thickness: 1.2, color: Colors.grey[200]),
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
              SizedBox(height: 14),
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
              SizedBox(height: 14),
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
              SizedBox(height: 30),
              Text(
                'Frequently Asked Questions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              SizedBox(height: 8),
              Divider(thickness: 1.2, color: Colors.grey[200]),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildFAQExpansionTile(
                      'How can I track my order?',
                      'You can track your order in the Orders section. We\'ll also send you updates via SMS and email.',
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
              SizedBox(height: 30),
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
    final isEmail = icon == Icons.email;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              isEmail
                  ? Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alternate_email,
                          color: Theme.of(context).primaryColor,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            action,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                  : Text(
                    action,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Text(
              content,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
