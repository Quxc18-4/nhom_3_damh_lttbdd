// File: screens/authentication/register/service/register_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterService {
  // `final`: Khởi tạo 1 lần
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  /// Hàm private (dùng nội bộ)
  /// Đảm bảo thông tin user (từ social login) tồn tại trên Firestore.
  // **Tại sao?**
  // Khi user bấm "Đăng ký bằng Google", có 2 trường hợp:
  // 1. User này đã đăng nhập Google ở app khác -> Tài khoản Firebase Auth
  //    đã tồn tại, nhưng hồ sơ Firestore (database) có thể chưa.
  // 2. User này hoàn toàn mới.
  // Hàm này kiểm tra `!userDoc.exists` (hồ sơ chưa tồn tại),
  // nếu đúng, nó sẽ TẠO MỚI hồ sơ trong collection 'users'.
  // Về cơ bản, đây chính là logic "Đăng ký" cho social login.
  Future<void> _ensureUserInFirestore(User user, String providerId) async {
    final DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      // **TẠO HỒ SƠ (DATABASE):**
      await _firestore.collection('users').doc(user.uid).set({
        // Lấy thông tin có sẵn từ Google/Facebook
        'name': user.displayName ?? 'Người dùng $providerId',
        'fullName': user.displayName ?? '',
        'email': user.email ?? '',
        'avatarUrl': user.photoURL ?? '',
        'authProviders': [providerId], // 'google.com' hoặc 'facebook.com'
        'bio': '',
        'password': null, // `null` vì họ dùng social
        'joinedAt': FieldValue.serverTimestamp(), // Dùng giờ của server
        'followersCount': 0,
        'followingCount': 0,
        'userRank': 'Bronze', // Hạng mặc định
        'phoneNumber': user.phoneNumber ?? '',
        'birthDate': null,
        'gender': '',
        'city': '',
      });
    }
  }

  /// 1. Đăng ký bằng Email và Password
  // `Future<User>`: Hàm `async` này trả về đối tượng `User`
  // (của Firebase Auth) sau khi tạo thành công.
  Future<User> registerWithEmail(
    String nickname,
    String email,
    String password,
  ) async {
    try {
      // **Bước 1: TẠO XÁC THỰC (AUTH):**
      // Tạo một user mới trong hệ thống Firebase Authentication.
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? newUser = userCredential.user;

      if (newUser != null) {
        // **Bước 2: TẠO HỒ SƠ (DATABASE):**
        // Đây là bước BẮT BUỘC. Nếu không có bước này,
        // user có thể đăng nhập (Auth) nhưng app không có
        // thông tin gì về họ (tên, avatar, rank...).
        await _firestore.collection('users').doc(newUser.uid).set({
          'name': nickname,
          'fullName': '',
          'email': email,
          'password': null, // **BẢO MẬT:** KHÔNG BAO GIỜ lưu password
          'avatarUrl': '',
          'bio': '',
          'authProviders': ['password'], // Đánh dấu là user này dùng password
          'joinedAt': FieldValue.serverTimestamp(),
          'followersCount': 0,
          'followingCount': 0,
          'userRank': 'Bronze',
          'phoneNumber': '',
          'birthDate': null,
          'gender': '',
          'city': '',
        });
        return newUser; // Trả về user đã tạo
      } else {
        throw Exception('Không thể tạo người dùng mới.');
      }
    } on FirebaseAuthException catch (e) {
      // **Dịch lỗi (Catch & Throw):**
      // Bắt lỗi cụ thể của Firebase và "ném" (throw)
      // ra lỗi (Exception) với thông báo tiếng Việt
      // để View (màn hình) có thể hiển thị.
      if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email này đã được sử dụng.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email không hợp lệ.');
      }
      throw Exception('Đã có lỗi xảy ra. Vui lòng thử lại.');
    }
  }

  /// 2. Đăng nhập/Đăng ký bằng Google
  // **Tại sao gọi là "signIn"?**
  // Đối với Social, logic Đăng nhập và Đăng ký là MỘT.
  // Service sẽ "Đăng nhập" (signIn), sau đó
  // hàm `_ensureUserInFirestore` sẽ kiểm tra, nếu user
  // chưa có hồ sơ -> "Đăng ký" (tạo hồ sơ).
  Future<User> signInWithGoogle() async {
    try {
      // 1. Mở cửa sổ chọn tài khoản Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Đăng nhập Google đã bị hủy.');
      }

      // 2. Lấy token
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      // 3. Tạo "Giấy thông hành" Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Đăng nhập vào Firebase (Auth)
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User user = userCredential.user!;

      // 5. **GỌI HÀM ĐĂNG KÝ (DATABASE):**
      // Đảm bảo user này có hồ sơ trong Firestore.
      await _ensureUserInFirestore(user, 'google.com');
      return user; // Trả về user
    } catch (e) {
      print("Lỗi Google Sign-In: $e");
      throw Exception('Lỗi đăng nhập Google: $e');
    }
  }

  /// 3. Đăng nhập/Đăng ký bằng Facebook
  Future<User> signInWithFacebook() async {
    try {
      // 1. Mở cửa sổ Facebook, yêu cầu quyền 'email' và 'public_profile'
      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.token;
        // 2. Tạo "Giấy thông hành" Firebase
        final facebookAuthCredential = FacebookAuthProvider.credential(
          accessToken,
        );

        // 3. Đăng nhập vào Firebase (Auth)
        UserCredential userCredential = await _auth.signInWithCredential(
          facebookAuthCredential,
        );
        User user = userCredential.user!;

        // 4. **GỌI HÀM ĐĂNG KÝ (DATABASE):**
        await _ensureUserInFirestore(user, 'facebook.com');
        return user;
      } else if (result.status == LoginStatus.cancelled) {
        throw Exception('Đăng nhập Facebook đã bị hủy.');
      } else {
        throw Exception('Lỗi đăng nhập Facebook: ${result.message}');
      }
    } catch (e) {
      print("Lỗi Facebook Sign-In: $e");
      throw Exception('Lỗi đăng nhập Facebook: $e');
    }
  }
}
