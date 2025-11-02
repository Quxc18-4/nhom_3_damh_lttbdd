// File: screens/authentication/register/registerScreen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import để nhận kiểu `User`
import 'package:google_sign_in/google_sign_in.dart'; // Import (dù không dùng trực tiếp)

// Import các màn hình
import 'package:nhom_3_damh_lttbdd/screens/authentication/login/loginScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/home/homePage.dart';

// Import Service và Widgets đã tách
import 'service/register_service.dart'; // ✅ Import "bộ não"
import 'widget/register_widgets.dart'; // ✅ Import "mảnh ghép" UI

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Service
  final RegisterService _registerService = RegisterService(); // ✅ Khởi tạo

  // Controllers
  // `final`: Các controller được tạo 1 lần
  // `TextEditingController`: Để "điều khiển" các ô TextField
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State
  bool _obscurePassword = true; // Trạng thái Ẩn/Hiện mật khẩu
  bool _obscureConfirmPassword = true; // Trạng thái Ẩn/Hiện mật khẩu xác nhận
  bool _isLoading = false; // Trạng thái loading (dùng cho nút bấm)

  @override
  // `dispose`: Được gọi khi màn hình bị hủy (thoát ra)
  void dispose() {
    // **Rất quan trọng:** Phải `dispose()` các controller
    // để tránh rò rỉ bộ nhớ (memory leak).
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- HÀM XỬ LÝ (HELPER) ---

  // Hàm helper hiển thị SnackBar (thanh thông báo)
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      // Kiểm tra xem màn hình còn hiển thị không
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
    }
  }

  /// 1. Xử lý Đăng ký Email
  Future<void> _handleRegisterUser() async {
    // 1. Lấy dữ liệu từ controllers và "làm sạch" (`.trim()`)
    final String nickname = _nicknameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    // 2. **Validation (Kiểm tra) tại View:**
    if (nickname.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin.', isError: true);
      return; // Dừng hàm
    }
    if (password != confirmPassword) {
      _showSnackBar('Mật khẩu xác nhận không khớp.', isError: true);
      return; // Dừng hàm
    }

    // 3. Bật loading
    setState(() => _isLoading = true);

    try {
      // 4. **GỌI SERVICE:**
      // `await`: Chờ cho service đăng ký xong
      await _registerService.registerWithEmail(nickname, email, password);

      // 5. Xử lý thành công
      if (mounted) {
        _showSnackBar('Đăng ký thành công! Vui lòng đăng nhập.');
        // `pushReplacement`: Thay thế màn hình Đăng ký
        // bằng màn hình Đăng nhập (user không thể "Back" lại).
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // 6. Xử lý lỗi (bắt lỗi `throw` từ Service)
      if (mounted) {
        setState(() => _isLoading = false); // Tắt loading
        // Hiển thị lỗi (đã được dịch)
        _showSnackBar(
          e.toString().replaceFirst("Exception: ", ""),
          isError: true,
        );
      }
    }
    // `finally` không cần thiết ở đây vì `pushReplacement`
    // đã hủy màn hình, `_isLoading` không còn quan trọng.
    // Tuy nhiên, nếu logic khác, bạn nên đặt
    // `setState(() => _isLoading = false)` trong `finally`.
  }

  /// 2. Xử lý Đăng nhập/Đăng ký Social
  /// **Kiến trúc rất hay:**
  /// Hàm này nhận 1 `Future<User>` (một hàm async) làm tham số.
  /// Nó không quan tâm đó là Google hay Facebook, nó chỉ
  /// `await` cái `loginMethod` được truyền vào.
  Future<void> _handleSocialLogin(Future<User> loginMethod) async {
    setState(
      () => _isLoading = true,
    ); // Dùng chung `_isLoading` của nút Register
    try {
      // 1. **GỌI SERVICE (thông qua tham số):**
      // `await loginMethod` sẽ chạy `_registerService.signInWithGoogle()`
      // hoặc `_registerService.signInWithFacebook()`.
      final User user = await loginMethod;

      // 2. Xử lý thành công
      if (mounted) {
        // Đăng nhập/Đăng ký bằng Social -> vào thẳng Home
        // `pushAndRemoveUntil`: Đẩy (push) Home và xóa (remove)
        // tất cả màn hình bên dưới (Login, Register...)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage(userId: user.uid)),
          (Route<dynamic> route) => false, // Xóa tất cả
        );
      }
    } catch (e) {
      // 3. Xử lý lỗi (bắt `throw` từ Service)
      if (mounted) {
        setState(() => _isLoading = false); // Tắt loading
        _showSnackBar(
          e.toString().replaceFirst("Exception: ", ""),
          isError: true,
        );
      }
    }
  }

  // --- HÀM BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // `SingleChildScrollView`: Cho phép cuộn khi bàn phím hiện
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ... (Logo, Tiêu đề) ...

                // === SỬ DỤNG WIDGET MỚI ===
                // Giao diện (View) trở nên rất sạch sẽ và
                // dễ đọc, chỉ tập trung vào việc "sắp xếp"
                // các widget đã được định nghĩa sẵn.
                NicknameField(controller: _nicknameController),
                const SizedBox(height: 16),
                RegisterEmailField(controller: _emailController),
                const SizedBox(height: 16),
                RegisterPasswordField(
                  controller: _passwordController,
                  obscurePassword: _obscurePassword,
                  // **Callback (Hàm gọi ngược):**
                  // Truyền 1 hàm (ẩn danh) vào `onToggleObscure`.
                  // Khi user bấm nút "mắt" (bên trong `RegisterPasswordField`)...
                  onToggleObscure: () {
                    // ...hàm này được gọi, nó `setState`
                    // (cập nhật state) và build lại UI.
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                const SizedBox(height: 16),
                ConfirmPasswordField(
                  controller: _confirmPasswordController,
                  obscurePassword: _obscureConfirmPassword,
                  onToggleObscure: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                ),
                const SizedBox(height: 24),
                // **Truyền State & Callback:**
                RegisterButton(
                  isLoading: _isLoading, // 1. Truyền trạng thái loading
                  onPressed: _handleRegisterUser, // 2. Truyền HÀM xử lý
                ),

                // ==========================
                // ... (Dấu gạch ngang "Hoặc đăng ký bằng") ...
                // ==========================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(
                      imagePath: 'assets/images/facebook.png',
                      // **Truyền Callback (dùng hàm helper):**
                      // Khi bấm nút Facebook...
                      onTap: () => _handleSocialLogin(
                        // ...gọi `_handleSocialLogin` và truyền
                        // hàm service `signInWithFacebook` vào
                        _registerService.signInWithFacebook(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SocialButton(
                      imagePath: 'assets/images/google.png',
                      // Tương tự, gọi `_handleSocialLogin` và
                      // truyền hàm `signInWithGoogle` vào
                      onTap: () => _handleSocialLogin(
                        _registerService.signInWithGoogle(),
                      ),
                    ),
                    // ... (Các nút social khác) ...
                  ],
                ),
                // ... (Link "Đăng nhập ngay") ...
              ],
            ),
          ),
        ),
      ),
    );
  }
}
