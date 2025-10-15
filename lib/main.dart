import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/screens/splashScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/welcomeScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/homePage.dart';
import 'package:nhom_3_damh_lttbdd/screens/loginScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // file này tự động sinh ra khi bạn chạy flutterfire configure
Future<void> main() async {
  // Khởi tạo Flutter & Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triply',
      debugShowCheckedModeBanner: false, // Ẩn banner "Debug"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),

      // Màn hình đầu tiên khi mở app
      initialRoute: '/',

      // Định nghĩa các routes
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/home': (context) => HomePage(),
      },
    );
  }
}