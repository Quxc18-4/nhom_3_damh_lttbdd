// File: screens/startup/widget/welcome_widgets.dart

import 'package:flutter/material.dart';

// === WIDGET 1: HEADER ẢNH ===
class WelcomeHeaderImage extends StatelessWidget {
  const WelcomeHeaderImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/images/Vietnam_landscape.png',
          width: double.infinity,
          height: 330,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 280,
              color: Colors.teal,
              child: const Icon(Icons.image, size: 80, color: Colors.white),
            );
          },
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 0, // Chiều cao 0? -> Giữ nguyên theo code gốc
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// === WIDGET 2: DROP DOWN CHỌN QUỐC GIA ===
class CountrySelector extends StatelessWidget {
  final String? selectedCountry;
  final List<Map<String, String>> countries;
  final ValueChanged<String?> onChanged;

  const CountrySelector({
    Key? key,
    required this.selectedCountry,
    required this.countries,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vị trí của bạn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedCountry,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: countries.map((country) {
                return DropdownMenuItem<String>(
                  value: country["name"],
                  child: Row(
                    children: [
                      Text(
                        country["flag"]!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        country["name"]!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// === WIDGET 3: DROP DOWN CHỌN NGÔN NGỮ ===
class LanguageSelector extends StatelessWidget {
  final String? selectedLanguage;
  final List<Map<String, String>> languages;
  final ValueChanged<String?> onChanged;

  const LanguageSelector({
    Key? key,
    required this.selectedLanguage,
    required this.languages,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngôn ngữ ưu tiên của bạn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedLanguage,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: languages.map((language) {
                return DropdownMenuItem<String>(
                  value: language["name"],
                  child: Text(
                    language["name"]!,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// === WIDGET 4: CÁC NÚT BẤM (TẠO TÀI KHOẢN, ĐĂNG NHẬP) ===
class ActionButtons extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  const ActionButtons({
    Key? key,
    required this.onCreateAccount,
    required this.onLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onCreateAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB74D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Tạo tài khoản mới',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: onLogin,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFB74D), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFB74D),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
