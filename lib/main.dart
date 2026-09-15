import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:device_preview/device_preview.dart';
// import 'package:grocery_app/services/deep_link_service.dart'; // Deprecated - Handled by GoRouter

import 'package:dio/dio.dart';
import 'package:grocery_app/core/analytics/analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  await dotenv.load(fileName: ".env");
  // await dotenv.load(fileName: ".env"); // Already loaded above
  debugPrint('Loaded PANCHANG_BASE_URL=${dotenv.env["PANCHANG_BASE_URL"]}');
  // Get an instance of SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Check if the 'hasSeenWelcome' flag is true. If not, it defaults to false.
  final bool hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await getIt<TokenService>().initializeAuthState();

  // Initialize AnalyticsService for customer activity, telemetry and product analytics
  try {
    final analyticsDio = Dio();
    await AnalyticsService().initialize(
      dio: analyticsDio,
      sutraBaseUrl: dotenv.env['SUTRA_BASE_URL'] ?? 'https://sutra-dev.anaadfoods.com',
      anaadBaseUrl: dotenv.env['API_BASE_URL'] ?? 'https://bck-dev.anaadfoods.com',
    );
    final currentUser = await getIt<TokenService>().getUserData();
    if (currentUser?.id != null) {
      AnalyticsService().identify(currentUser!.id!);
    }
  } catch (e) {
    debugPrint('AnalyticsService initialization error: $e');
  }

  await NotificationHelper.initialize();
  unawaited(getIt<NotificationService>().initialize(NotificationCubit()));

  // Initialize deep link handling - MOVED TO GO_ROUTER
  // await DeepLinkService().initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      systemNavigationBarColor: AppColors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  if (kDebugMode) {
    runApp(
      DevicePreview(
        enabled: false, // for release mode set it to false
        builder: (context) {
          return MyApp(hasSeenWelcome: hasSeenWelcome);
        },
      ),
    );
  } else {
    runApp(MyApp(hasSeenWelcome: hasSeenWelcome));
  }
}
