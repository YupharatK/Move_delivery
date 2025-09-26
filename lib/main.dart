import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:move_delivery/firebase_options.dart';
import 'package:move_delivery/pages/app_theme.dart';
import 'package:move_delivery/pages/welcome_screen.dart';

void main() async {
  // 1. ทำให้ main เป็น async
  WidgetsFlutterBinding.ensureInitialized(); // 2. บรรทัดนี้สำคัญมาก
  await Firebase.initializeApp(
    // 3. เรียกใช้และรอจนกว่าจะเชื่อมต่อสำเร็จ
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: AppTheme.theme,
      home: const WelcomeScreen(),
    );
  }
}
