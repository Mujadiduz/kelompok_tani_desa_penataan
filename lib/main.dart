import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'pages/splash_screen_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryGreen = Color(0xff2E7D32);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaniGo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primaryGreen,
        scaffoldBackgroundColor: const Color(0xffF6FAF7),
      ),
      home: const SplashScreenPage(),
    );
  }
}