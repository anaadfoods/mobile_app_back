import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:device_preview/device_preview.dart';
// import 'package:grocery_app/services/deep_link_service.dart'; // Deprecated - Handled by GoRouter

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env"); // Already loaded above
  debugPrint('Loaded PANCHANG_BASE_URL=${dotenv.env["PANCHANG_BASE_URL"]}');
  // Get an instance of SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Check if the 'hasSeenWelcome' flag is true. If not, it defaults to false.
  final bool hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService().initializeAuthState();
  await NotificationHelper.initialize();
  await NotificationService().initialize(
    NotificationCubit(notificationRepository: NotificationRepository()),
  );

  // Get and print FCM token
  final notificationService = NotificationService();
  await notificationService.getFreshFCMToken();

  // Initialize deep link handling - MOVED TO GO_ROUTER
  // await DeepLinkService().initialize();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    DevicePreview(
      enabled: false, // for release mode set it to false
      builder: (context) {
        return MyApp(hasSeenWelcome: hasSeenWelcome);
      },
    ),
  );
}
