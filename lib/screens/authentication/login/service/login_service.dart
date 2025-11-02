// File: screens/authentication/login/service/login_service.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// `enum` (kiểu liệt kê) để định nghĩa rõ 2 vai trò
enum UserRole { admin, user }

/// Một class (lớp) tùy chỉnh để gói (wrap) kết quả trả về.
/// **Tại sao?** An toàn kiểu (type-safe). Thay vì trả về 1 List
/// (ví dụ `[user, 'admin']`) rất dễ nhầm lẫn, ta trả về
/// 1 đối tượng có tên thuộc tính rõ ràng.
class LoginResult {
  final User user;
  final UserRole role;
  LoginResult(this.user, this.role);
}

class LoginService {
  // `final`: Các instance (thể hiện) của dịch vụ
  // được khởi tạo 1 lần và không bao giờ thay đổi.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  /// Hàm private (dùng nội bộ) để kiểm tra vai trò từ Firestore
  Future<UserRole> _getUserRole(User user) async {
    try {
      // 1. Đọc tài liệu (document) của user từ collection 'users'
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        // 2. Nếu trường 'userRank' là 'Admin' -> trả về Admin
        if (data['userRank'] == 'Admin') {
          return UserRole.admin;
        }
      }
    } catch (e) {
      print("Lỗi khi đọc userRank: $e");
      // Bỏ qua lỗi, coi như là user thường
    }
    return UserRole.user; // 3. Mặc định là user
  }

  /// Hàm private (Rất quan trọng) đảm bảo user social tồn tại trong Firestore
  // **Tại sao?** Khi đăng nhập bằng Google/Facebook, bạn chỉ
  // "xác thực" (Auth) chứ chưa "tạo hồ sơ" (Database).
  // Hàm này kiểm tra: "Hồ sơ của user này đã có trong 'users'
  // collection chưa?". Nếu chưa (`!userDoc.exists`) -> tạo mới.
  Future<void> _ensureUserInFirestore(User user, String providerId) async {
    final DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      // Nếu user chưa tồn tại -> Tạo mới (giống hệt logic Register)
      await _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName ?? 'Người dùng $providerId',
        'fullName': user.displayName ?? '',
        'email': user.email ?? '',
        'avatarUrl': user.photoURL ?? '',
        'authProviders': [providerId], // Lưu 'google.com' hoặc 'facebook.com'
        'bio': '',
        'password': null, // null vì họ dùng social login
        'joinedAt': FieldValue.serverTimestamp(), // Dùng giờ của server
        'followersCount': 0,
        'followingCount': 0,
        'userRank': 'Bronze', // Mặc định
        'phoneNumber': user.phoneNumber ?? '',
        'birthDate': null,
        'gender': '',
        'city': '',
      });
    }
  }

  /// 1. Đăng nhập bằng Email và Password
  // `Future<LoginResult>`: Hàm `async` này trả về 1 `LoginResult`
  Future<LoginResult> loginWithEmail(String email, String password) async {
    try {
      // 1. Gọi Firebase Auth
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      final User user = userCredential.user!;
      // 2. Lấy vai trò (Admin hay User)
      final UserRole role = await _getUserRole(user);
      // 3. Trả về kết quả
      return LoginResult(user, role);
    } on FirebaseAuthException catch (e) {
      // `catch (e)`: Bắt lỗi nếu Firebase trả về.
      // `throw Exception`: Ném lỗi đã được "dịch"
      // sang tiếng Việt để UI (View) bắt và hiển thị.
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        throw Exception('Email hoặc mật khẩu không chính xác.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Định dạng email không hợp lệ.');
      }
      throw Exception('Đã có lỗi xảy ra. Vui lòng thử lại.');
    }
  }

  /// 2. Đăng nhập bằng Google
  Future<LoginResult> loginWithGoogle() async {
    try {
      // 1. Mở cửa sổ chọn tài khoản Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Đăng nhập Google đã bị hủy.');
      }

      // 2. Lấy token xác thực từ Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      // 3. Tạo "Giấy thông hành" (Credential) của Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Dùng "Giấy thông hành" đó để đăng nhập vào Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User user = userCredential.user!;

      // 5. Đảm bảo user này có hồ sơ trong Firestore
      await _ensureUserInFirestore(user, 'google.com');
      // 6. Lấy vai trò (Admin hay User)
      final UserRole role = await _getUserRole(user);
      // 7. Trả về kết quả
      return LoginResult(user, role);
    } catch (e) {
      print("Lỗi Google Sign-In: $e");
      throw Exception('Lỗi đăng nhập Google: $e');
    }
  }

  /// 3. Đăng nhập bằng Facebook (Logic tương tự Google)
  Future<LoginResult> loginWithFacebook() async {
    try {
      // 1. Mở cửa sổ đăng nhập Facebook
      final result = await _facebookAuth.login();

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.token;
        // 2. Tạo "Giấy thông hành" (Credential)
        final facebookAuthCredential = FacebookAuthProvider.credential(
          accessToken,
        );

        // 3. Đăng nhập vào Firebase
        UserCredential userCredential = await _auth.signInWithCredential(
          facebookAuthCredential,
        );
        User user = userCredential.user!;

        // 4. Đảm bảo user có hồ sơ
        await _ensureUserInFirestore(user, 'facebook.com');
        // 5. Lấy vai trò
        final UserRole role = await _getUserRole(user);
        // 6. Trả về kết quả
        return LoginResult(user, role);
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
