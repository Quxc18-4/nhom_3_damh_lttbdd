import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/screens/splashScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/welcomeScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/homePage.dart';
import 'package:nhom_3_damh_lttbdd/screens/loginScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // THÊM IMPORT NÀY
import 'firebase_options.dart';

Future<void> main() async {
  // Khởi tạo Flutter & Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // *****************************************************************
  // THÊM: Khởi tạo dữ liệu Locale cho Tiếng Việt ('vi_VN')
  // Việc này cần thiết vì HomePage sử dụng DateFormat('...', 'vi_VN')
  try {
    await initializeDateFormatting('vi_VN', null);
  } catch (e) {
    // Không nên crash nếu khởi tạo locale thất bại
    print('Lỗi khi khởi tạo định dạng ngày tháng cho vi_VN: $e');
  }
  // *****************************************************************

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triply',
      // Thêm locale để DateFormat hoạt động tốt hơn
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('vi', 'VN'), // HỖ TRỢ VIỆT NAM
      ],
      // Sử dụng delegate để tự động tải dữ liệu locale
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('vi', 'VN'), // Đặt locale mặc định là Tiếng Việt

      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        // Đảm bảo bạn có routes cho login và home nếu cần
        '/login': (context) => const LoginScreen(),
        '/home': (context) =>
            const HomePage(userId: 'guest'), // Cần truyền userId thực tế
      },
    );
  }
}
