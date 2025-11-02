// File: screens/authentication/register/registerScreen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Import các màn hình
import 'package:nhom_3_damh_lttbdd/screens/authentication/login/loginScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/home/homePage.dart';

// Import Service và Widgets đã tách
import 'service/register_service.dart';
import 'widget/register_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Service
  final RegisterService _registerService = RegisterService();

  // Controllers
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- HÀM XỬ LÝ (HELPER) ---

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
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
    final String nickname = _nicknameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (nickname.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin.', isError: true);
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Mật khẩu xác nhận không khớp.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _registerService.registerWithEmail(nickname, email, password);

      if (mounted) {
        _showSnackBar('Đăng ký thành công! Vui lòng đăng nhập.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(
          e.toString().replaceFirst("Exception: ", ""),
          isError: true,
        );
      }
    }
  }

  /// 2. Xử lý Đăng nhập/Đăng ký Social
  /// (Chung cho cả Google và Facebook)
  Future<void> _handleSocialLogin(Future<User> loginMethod) async {
    setState(() => _isLoading = true); // Dùng loading của nút Register
    try {
      final User user = await loginMethod;

      // Đăng nhập thành công, chuyển thẳng vào Home
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage(userId: user.uid)),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 18),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    width: 100,
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Đăng Ký Tài Khoản Mới',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // === SỬ DỤNG WIDGET MỚI ===
                NicknameField(controller: _nicknameController),
                const SizedBox(height: 16),
                RegisterEmailField(controller: _emailController),
                const SizedBox(height: 16),
                RegisterPasswordField(
                  controller: _passwordController,
                  obscurePassword: _obscurePassword,
                  onToggleObscure: () {
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
                RegisterButton(
                  isLoading: _isLoading,
                  onPressed: _handleRegisterUser,
                ),

                // ==========================
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Hoặc đăng ký bằng',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(
                      imagePath: 'assets/images/facebook.png',
                      onTap: () => _handleSocialLogin(
                        _registerService.signInWithFacebook(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SocialButton(
                      imagePath: 'assets/images/google.png',
                      onTap: () => _handleSocialLogin(
                        _registerService.signInWithGoogle(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SocialButton(
                      imagePath: 'assets/images/apple.png',
                      onTap: () {
                        _showSnackBar('Đăng nhập Apple chưa được hỗ trợ');
                      },
                    ),
                    const SizedBox(width: 16),
                    SocialButton(
                      imagePath: 'assets/images/instagram.png',
                      onTap: () {
                        _showSnackBar('Đăng nhập Instagram chưa được hỗ trợ');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Bạn đã có tài khoản? ',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Đăng nhập ngay.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
