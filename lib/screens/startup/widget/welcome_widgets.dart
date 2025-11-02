// File: screens/startup/widget/welcome_widgets.dart

import 'package:flutter/material.dart'; // Thư viện chính của Flutter

// === WIDGET 1: HEADER ẢNH ===
class WelcomeHeaderImage extends StatelessWidget { // Widget hiển thị ảnh nền chào mừng
  const WelcomeHeaderImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Stack( // Chồng các lớp lên nhau
      children: [
        Image.asset( // Ảnh nền phong cảnh
          'assets/images/Vietnam_landscape.png', // Đường dẫn ảnh
          width: double.infinity, // Chiếm toàn bộ chiều rộng
          height: 330, // Chiều cao cố định
          fit: BoxFit.cover, // Cắt ảnh vừa khung
          errorBuilder: (context, error, stackTrace) { // Nếu lỗi tải ảnh
            return Container( // Hiển thị khung thay thế
              width: double.infinity,
              height: 280,
              color: Colors.teal, // Màu nền xanh ngọc
              child: const Icon(Icons.image, size: 80, color: Colors.white), // Icon ảnh
            );
          },
        ),
        Positioned( // Lớp phủ ở dưới (bo góc)
          bottom: 0, // Căn dưới
          left: 0, // Căn trái
          right: 0, // Căn phải
          child: Container( // Khung bo góc
            height: 0, // Chiều cao 0? -> Giữ nguyên theo code gốc
            decoration: const BoxDecoration( // Trang trí
              color: Colors.white, // Màu trắng
              borderRadius: BorderRadius.only( // Bo 2 góc trên
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
class CountrySelector extends StatelessWidget { // Widget chọn quốc gia
  final String? selectedCountry; // Quốc gia đang chọn
  final List<Map<String, String>> countries; // Danh sách quốc gia
  final ValueChanged<String?> onChanged; // Hàm gọi khi thay đổi

  const CountrySelector({ // Constructor
    Key? key,
    required this.selectedCountry,
    required this.countries,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Column( // Cột dọc
      crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
      children: [
        Text( // Tiêu đề
          'Vị trí của bạn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12), // Khoảng cách
        Container( // Khung dropdown
          padding: const EdgeInsets.symmetric(horizontal: 16), // Padding ngang
          decoration: BoxDecoration(
            color: Colors.white, // Nền trắng
            borderRadius: BorderRadius.circular(12), // Bo góc
            border: Border.all(color: Colors.grey[300]!), // Viền xám nhạt
          ),
          child: DropdownButtonHideUnderline( // Ẩn gạch dưới mặc định
            child: DropdownButton<String>( // Dropdown chọn quốc gia
              isExpanded: true, // Chiếm toàn bộ chiều rộng
              value: selectedCountry, // Giá trị hiện tại
              icon: const Icon(Icons.keyboard_arrow_down), // Icon mũi tên
              items: countries.map((country) { // Tạo danh sách item
                return DropdownMenuItem<String>(
                  value: country["name"], // Giá trị là tên quốc gia
                  child: Row( // Dòng: cờ + tên
                    children: [
                      Text(
                        country["flag"]!, // Cờ (dạng emoji)
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12), // Khoảng cách
                      Text(
                        country["name"]!, // Tên quốc gia
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged, // Gọi hàm khi chọn
            ),
          ),
        ),
      ],
    );
  }
}

// === WIDGET 3: DROP DOWN CHỌN NGÔN NGỮ ===
class LanguageSelector extends StatelessWidget { // Widget chọn ngôn ngữ
  final String? selectedLanguage; // Ngôn ngữ đang chọn
  final List<Map<String, String>> languages; // Danh sách ngôn ngữ
  final ValueChanged<String?> onChanged; // Hàm gọi khi thay đổi

  const LanguageSelector({ // Constructor
    Key? key,
    required this.selectedLanguage,
    required this.languages,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Column( // Cột dọc
      crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
      children: [
        Text( // Tiêu đề
          'Ngôn ngữ ưu tiên của bạn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12), // Khoảng cách
        Container( // Khung dropdown
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>( // Dropdown chọn ngôn ngữ
              isExpanded: true,
              value: selectedLanguage,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: languages.map((language) { // Tạo danh sách item
                return DropdownMenuItem<String>(
                  value: language["name"], // Giá trị là tên ngôn ngữ
                  child: Text(
                    language["name"]!, // Chỉ hiển thị tên
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
class ActionButtons extends StatelessWidget { // Widget chứa 2 nút hành động
  final VoidCallback onCreateAccount; // Hàm khi nhấn "Tạo tài khoản"
  final VoidCallback onLogin; // Hàm khi nhấn "Đăng nhập"

  const ActionButtons({ // Constructor
    Key? key,
    required this.onCreateAccount,
    required this.onLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Column( // Cột dọc
      crossAxisAlignment: CrossAxisAlignment.stretch, // Chiếm toàn bộ chiều ngang
      children: [
        SizedBox( // Nút "Tạo tài khoản mới"
          width: double.infinity, // Chiếm toàn bộ chiều rộng
          height: 50, // Chiều cao cố định
          child: ElevatedButton( // Nút nền đầy
            onPressed: onCreateAccount, // Gọi hàm từ ngoài
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB74D), // Màu cam
              shape: RoundedRectangleBorder( // Bo góc
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0, // Không bóng
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
        const SizedBox(height: 16), // Khoảng cách giữa 2 nút
        SizedBox( // Nút "Đăng nhập"
          width: double.infinity,
          height: 50,
          child: OutlinedButton( // Nút viền
            onPressed: onLogin,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFB74D), width: 2), // Viền cam
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