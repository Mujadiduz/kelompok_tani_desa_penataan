import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'pages/splash_screen_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Inisialisasi notifikasi
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kelompok Tani Desa Penataan',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const SplashScreenPage(),
    );
  }
}
