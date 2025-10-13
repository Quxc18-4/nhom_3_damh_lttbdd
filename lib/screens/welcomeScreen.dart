import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/constants/countries.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';



class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Danh sách quốc gia
  final countries = AppConstants.countries;
  final languages = AppConstants.languages;

  // Lựa chọn hiện tại
  String? selectedCountry = "Việt Nam";
  String? selectedLanguage = "Tiếng Việt";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Phần ảnh phía trên với hiệu ứng curved
            Stack(
              children: [
                // Ảnh
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
                      child: Icon(Icons.image, size: 80, color: Colors.white),
                    );
                  },
                ),
                // Curved white container overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 60,),
            // Phần nội dung
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Tiêu đề
                  Center(
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

                  // Mô tả
                  Center(
                    child: Text(
                      'Để tiếp tục, hãy chọn quốc gia và ngôn ngữ của bạn',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Vị trí của bạn
                  Text(
                    'Vị trí của bạn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Dropdown quốc gia
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
                        icon: Icon(Icons.keyboard_arrow_down),
                        items: countries.map((country) {
                          return DropdownMenuItem<String>(
                            value: country["name"],
                            child: Row(
                              children: [
                                Text(
                                  country["flag"]!,
                                  style: TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  country["name"]!,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCountry = value;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Ngôn ngữ ưu tiên của bạn
                  Text(
                    'Ngôn ngữ ưu tiên của bạn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Dropdown ngôn ngữ
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
                        icon: Icon(Icons.keyboard_arrow_down),
                        items: languages.map((language) {
                          return DropdownMenuItem<String>(
                            value: language["name"],
                            child: Text(
                              language["name"]!,
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedLanguage = value;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Nút Tạo tài khoản mới
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Xử lý tạo tài khoản
                        print('Country: $selectedCountry');
                        print('Language: $selectedLanguage');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFB74D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
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
                  // Nút Đăng nhập
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Xử lý đăng nhập
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFFFFB74D), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFB74D),
                        ),
                      ),
                    ),
                  ),

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
