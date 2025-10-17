import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/screens/loginScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; // (MỚI) Import cho Facebook
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nhom_3_damh_lttbdd/screens/homePage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Giữ nguyên các controller từ file gốc của bạn
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // --- (MỚI) CÁC HÀM HELPER TỪ FILE .TXT ĐỂ CODE GỌN HƠN ---
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoading() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // --- HÀM ĐĂNG KÝ BẰNG EMAIL (ĐÃ CẬP NHẬT ĐỂ DÙNG HELPER) ---
  Future<void> _registerUser() async {
    final String nickname = _nicknameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (nickname.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin.');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Mật khẩu xác nhận không khớp.');
      return;
    }

    _showLoading();

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      User? newUser = userCredential.user;

      if (newUser != null) {
        // Giữ nguyên cấu trúc Firestore bạn muốn (fullName rỗng)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUser.uid)
            .set({
              'name': nickname,
              'fullName': '', // Để trống, cập nhật sau
              'email': email,
              'password': null,
              'avatarUrl': '',
              'bio': '',
              'authProviders': ['password'],
              'joinedAt': FieldValue.serverTimestamp(),
              'followersCount': 0,
              'followingCount': 0,
              'userRank': 'Bronze',
              'phoneNumber': '',
              'birthDate': null,
              'gender': '',
              'city': '',
            });

        _hideLoading();
        _showSnackBar('Đăng ký thành công!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _hideLoading();
      String message = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email này đã được sử dụng.';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ.';
      }
      _showSnackBar(message);
    }
  }

  // --- (MỚI) HÀM ĐĂNG NHẬP BẰNG FACEBOOK TỪ FILE .TXT ---
  Future<void> _signInWithFacebook() async {
    _showLoading();
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.token;
        final facebookAuthCredential = FacebookAuthProvider.credential(
          accessToken,
        );
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(facebookAuthCredential);
        User? newUser = userCredential.user;

        if (newUser != null) {
          // Kiểm tra xem user đã tồn tại trong Firestore chưa
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(newUser.uid)
              .get();

          // Nếu chưa, tạo document mới cho họ
          if (!userDoc.exists) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(newUser.uid)
                .set({
                  'name': newUser.displayName ?? 'Người dùng Facebook',
                  'fullName':
                      newUser.displayName ?? '', // Lấy họ tên từ FB nếu có
                  'email': newUser.email,
                  'password': null,
                  'avatarUrl': newUser.photoURL ?? '',
                  'bio': '',
                  'authProviders': ['facebook.com'], // Ghi nhận nhà cung cấp
                  'joinedAt': FieldValue.serverTimestamp(),
                  'followersCount': 0,
                  'followingCount': 0,
                  'userRank': 'Bronze',
                  'phoneNumber': newUser.phoneNumber ?? '',
                  'birthDate': null,
                  'gender': '',
                  'city': '',
                });
          }

          _hideLoading();
          _showSnackBar('Đăng nhập bằng Facebook thành công!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ), // Hoặc HomePage
          );
        }
      } else {
        _hideLoading();
        _showSnackBar('Đăng nhập Facebook đã bị hủy hoặc thất bại.');
      }
    } catch (e) {
      _hideLoading();
      _showSnackBar('Lỗi đăng nhập Facebook: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    _showLoading();
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        _hideLoading();
        _showSnackBar('Đăng nhập Google đã bị hủy.');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'name': user.displayName ?? 'Người dùng Google',
                'fullName': user.displayName ?? '',
                'email': user.email ?? '',
                'avatarUrl': user.photoURL ?? '',
                'authProviders': ['google.com'],
                'bio': '',
                'password': null,
                'joinedAt': FieldValue.serverTimestamp(),
                'followersCount': 0,
                'followingCount': 0,
                'userRank': 'Bronze',
                'phoneNumber': user.phoneNumber ?? '',
                'birthDate': null,
                'gender': '',
                'city': '',
              });
        }
        _hideLoading();
        // Sau khi đăng nhập/đăng ký thành công, chuyển thẳng vào HomePage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage(userId: user.uid)),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      _hideLoading();
      _showSnackBar('Lỗi đăng nhập Google: $e');
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
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

                // --- NICKNAME INPUT (Giữ nguyên từ file của bạn) ---
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

                // --- CÁC Ô NHẬP LIỆU CÒN LẠI (Giữ nguyên) ---
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

                // Dòng chữ phân cách
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

                // --- CẬP NHẬT NÚT SOCIAL ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      imagePath: 'assets/images/facebook.png',
                      onTap: _signInWithFacebook,
                    ), // ✅ Gắn hàm Facebook
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      imagePath: 'assets/images/google.png',
                      onTap: _signInWithGoogle,
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      imagePath: 'assets/images/apple.png',
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      imagePath: 'assets/images/instagram.png',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 32), // Tăng khoảng cách
                // Dòng chữ chuyển về Đăng nhập
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
                // ... (Phần link Đăng nhập và Điều khoản giữ nguyên)
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
