import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Cần cho Firestore
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; // ✅ Cần cho Facebook Login
import 'package:google_sign_in/google_sign_in.dart'; // ✅ Cần cho Google Sign-In

// Đảm bảo các import này là chính xác

import 'package:nhom_3_damh_lttbdd/screens/home/homePage.dart';
import 'package:nhom_3_damh_lttbdd/screens/registerScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/forgotPasswordScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/adminDashboardRequestView.dart';

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

  // =========================================================================
  // HÀM HIỂN THỊ/ẨN LOADING VÀ SNACKBAR
  // =========================================================================

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoading() {
    Navigator.of(context).pop();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _navigateAfterLogin(User user) async {
    String? userRank;
    try {
      // Lấy document của user từ Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        // Đọc trường userRank (nếu có)
        userRank =
            (userDoc.data() as Map<String, dynamic>)['userRank'] as String?;
      }
    } catch (e) {
      print("Lỗi khi đọc userRank: $e");
      // Bỏ qua lỗi đọc rank, coi như user thường
    }

    // Ẩn loading (nếu đang hiển thị) - Di chuyển _hideLoading ra khỏi các hàm login
    // _hideLoading(); // <-- Xóa _hideLoading ở cuối các hàm _loginUser, _signInWithFacebook, _signInWithGoogle

    if (!mounted) return; // Kiểm tra mounted trước khi điều hướng

    // Điều hướng dựa trên userRank
    if (userRank == 'Admin') {
      print("User is Admin, navigating to Admin Dashboard.");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashBoardRequestView(userId: user.uid),
        ),
        (Route<dynamic> route) => false,
      );
    } else {
      print("User is not Admin, navigating to Home Page.");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage(userId: user.uid)),
        (Route<dynamic> route) => false,
      );
    }
  }

  // =========================================================================
  // 1. HÀM ĐĂNG NHẬP BẰNG EMAIL/PASSWORD
  // =========================================================================
  Future<void> _loginUser() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng nhập email và mật khẩu.');
      return;
    }

    _showLoading();

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user != null) {
        // 3. Đăng nhập thành công, lấy userID và chuyển hướng
        await _navigateAfterLogin(user);
      }
    } on FirebaseAuthException catch (e) {
      _hideLoading();

      String message = 'Đã có lỗi xảy ra.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'Email hoặc mật khẩu không chính xác.';
      } else if (e.code == 'wrong-password') {
        message = 'Email hoặc mật khẩu không chính xác.';
      } else if (e.code == 'invalid-email') {
        message = 'Định dạng email không hợp lệ.';
      }
      _showSnackBar(message);
    } catch (e) {
      _hideLoading();
      _showSnackBar('Lỗi không xác định: $e');
    }
  }

  // =========================================================================
  // 2. HÀM ĐĂNG NHẬP BẰNG FACEBOOK (Dựa trên code từ RegisterScreen)
  // =========================================================================
  Future<void> _signInWithFacebook() async {
    _showLoading();
    try {
      // 1. Thực hiện Đăng nhập bằng Facebook
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.token;
        final facebookAuthCredential = FacebookAuthProvider.credential(
          accessToken,
        );

        // 2. Đăng nhập/Đăng ký vào Firebase
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(facebookAuthCredential);
        User? user = userCredential.user;

        if (user != null) {
          // 3. Kiểm tra và Lưu thông tin người dùng lên Cloud Firestore
          // Chỉ tạo user mới nếu chưa tồn tại
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userDoc.exists) {
            String name = user.displayName ?? 'Người dùng Facebook';
            String avatarUrl = user.photoURL ?? '';

            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
                  'name': name,
                  'email': user.email,
                  'password': null,
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
          _showSnackBar('Đăng nhập bằng Facebook thành công!');
          await _navigateAfterLogin(user);
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
  // =========================================================================
  // END HÀM ĐĂNG NHẬP BẰNG FACEBOOK
  // =========================================================================

  // =========================================================================
  // 3. HÀM ĐĂNG NHẬP BẰNG GOOGLE
  // =========================================================================

  // Dán hàm này vào trong class _LoginScreenState của bạn

  // Thay thế toàn bộ hàm này trong file loginScreen.dart hoặc registerScreen.dart

  Future<void> _signInWithGoogle() async {
    _showLoading(); // Dùng lại hàm helper _showLoading của bạn
    try {
      // 1. Bắt đầu quá trình đăng nhập với Google.
      // Đây là cách gọi đúng cho phiên bản mới nhất.
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // 2. Nếu người dùng hủy, googleUser sẽ là null.
      if (googleUser == null) {
        _hideLoading();
        _showSnackBar(
          'Đăng nhập Google đã bị hủy.',
        ); // Dùng helper _showSnackBar
        return;
      }

      // 3. Lấy thông tin xác thực (idToken và accessToken) từ tài khoản Google.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Tạo một "Firebase credential" từ các token đó.
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Dùng credential đó để đăng nhập vào Firebase.
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 6. Kiểm tra và lưu thông tin vào Firestore.
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

        // 7. Điều hướng đến trang chủ.
        _hideLoading();
        if (mounted) {
          // Thêm kiểm tra `mounted` để đảm bảo an toàn
          await _navigateAfterLogin(user);
        }
      }
    } catch (e) {
      _hideLoading();
      _showSnackBar('Lỗi đăng nhập Google: $e');
    }
  }

  // =========================================================================
  // END HÀM ĐĂNG NHẬP BẰNG GOOGLE
  // =========================================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hàm xây dựng nút mạng xã hội (giữ nguyên)
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

                /// Tiêu đề
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

                // ... (Các trường Email, Password, Nút Login giữ nguyên) ...

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

                /// Login Button
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

                /// Remember me & Forgot Password (Giữ nguyên)
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

                /// Social buttons (ĐÃ SỬA: Thêm onTap cho Facebook)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      imagePath: 'assets/images/facebook.png',
                      onTap: _signInWithFacebook, // ✅ GỌI HÀM FACEBOOK LOGIN
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      imagePath: 'assets/images/google.png',
                      onTap: () {
                        _signInWithGoogle(); // ✅ GỌI HÀM GOOGLE LOGIN
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      imagePath: 'assets/images/apple.png',
                      onTap: () {
                        // Handle Apple login (Chưa tích hợp)
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      imagePath: 'assets/images/instagram.png',
                      onTap: () {
                        // Handle Instagram login (Chưa tích hợp)
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ... (Phần Đăng ký và Điều khoản giữ nguyên) ...

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
