import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/helpers/notification_helper.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';

class FCMTokenScreen extends StatefulWidget {
  const FCMTokenScreen({Key? key}) : super(key: key);

  @override
  State<FCMTokenScreen> createState() => _FCMTokenScreenState();
}

class _FCMTokenScreenState extends State<FCMTokenScreen> {
  String? _fcmToken;
  bool _isLoading = false;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  Future<void> _loadFCMToken() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? token = await NotificationHelper.getStoredFCMToken();
      setState(() {
        _fcmToken = token;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading FCM token: $e');
    }
  }

  Future<void> _refreshFCMToken() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? token = await NotificationHelper.getFCMToken();
      setState(() {
        _fcmToken = token;
        _isLoading = false;
      });

      if (token != null) {
        _showSuccessSnackBar('FCM token refreshed successfully!');
      } else {
        _showErrorSnackBar('Failed to get FCM token');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error refreshing FCM token: $e');
    }
  }

  Future<void> _copyToClipboard() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      setState(() {
        _isCopied = true;
      });
      _showSuccessSnackBar('FCM token copied to clipboard!');

      // Reset copied state after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isCopied = false;
          });
        }
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    SnackBarHelper.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    SnackBarHelper.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText(
          text: 'FCM Token',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryColor),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: 'Firebase Cloud Messaging Token',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 8),
            AppText(
              text:
                  'This token is used to send push notifications to your device.',
              fontSize: 14,
              color: Colors.grey[600]!,
            ),
            SizedBox(height: 30),

            // Token Display Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        text: 'Current Token:',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      if (_fcmToken != null)
                        IconButton(
                          onPressed: _copyToClipboard,
                          icon: Icon(
                            _isCopied ? Icons.check : Icons.copy,
                            color:
                                _isCopied
                                    ? Colors.green
                                    : AppColors.primaryColor,
                          ),
                          tooltip: 'Copy to clipboard',
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  else if (_fcmToken != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SelectableText(
                        _fcmToken!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: AppText(
                        text: 'No FCM token available',
                        fontSize: 14,
                        color: Colors.orange[700]!,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _refreshFCMToken,
                    icon: Icon(Icons.refresh),
                    label: Text(_isLoading ? 'Refreshing...' : 'Refresh Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _fcmToken != null ? _copyToClipboard : null,
                    icon: Icon(_isCopied ? Icons.check : Icons.copy),
                    label: Text(_isCopied ? 'Copied!' : 'Copy Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _fcmToken != null ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            // Information Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]!),
                      SizedBox(width: 8),
                      AppText(
                        text: 'Information',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700]!,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  AppText(
                    text:
                        '• This token is unique to your device\n'
                        '• It\'s automatically refreshed when needed\n'
                        '• Copy this token to test push notifications\n'
                        '• Keep this token secure',
                    fontSize: 14,
                    color: Colors.blue[700]!,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
