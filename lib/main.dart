import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Login/OnBoarding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'Data/UserData.dart';
import 'Data/CourseData.dart';
import 'Home/HomePage.dart';
import 'Settings/search_history_provider.dart';
import 'package:provider/provider.dart';
import 'widgets/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Login/LoginPage.dart';
import 'FCM.dart';
import 'Settings/notifications_preferences.dart';
import 'package:flutter/services.dart';

final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  //await Hive.deleteFromDisk();
  final userBox = await Hive.openBox<UserData>('userBox');
  await userBox.deleteFromDisk(); 
  Hive.registerAdapter(UserDataAdapter());
  Hive.registerAdapter(CourseDataAdapter());
  await NotificationService.initialize();

  FirebaseMessaging.onBackgroundMessage(
    NotificationService.firebaseMessagingBackgroundHandler,
  );
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async{
    final notificationsEnabled = await NotificationPreferences.getNotificationsEnabled();
  
    if (notificationsEnabled) {
      await NotificationService.showNotification(message); 
    }
  });


  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
  print(isFirstLaunch);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SearchHistoryProvider()),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
          ), 
        ],
        child: MyApp(isFirstLaunch: isFirstLaunch),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: MyTheme.lightTheme, 
          darkTheme: MyTheme.darkTheme, 
          title: 'eecsync',
          home: isFirstLaunch ? OnboardingScreen() : LoginPage(),
        );
      },
    );
  }
}