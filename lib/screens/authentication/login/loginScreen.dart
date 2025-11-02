// File: loginScreen.dart

import 'package:flutter/material.dart';
// ... (các import khác) ...
import 'package:nhom_3_damh_lttbdd/screens/admin_only/adminDashboardRequestView.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  // Tạo ra đối tượng State (bộ não)
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // `TextEditingController`: Dùng để "điều khiển" các ô TextField.
  // Giúp chúng ta đọc (get) và gán (set) giá trị cho chúng.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Biến trạng thái (State):
  bool _rememberMe = false; // Trạng thái của checkbox
  bool _obscurePassword = true; // Trạng thái Ẩn/Hiện mật khẩu

  // =========================================================================
  // HÀM HIỂN THỊ/ẨN LOADING VÀ SNACKBAR
  // =========================================================================

  // Hàm helper (hỗ trợ) để hiển thị dialog loading
  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho bấm ra ngoài để tắt
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  // Hàm helper để tắt dialog (bất kể dialog đó là gì)
  void _hideLoading() {
    Navigator.of(context).pop();
  }

  // Hàm helper để hiển thị thanh thông báo (SnackBar)
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // **Luồng hoạt động chính:** Hàm điều hướng sau khi đăng nhập
  Future<void> _navigateAfterLogin(User user) async {
    String? userRank;
    try {
      // 1. Đọc trực tiếp Firestore từ View
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        // 2. Lấy `userRank`
        userRank =
            (userDoc.data() as Map<String, dynamic>)['userRank'] as String?;
      }
    } catch (e) {
      print("Lỗi khi đọc userRank: $e");
      // Bỏ qua, coi như user thường
    }

    // `if (!mounted) return;`: (Rất quan trọng)
    // `mounted` là `true` nếu Widget (màn hình) vẫn còn
    // trên cây (đang hiển thị).
    // Vì đây là hàm `async`, có thể user đã bấm back
    // trong lúc đang `await`. Nếu cố điều hướng (navigate)
    // khi `mounted` là `false`, app sẽ crash.
    if (!mounted) return;

    // 3. Điều hướng
    if (userRank == 'Admin') {
      print("User is Admin, navigating to Admin Dashboard.");
      // `pushAndRemoveUntil`:
      // **Tại sao?** Đẩy (push) màn hình Admin VÀ
      // Xóa (remove) tất cả màn hình cũ (màn hình Login).
      // Điều này ngăn người dùng bấm "Back" để quay lại Login.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashBoardRequestView(userId: user.uid),
        ),
        (Route<dynamic> route) => false, // Xóa tất cả
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
    // 1. Lấy và "làm sạch" (trim) dữ liệu
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    // 2. Validation (Kiểm tra)
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng nhập email và mật khẩu.');
      return; // Dừng hàm
    }

    _showLoading(); // Hiển thị vòng quay

    try {
      // 3. Gọi Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user != null) {
        // 4. Đăng nhập thành công, gọi hàm điều hướng
        // (Hàm này sẽ tự tắt loading dialog bằng cách
        // thay thế màn hình)
        await _navigateAfterLogin(user);
      }
    } on FirebaseAuthException catch (e) {
      // 5. Bắt lỗi từ Firebase
      _hideLoading(); // Tắt vòng quay

      String message = 'Đã có lỗi xảy ra.';
      // Dịch mã lỗi sang tiếng Việt
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'Email hoặc mật khẩu không chính xác.';
      } else if (e.code == 'wrong-password') {
        message = 'Email hoặc mật khẩu không chính xác.';
      } else if (e.code == 'invalid-email') {
        message = 'Định dạng email không hợp lệ.';
      }
      _showSnackBar(message);
    } catch (e) {
      // 6. Bắt các lỗi khác
      _hideLoading();
      _showSnackBar('Lỗi không xác định: $e');
    }
  }

  // =========================================================================
  // 2. HÀM ĐĂNG NHẬP BẰNG FACEBOOK
  // =========================================================================
  Future<void> _signInWithFacebook() async {
    _showLoading();
    try {
      // 1. Gọi SDK của Facebook
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.token;
        // 2. Tạo "Giấy thông hành" Firebase
        final facebookAuthCredential = FacebookAuthProvider.credential(
          accessToken,
        );

        // 3. Đăng nhập vào Firebase
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(facebookAuthCredential);
        User? user = userCredential.user;

        if (user != null) {
          // 4. **Logic `_ensureUserInFirestore` (viết trực tiếp):**
          // Kiểm tra xem user có tồn tại trong 'users' collection không
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userDoc.exists) {
            // Nếu không -> Tạo mới
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

          // 5. Xử lý sau khi thành công
          _hideLoading(); // Tắt loading
          _showSnackBar('Đăng nhập bằng Facebook thành công!');
          await _navigateAfterLogin(user); // Điều hướng
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
  // 3. HÀM ĐĂNG NHẬP BẰNG GOOGLE
  // =========================================================================
  Future<void> _signInWithGoogle() async {
    _showLoading();
    try {
      // 1. Gọi SDK của Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        _hideLoading();
        _showSnackBar('Đăng nhập Google đã bị hủy.');
        return;
      }

      // 2. Lấy token
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Tạo "Giấy thông hành" Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Đăng nhập Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 5. **Logic `_ensureUserInFirestore` (viết trực tiếp):**
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // Nếu không -> Tạo mới
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

        // 6. Điều hướng
        _hideLoading();
        if (mounted) {
          await _navigateAfterLogin(user);
        }
      }
    } catch (e) {
      _hideLoading();
      _showSnackBar('Lỗi đăng nhập Google: $e');
    }
  }

  // =========================================================================

  @override
  // `dispose`: Được gọi khi màn hình bị hủy (thoát ra).
  void dispose() {
    // **Rất quan trọng:** Phải `dispose()` các controller
    // để tránh rò rỉ bộ nhớ (memory leak).
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hàm private để xây dựng UI (bạn đã tách ra file widget)
  Widget _buildSocialButton({
    required String imagePath,
    required VoidCallback onTap,
  }) {
    // ... (code UI) ...
    // (Trong file `login_widgets.dart` của bạn có 1
    // widget `SocialButton` làm y hệt việc này)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(backgroundColor: Colors.grey[100]),
      body: SafeArea(
        // `SingleChildScrollView`: (Rất quan trọng)
        // Bọc `Column` để khi bàn phím ảo hiện lên,
        // nội dung có thể cuộn, tránh lỗi "Overflowed"
        // (nội dung bị đè lên nhau).
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ... (Logo, Tiêu đề) ...

                /// Email
                // ... (Code UI cho Email Field) ...
                // Bạn có thể thay thế toàn bộ khối này bằng:
                // EmailField(controller: _emailController),
                const SizedBox(height: 16),

                /// Password
                // ... (Code UI cho Password Field) ...
                // Bạn có thể thay thế toàn bộ khối này bằng:
                // PasswordField(
                //   controller: _passwordController,
                //   obscurePassword: _obscurePassword,
                //   onToggleObscure: () {
                //     setState(() {
                //       _obscurePassword = !_obscurePassword;
                //     });
                //   },
                // ),
                const SizedBox(height: 24),

                /// Login Button
                // ... (Code UI cho Login Button) ...
                // Bạn có thể thay thế toàn bộ khối này bằng:
                // LoginButton(
                //   onPressed: _loginUser,
                //   isLoading: false, // Bạn cần 1 biến _isLoading
                // ),

                // ... (Remember me & Forgot Password) ...

                /// Social buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      imagePath: 'assets/images/facebook.png',
                      onTap: _signInWithFacebook, // ✅ GỌI HÀM FACEBOOK
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      imagePath: 'assets/images/google.png',
                      onTap: _signInWithGoogle, // ✅ GỌI HÀM GOOGLE
                    ),
                    // ... (Các nút social khác) ...
                  ],
                ),
                // ... (Link Đăng ký, Điều khoản) ...
              ],
            ),
          ),
        ),
      ),
    );
  }
}
