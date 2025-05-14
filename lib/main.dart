import 'package:flutter/material.dart';
import 'package:grocery_app/services/auth_service.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().initializeAuthState();
  runApp(MyApp());
}
