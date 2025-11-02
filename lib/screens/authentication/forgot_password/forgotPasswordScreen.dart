// File: screens/authentication/forgot_password/forgotPasswordScreen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import để bắt kiểu lỗi `FirebaseAuthException`

// Import Service và Widgets đã tách
import 'service/forgot_password_service.dart'; // Import "bộ não"
import 'widget/forgot_password_widgets.dart'; // Import các "mảnh ghép" UI

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  // Tạo ra đối tượng State (bộ não của Widget)
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

// Lớp State, chứa toàn bộ trạng thái và logic của màn hình
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Service
  // `final`: Instance của service không thay đổi
  final ForgotPasswordService _service = ForgotPasswordService();

  // State
  // `int?` (kiểu `int` có thể `null` - nullable):
  // **Tại sao?** Vì lúc đầu, người dùng chưa chọn phương thức nào
  // (`_selectedMethod` sẽ là `null`).
  // Khi người dùng chọn, nó sẽ lưu `0` (Email), `1` (Google), v.v.
  int? _selectedMethod;

  // `bool`: Trạng thái loading
  // Dùng để ngăn người dùng bấm nút nhiều lần và
  // hiển thị `CircularProgressIndicator`.
  bool _isLoading = false;

  // --- HÀM XỬ LÝ CHÍNH (CONTROLLERS) ---

  // Hàm được gọi khi bấm nút "Tiếp tục"
  void _handleContinue() {
    // Chỉ xử lý nếu phương thức 0 (Email) được chọn
    if (_selectedMethod == 0) {
      _showCustomEmailInputDialog(); // Gọi hàm hiển thị dialog nhập email
    }
  }

  /// Hàm xử lý logic chính: Gửi email
  // **Luồng hoạt động (Rất quan trọng):**
  Future<void> _sendPasswordResetEmail(String email) async {
    if (_isLoading) return; // Ngăn bấm nút nhiều lần

    // 1. Cập nhật state -> Bật loading
    // `setState`: Báo cho Flutter "hãy build lại UI"
    setState(() => _isLoading = true);

    // 2. Hiển thị dialog loading (xoay xoay)
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho bấm ra ngoài để tắt
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 3. **GỌI SERVICE:**
      // Gọi hàm `sendPasswordResetEmail` từ service
      // và `await` (chờ) nó hoàn thành.
      await _service.sendPasswordResetEmail(email);

      // 4. `if (!mounted) return;`: (Kiểm tra an toàn)
      // `mounted` là `true` nếu Widget còn hiển thị.
      // Vì đây là hàm `async`, có thể người dùng đã
      // bấm "Back" (thoát màn hình) trong lúc đang `await`.
      // Nếu cố gọi `Navigator` khi `mounted` là `false`, app sẽ crash.
      if (!mounted) return;
      Navigator.of(context).pop(); // Tắt dialog loading

      // 5. **HIỂN THỊ THÀNH CÔNG (Trường hợp 1: Thành công thật)**
      _showResultDialog(
        title: 'Yêu Cầu Thành Công',
        content:
            'Nếu email $email tồn tại trong hệ thống, một liên kết sẽ được gửi đến. Vui lòng kiểm tra hộp thư (và cả mục Spam).',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        isSuccess: true, // `true` để dialog biết sẽ pop 2 lần (về Login)
      );
    } catch (e) {
      // 6. **XỬ LÝ LỖI (Bắt lỗi `throw` từ Service)**
      if (!mounted) return;
      Navigator.of(context).pop(); // Tắt dialog loading

      // **LOGIC BẢO MẬT (RẤT QUAN TRỌNG):**
      if (e is FirebaseAuthException) {
        // Nếu lỗi là từ Firebase (ví dụ: 'user-not-found', 'invalid-email')
        // Chúng ta *KHÔNG* báo "Không tìm thấy user".
        // **Tại sao?** Nếu báo lỗi, hacker có thể dùng
        // tính năng này để "dò" xem email nào đã đăng ký
        // trong hệ thống của bạn.
        // Thay vào đó, ta **VẪN BÁO THÀNH CÔNG** (Trường hợp 2).
        _showResultDialog(
          title: 'Yêu Cầu Thành Công',
          content:
              'Nếu email $email tồn tại trong hệ thống, một liên kết sẽ được gửi đến.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          isSuccess: true, // Vẫn là `true`
        );
      } else {
        // 7. Nếu là lỗi từ service (ví dụ: email rỗng do `throw`)
        // Đây là lỗi validation (người dùng làm sai), có thể hiển thị.
        _showResultDialog(
          title: 'Lỗi',
          content: e.toString().replaceFirst(
            "Exception: ",
            "",
          ), // Làm sạch chuỗi lỗi
          icon: Icons.error_outline,
          iconColor: Colors.red,
          isSuccess: false, // `false` để dialog chỉ pop 1 lần
        );
      }
    } finally {
      // `finally`: Khối này **LUÔN LUÔN** được chạy,
      // dù `try` thành công hay `catch` bị lỗi.
      if (mounted) {
        setState(() => _isLoading = false); // Tắt cờ loading
      }
    }
  }

  // --- CÁC HÀM HIỂN THỊ DIALOG (ĐÃ SỬ DỤNG WIDGET MỚI) ---

  // Hàm này chỉ "build" (xây dựng) và hiển thị Dialog
  Future<void> _showCustomEmailInputDialog() async {
    // `TextEditingController`: Tạo 1 controller MỚI
    // chỉ dành riêng cho dialog này.
    final TextEditingController emailController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Cho phép bấm ra ngoài để tắt
      builder: (BuildContext context) {
        // **Sử dụng Widget đã tách:**
        // Trả về `EmailInputDialog` (từ file `_widgets.dart`)
        return EmailInputDialog(
          controller: emailController, // Truyền controller vào
          // **Callback (Hàm gọi ngược):**
          // Truyền 1 hàm (ẩn danh) vào `onSend`.
          // Khi người dùng bấm nút "Gửi" (bên trong `EmailInputDialog`)...
          onSend: () {
            // ...hàm này sẽ được gọi.
            final String email = emailController.text.trim();
            Navigator.of(context).pop(); // Đóng dialog
            _sendPasswordResetEmail(email); // Gọi hàm xử lý chính
          },
        );
      },
    );
  }

  // Hàm này hiển thị dialog Kết quả (thành công/thất bại)
  Future<void> _showResultDialog({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required bool isSuccess,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        // **Sử dụng Widget đã tách:**
        // Trả về `ResultDialog` (từ file `_widgets.dart`)
        return ResultDialog(
          title: title,
          content: content,
          icon: icon,
          iconColor: iconColor,

          // **Callback:**
          // Khi người dùng bấm "OK" (bên trong `ResultDialog`)...
          onOk: () {
            Navigator.of(context).pop(); // 1. Đóng dialog kết quả
            if (isSuccess) {
              // Nếu thành công, đóng luôn cả màn hình
              // "Quên mật khẩu" để quay về "Đăng nhập".
              Navigator.of(context).pop(); // 2. Quay về màn hình Login
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // ... (Code UI cho AppBar) ...
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (Text hướng dẫn) ...
              const SizedBox(height: 32),

              // === SỬ DỤNG WIDGET MỚI ===
              // **Luồng hoạt động của UI:**
              MethodOptionWidget(
                index: 0,
                imagePath: 'assets/images/forgotpasswordgmail.png',
                title: 'Email đặt lại mật khẩu',
                isEnabled: true, // Cho phép chọn
                // **Logic State:**
                // `isSelected` là `true` nếu `_selectedMethod` là 0.
                isSelected: _selectedMethod == 0,

                // **Callback:**
                // Khi `onTap` được gọi...
                onTap: () =>
                    setState(() => _selectedMethod = 0), // ...cập nhật state
              ),
              const SizedBox(height: 16),
              MethodOptionWidget(
                index: 1,
                imagePath: 'assets/images/forgotpasswordgoogle.png',
                title: 'Google Authenticator (Sắp ra mắt)',
                isEnabled: false, // Bị vô hiệu hóa (sẽ mờ đi)
                isSelected: _selectedMethod == 1,
                onTap: () {}, // Không làm gì
              ),
              const SizedBox(height: 16),
              MethodOptionWidget(
                index: 2,
                imagePath: 'assets/images/forgotpasswordnumberphone.png',
                title: 'Số điện thoại/SMS (Sắp ra mắt)',
                isEnabled: false, // Bị vô hiệu hóa
                isSelected: _selectedMethod == 2,
                onTap: () {},
              ),

              // =========================
              // `Spacer`: Một widget "vô hình" chiếm
              // hết không gian trống còn lại, đẩy
              // nút "Tiếp tục" xuống đáy màn hình.
              const Spacer(),
              ElevatedButton(
                // **Logic State:**
                // `onPressed` sẽ là `null` (nút bị vô hiệu hóa)
                // nếu `_selectedMethod` *không* phải là 0.
                onPressed: _selectedMethod == 0 ? _handleContinue : null,
                style: ElevatedButton.styleFrom(
                  // ... (style) ...
                  // `disabledBackgroundColor`: Màu khi nút bị vô hiệu hóa
                  disabledBackgroundColor: Colors.orange[200],
                ),
                child: const Row(
                  // ... (Text "Tiếp tục" + Icon) ...
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
