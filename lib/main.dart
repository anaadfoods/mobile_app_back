import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';



Future<void> main() async {

  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  // Get an instance of SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Check if the 'hasSeenWelcome' flag is true. If not, it defaults to false.
  final bool hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService().initializeAuthState();
  await NotificationHelper.initialize();
  await NotificationService().initialize(
    NotificationCubit(notificationRepository: NotificationRepository())
  );


  // Get and print FCM token
  final notificationService = NotificationService();
  await notificationService.getFreshFCMToken();

  runApp(MyApp(hasSeenWelcome : hasSeenWelcome));
}


