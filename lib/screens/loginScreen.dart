import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Đảm bảo các import này là chính xác
import 'package:nhom_3_damh_lttbdd/screens/homePage.dart';
import 'package:nhom_3_damh_lttbdd/screens/registerScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/forgotPasswordScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  // Dán hàm này vào trong class _LoginScreenState
  Future<void> _loginUser() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    // 1. Kiểm tra đầu vào
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email và mật khẩu.')),
      );
      return;
    }

    // Hiển thị vòng xoay loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Gọi Firebase để đăng nhập
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user != null) {
        // Tắt vòng xoay loading
        Navigator.of(context).pop();

        // 3. Đăng nhập thành công, lấy userID và chuyển hướng
        // Dùng pushAndRemoveUntil để xóa hết các màn hình cũ
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            // Truyền userId qua HomePage
            builder: (context) => HomePage(userId: user.uid),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Tắt vòng xoay loading
      Navigator.of(context).pop();

      // 4. Xử lý các lỗi đăng nhập cụ thể
      String message = 'Đã có lỗi xảy ra.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'Email hoặc mật khẩu không chính xác.';
      } else if (e.code == 'wrong-password') {
        message = 'Email hoặc mật khẩu không chính xác.';
      } else if (e.code == 'invalid-email') {
        message = 'Định dạng email không hợp lệ.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hàm xây dựng nút mạng xã hội (được giữ nguyên)
  Widget _buildSocialButton({
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: SizedBox(
        width: 50,
        height: 50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(imagePath, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(backgroundColor: Colors.grey[100]),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                /// Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    width: 120,
                  ),
                ),

                const SizedBox(height: 24),

                /// SỬA ĐỔI: Chuyển TextButton thành Text làm tiêu đề
                const Center(
                  child: Text(
                    'Đăng Nhập',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                /// Email
                const Text(
                  'Số điện thoại hoặc email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email hoặc số điện thoại của bạn',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey[600],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// Password
                const Text(
                  'Mật khẩu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu của bạn',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey[600],
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// Login Button (Đã thêm logic chuyển hướng)
                ElevatedButton(
                  onPressed: _loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// Remember me & Forgot Password
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: Colors.orange[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Lưu đăng nhập cho những lần sau',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// Social buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      imagePath: 'assets/images/facebook.png',
                      onTap: () {
                        // Handle Facebook login
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      imagePath: 'assets/images/google.png',
                      onTap: () {
                        // Handle Google login
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      imagePath: 'assets/images/apple.png',
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      imagePath: 'assets/images/instagram.png',
                      onTap: () {
                        // Handle Instagram login
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                /// Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Bạn chưa có tài khoản? ',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Đăng ký',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// Terms
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      children: [
                        const TextSpan(
                          text:
                              'Khi nhập vào Đăng ký, bạn đã xác nhận đồng ý với ',
                        ),
                        TextSpan(
                          text: 'Điều khoản dịch vụ',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(text: ' và '),
                        TextSpan(
                          text: 'Chính sách bảo mật',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(text: ' của chúng tôi.'),
                      ],
                    ),
                  ),
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
