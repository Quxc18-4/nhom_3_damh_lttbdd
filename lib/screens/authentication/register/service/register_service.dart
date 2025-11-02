// File: screens/authentication/register/service/register_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  /// Đảm bảo thông tin user (từ social login) tồn tại trên Firestore
  /// (Tương tự như LoginService)
  Future<void> _ensureUserInFirestore(User user, String providerId) async {
    final DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName ?? 'Người dùng $providerId',
        'fullName': user.displayName ?? '',
        'email': user.email ?? '',
        'avatarUrl': user.photoURL ?? '',
        'authProviders': [providerId],
        'bio': '',
        'password': null, // Mật khẩu null vì đăng nhập qua social
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
  }

  /// 1. Đăng ký bằng Email và Password
  Future<User> registerWithEmail(
    String nickname,
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? newUser = userCredential.user;

      if (newUser != null) {
        // Tạo document user trong Firestore
        await _firestore.collection('users').doc(newUser.uid).set({
          'name': nickname,
          'fullName': '',
          'email': email,
          'password': null, // Không bao giờ lưu password
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
        return newUser;
      } else {
        throw Exception('Không thể tạo người dùng mới.');
      }
    } on FirebaseAuthException catch (e) {
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
  Future<User> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Đăng nhập Google đã bị hủy.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User user = userCredential.user!;

      // Kiểm tra/Tạo user trong Firestore
      await _ensureUserInFirestore(user, 'google.com');
      return user;
    } catch (e) {
      print("Lỗi Google Sign-In: $e");
      throw Exception('Lỗi đăng nhập Google: $e');
    }
  }

  /// 3. Đăng nhập/Đăng ký bằng Facebook
  Future<User> signInWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.token;
        final facebookAuthCredential = FacebookAuthProvider.credential(
          accessToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(
          facebookAuthCredential,
        );
        User user = userCredential.user!;

        // Kiểm tra/Tạo user trong Firestore
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
