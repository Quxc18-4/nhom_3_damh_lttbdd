// File: screens/startup/welcomeScreen.dart

import 'package:flutter/material.dart';
// Cập nhật đường dẫn
import 'package:nhom_3_damh_lttbdd/constants/countries.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
// Import các màn hình điều hướng
import 'package:nhom_3_damh_lttbdd/screens/authentication/login/loginScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/authentication/register/registerScreen.dart';
// Import widget đã tách
import 'widget/welcome_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Dữ liệu
  final countries = AppConstants.countries;
  final languages = AppConstants.languages;

  // State
  String? selectedCountry = "Việt Nam";
  String? selectedLanguage = "Tiếng Việt";

  // === HÀM XỬ LÝ ĐIỀU HƯỚNG ===
  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }
  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // === SỬ DỤNG WIDGET MỚI ===
            const WelcomeHeaderImage(),

            // =========================
            const SizedBox(height: 60),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Chào mừng bạn đến với Triply!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Để tiếp tục, hãy chọn quốc gia và ngôn ngữ của bạn',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // === SỬ DỤNG WIDGET MỚI ===
                  CountrySelector(
                    selectedCountry: selectedCountry,
                    countries: countries,
                    onChanged: (value) {
                      setState(() => selectedCountry = value);
                    },
                  ),

                  // =========================
                  const SizedBox(height: 24),

                  // === SỬ DỤNG WIDGET MỚI ===
                  LanguageSelector(
                    selectedLanguage: selectedLanguage,
                    languages: languages,
                    onChanged: (value) {
                      setState(() => selectedLanguage = value);
                    },
                  ),

                  // =========================
                  const SizedBox(height: 40),

                  // === SỬ DỤNG WIDGET MỚI ===
                  ActionButtons(
                    onCreateAccount: _navigateToRegister,
                    onLogin: _navigateToLogin,
                  ),

                  // =========================
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
