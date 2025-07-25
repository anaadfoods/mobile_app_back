import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_badge_widget.dart';
import '../../helpers/snackbar_helper.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _orderNotifications = true;
  bool _productNotifications = true;
  bool _promoNotifications = true;
  bool _subscriptionNotifications = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  bool _quietHours = false;
  TimeOfDay _quietStartTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEndTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderNotifications = prefs.getBool('order_notifications') ?? true;
      _productNotifications = prefs.getBool('product_notifications') ?? true;
      _promoNotifications = prefs.getBool('promo_notifications') ?? true;
      _subscriptionNotifications =
          prefs.getBool('subscription_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? false;
      _smsNotifications = prefs.getBool('sms_notifications') ?? false;
      _quietHours = prefs.getBool('quiet_hours') ?? false;

      int startHour = prefs.getInt('quiet_start_hour') ?? 22;
      int startMinute = prefs.getInt('quiet_start_minute') ?? 0;
      int endHour = prefs.getInt('quiet_end_hour') ?? 8;
      int endMinute = prefs.getInt('quiet_end_minute') ?? 0;

      _quietStartTime = TimeOfDay(hour: startHour, minute: startMinute);
      _quietEndTime = TimeOfDay(hour: endHour, minute: endMinute);
    });
  }

  Future<void> _saveNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('order_notifications', _orderNotifications);
    await prefs.setBool('product_notifications', _productNotifications);
    await prefs.setBool('promo_notifications', _promoNotifications);
    await prefs.setBool(
      'subscription_notifications',
      _subscriptionNotifications,
    );
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('sms_notifications', _smsNotifications);
    await prefs.setBool('quiet_hours', _quietHours);
    await prefs.setInt('quiet_start_hour', _quietStartTime.hour);
    await prefs.setInt('quiet_start_minute', _quietStartTime.minute);
    await prefs.setInt('quiet_end_hour', _quietEndTime.hour);
    await prefs.setInt('quiet_end_minute', _quietEndTime.minute);
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      await _notificationService.initialize();
      SnackBarHelper.showSuccess(context, 'Notification permissions updated');
    } catch (e) {
      SnackBarHelper.showError(context, 'Error updating permissions: $e');
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _quietStartTime : _quietEndTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _quietStartTime = picked;
        } else {
          _quietEndTime = picked;
        }
      });
      await _saveNotificationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _requestNotificationPermissions,
            tooltip: 'Refresh permissions',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Notification Types'),
            const SizedBox(height: 16),
            NotificationSettingsWidget(
              onOrderNotificationsChanged: (value) {
                setState(() {
                  _orderNotifications = value;
                });
                _saveNotificationSettings();
              },
              onProductNotificationsChanged: (value) {
                setState(() {
                  _productNotifications = value;
                });
                _saveNotificationSettings();
              },
              onPromoNotificationsChanged: (value) {
                setState(() {
                  _promoNotifications = value;
                });
                _saveNotificationSettings();
              },
              onSubscriptionNotificationsChanged: (value) {
                setState(() {
                  _subscriptionNotifications = value;
                });
                _saveNotificationSettings();
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Notification Channels'),
            const SizedBox(height: 16),
            _buildNotificationChannelCard(
              title: 'Push Notifications',
              subtitle: 'Receive notifications on your device',
              icon: Icons.notifications,
              color: Colors.blue,
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
                _saveNotificationSettings();
              },
            ),
            _buildNotificationChannelCard(
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              icon: Icons.email,
              color: Colors.green,
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
                _saveNotificationSettings();
              },
            ),
            _buildNotificationChannelCard(
              title: 'SMS Notifications',
              subtitle: 'Receive notifications via SMS',
              icon: Icons.sms,
              color: Colors.orange,
              value: _smsNotifications,
              onChanged: (value) {
                setState(() {
                  _smsNotifications = value;
                });
                _saveNotificationSettings();
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Quiet Hours'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bedtime,
                          color: Colors.purple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quiet Hours',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'Mute notifications during specified hours',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _quietHours,
                        onChanged: (value) {
                          setState(() {
                            _quietHours = value;
                          });
                          _saveNotificationSettings();
                        },
                        activeColor: Colors.purple,
                      ),
                    ],
                  ),
                  if (_quietHours) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeSelector(
                            'Start Time',
                            _quietStartTime,
                            (time) => _selectTime(context, true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeSelector(
                            'End Time',
                            _quietEndTime,
                            (time) => _selectTime(context, false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Notification Statistics'),
            const SizedBox(height: 16),
            _buildStatisticsCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('Actions'),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNotificationChannelCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onTap,
  ) {
    return GestureDetector(
      onTap: () => onTap(time),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Statistics',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'View your notification activity',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Today', '12'),
              _buildStatItem('This Week', '45'),
              _buildStatItem('This Month', '156'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to notification history
            },
            icon: const Icon(Icons.history),
            label: const Text('View Notification History'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Export notification settings
            },
            icon: const Icon(Icons.download),
            label: const Text('Export Settings'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              // TODO: Reset to default settings
            },
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Default'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
