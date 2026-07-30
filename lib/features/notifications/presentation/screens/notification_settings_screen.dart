import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _orderUpdates = true;
  bool _promotions = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive push alerts on your device'),
            value: _pushEnabled,
            onChanged: (val) => setState(() => _pushEnabled = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Order Updates'),
            subtitle: const Text('Get real-time updates on your order status'),
            value: _orderUpdates,
            onChanged: _pushEnabled
                ? (val) => setState(() => _orderUpdates = val)
                : null,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Promotions & Deals'),
            subtitle: const Text('Receive discounts and special offer alerts'),
            value: _promotions,
            onChanged: _pushEnabled
                ? (val) => setState(() => _promotions = val)
                : null,
          ),
        ],
      ),
    );
  }
}
