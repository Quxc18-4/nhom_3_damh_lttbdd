// File: screens/authentication/forgot_password/forgotPasswordScreen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import Service và Widgets đã tách
import 'service/forgot_password_service.dart';
import 'widget/forgot_password_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Service
  final ForgotPasswordService _service = ForgotPasswordService();

  // State
  int? _selectedMethod;
  bool _isLoading = false;

  // --- HÀM XỬ LÝ CHÍNH (CONTROLLERS) ---

  void _handleContinue() {
    if (_selectedMethod == 0) {
      _showCustomEmailInputDialog();
    }
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _service.sendPasswordResetEmail(email);
      if (!mounted) return;
      Navigator.of(context).pop(); // Tắt loading

      // **LUÔN** hiển thị thành công (vì lý do bảo mật)
      _showResultDialog(
        title: 'Yêu Cầu Thành Công',
        content:
            'Nếu email $email tồn tại trong hệ thống, một liên kết sẽ được gửi đến. Vui lòng kiểm tra hộp thư (và cả mục Spam).',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        isSuccess: true, // Để quay về màn hình Login
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Tắt loading

      if (e is FirebaseAuthException) {
        // Nếu lỗi là do Firebase (ví dụ: email không tồn tại),
        // vẫn hiển thị thành công để bảo mật.
        _showResultDialog(
          title: 'Yêu Cầu Thành Công',
          content:
              'Nếu email $email tồn tại trong hệ thống, một liên kết sẽ được gửi đến.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          isSuccess: true, // Vẫn là success
        );
      } else {
        // Nếu là lỗi từ service (ví dụ: email rỗng)
        _showResultDialog(
          title: 'Lỗi',
          content: e.toString().replaceFirst("Exception: ", ""),
          icon: Icons.error_outline,
          iconColor: Colors.red,
          isSuccess: false, // Lỗi
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- CÁC HÀM HIỂN THỊ DIALOG (ĐÃ SỬ DỤNG WIDGET MỚI) ---

  Future<void> _showCustomEmailInputDialog() async {
    final TextEditingController emailController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Dùng widget mới
        return EmailInputDialog(
          controller: emailController,
          onSend: () {
            final String email = emailController.text.trim();
            Navigator.of(context).pop(); // Đóng dialog
            _sendPasswordResetEmail(email); // Gọi hàm xử lý
          },
        );
      },
    );
  }

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
        // Dùng widget mới
        return ResultDialog(
          title: title,
          content: content,
          icon: icon,
          iconColor: iconColor,
          onOk: () {
            Navigator.of(context).pop(); // Đóng dialog
            if (isSuccess) {
              Navigator.of(context).pop(); // Quay về màn hình Login
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Chọn phương thức xác minh mà bạn muốn đặt lại mật khẩu.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // === SỬ DỤNG WIDGET MỚI ===
              MethodOptionWidget(
                index: 0,
                imagePath: 'assets/images/forgotpasswordgmail.png',
                title: 'Email đặt lại mật khẩu',
                isEnabled: true,
                isSelected: _selectedMethod == 0,
                onTap: () => setState(() => _selectedMethod = 0),
              ),
              const SizedBox(height: 16),
              MethodOptionWidget(
                index: 1,
                imagePath: 'assets/images/forgotpasswordgoogle.png',
                title: 'Google Authenticator (Sắp ra mắt)',
                isEnabled: false,
                isSelected: _selectedMethod == 1,
                onTap: () {},
              ),
              const SizedBox(height: 16),
              MethodOptionWidget(
                index: 2,
                imagePath: 'assets/images/forgotpasswordnumberphone.png',
                title: 'Số điện thoại/SMS (Sắp ra mắt)',
                isEnabled: false,
                isSelected: _selectedMethod == 2,
                onTap: () {},
              ),

              // =========================
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedMethod == 0 ? _handleContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[400],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.orange[200],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tiếp tục',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
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
