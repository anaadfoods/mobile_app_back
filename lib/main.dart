import 'package:flutter/material.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/notification_service.dart';
import 'package:grocery_app/styles/theme.dart';
import 'package:grocery_app/helpers/notification_helper.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService().initializeAuthState();
  await NotificationHelper.initialize();
  await NotificationService().initialize();

  // Get and print FCM token
  final notificationService = NotificationService();
  await notificationService.getFreshFCMToken();

  runApp(const MyApp());
}
