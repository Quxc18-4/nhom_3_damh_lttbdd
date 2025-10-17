import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/screens/loginScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Đổi tên và thêm controller mới
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;


  // Hàm hiển thị thông báo lỗi/thành công
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Hàm tắt vòng xoay loading
  void _hideLoading() {
    // Chỉ pop nếu có thể (để tránh lỗi)
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // =========================================================================
  // 1. HÀM ĐĂNG KÝ BẰNG EMAIL/PASSWORD
  // =========================================================================
  Future<void> _registerUser() async {
    final String name = _nameController.text.trim();

  Future<void> _registerUser() async {
    // Lấy dữ liệu từ các controller
    final String nickname = _nicknameController.text.trim();

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();


    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin.');
    // 1. Kiểm tra đầu vào
    if (nickname.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
      );

      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Mật khẩu xác nhận không khớp.');
      return;
    }


    // Hiển thị vòng xoay loading

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? newUser = userCredential.user;

      if (newUser != null) {
  // 3. Lưu thông tin người dùng lên Cloud Firestore với cấu trúc đầy đủ
  await FirebaseFirestore.instance
      .collection('users')
      .doc(newUser.uid)
      .set({
        'name': name, // SỬ DỤNG biến 'name' hoặc 'nickname' của bạn
        'fullName': '', // Trường họ và tên đầy đủ (Để trống khi đăng ký)
        'email': email,
        'password': null, // Không lưu mật khẩu thô
        'avatarUrl': '',
        'bio': '',
        'authProviders': ['password'], // Xác định phương thức đăng ký
        'joinedAt': FieldValue.serverTimestamp(),
        'followersCount': 0,
        'followingCount': 0,
        'userRank': 'Bronze',
        'phoneNumber': '',
        'birthDate': null, // Kiểu DateTime hoặc Timestamp nếu cần
        'gender': '',
        'city': '',
      });

  // Tắt vòng xoay loading
  _hideLoading();
  _showSnackBar('Đăng ký thành công!');

  // Chuyển hướng đến màn hình đăng nhập
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );
}

  // =========================================================================
// 2. HÀM ĐĂNG KÝ BẰNG FACEBOOK
// =========================================================================
// Đặt import 'dart:io' ở đầu file để dùng Platform
// Đặt hàm _hideLoading và _showSnackBar trong class _RegisterScreenState
  Future<void> _signInWithFacebook() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      // THÊM: Xử lý quyền theo dõi trên iOS (Nếu bạn có package app_tracking_transparency)
      // if (Platform.isIOS) {
      //   await AppTrackingTransparency.requestTrackingAuthorization();
      // }

      // 1. Thực hiện Đăng nhập bằng Facebook
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.token;
        final facebookAuthCredential = FacebookAuthProvider.credential(accessToken);

        // 2. Đăng nhập/Đăng ký vào Firebase
        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
        User? newUser = userCredential.user;

        if (newUser != null) {
          // 3. Kiểm tra và Lưu thông tin người dùng lên Cloud Firestore
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(newUser.uid).get();

          if (!userDoc.exists) {
            String name = newUser.displayName ?? 'Người dùng Facebook';
            String avatarUrl = newUser.photoURL ?? '';

            await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
              'name': name,
              'email': newUser.email,
              'password': null, // Bỏ qua mật khẩu
              'avatarUrl': avatarUrl,
              'bio': '',
              'authProviders': ['facebook'],
              'joinedAt': FieldValue.serverTimestamp(),
              'followersCount': 0,
              'followingCount': 0,
              'userRank': 'Bronze',
            });
          }

          // 4. Xử lý sau khi thành công
          _hideLoading();
          _showSnackBar('Đăng nhập/Đăng ký bằng Facebook thành công!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else if (result.status == LoginStatus.cancelled) {
        _hideLoading();
        _showSnackBar('Đăng nhập Facebook đã bị hủy.');
      } else {
        _hideLoading();
        _showSnackBar('Lỗi đăng nhập Facebook: ${result.message}');
      }
    } on FirebaseAuthException catch (e) {
      _hideLoading();
      _showSnackBar('Lỗi Firebase: ${e.message}');
    } catch (e) {
      _hideLoading();
      _showSnackBar('Lỗi không xác định: $e');
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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

                // --- NICKNAME INPUT ---
                const Text(
                  'Nickname (Tên hiển thị)',
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
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      hintText: 'Tên sẽ hiển thị trong ứng dụng...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
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

                // --- EMAIL INPUT ---
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
                      hintText: 'Email hoặc số điện thoại của bạn...',
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

                // --- PASSWORD INPUT ---
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
                      hintText: 'Nhập mật khẩu...',
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
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
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

                // --- CONFIRM PASSWORD INPUT ---
                const Text(
                  'Xác nhận mật khẩu',
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
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'Nhập lại mật khẩu...',
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
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[400],
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
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

                // --- REGISTER BUTTON ---
                ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đăng ký',
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

                const SizedBox(height: 24),
                // Social Login Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      imagePath: 'assets/images/facebook.png',
                      onTap: () {
                        // GỌI HÀM ĐĂNG NHẬP FACEBOOK
                        _signInWithFacebook();
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
                      onTap: () {
                        // Handle Apple login
                      },
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

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Bạn đã có tài khoản? ',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    TextButton(
                      onPressed: () {
                        // Handle navigate to login
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Đăng nhập.',
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

                // Terms and Privacy
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
}



