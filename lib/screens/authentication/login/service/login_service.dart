// File: screens/authentication/login/service/login_service.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum UserRole { admin, user }

class LoginResult {
  final User user;
  final UserRole role;
  LoginResult(this.user, this.role);
}

class LoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  /// Kiểm tra vai trò (Admin/User) của người dùng
  Future<UserRole> _getUserRole(User user) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data['userRank'] == 'Admin') {
          return UserRole.admin;
        }
      }
    } catch (e) {
      print("Lỗi khi đọc userRank: $e");
    }
    return UserRole.user; // Mặc định là user
  }

  /// Đảm bảo thông tin user (từ social login) tồn tại trên Firestore
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
  }

  /// 1. Đăng nhập bằng Email và Password
  Future<LoginResult> loginWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      final User user = userCredential.user!;
      final UserRole role = await _getUserRole(user);
      return LoginResult(user, role);
    } on FirebaseAuthException catch (e) {
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

      await _ensureUserInFirestore(user, 'google.com');
      final UserRole role = await _getUserRole(user);
      return LoginResult(user, role);
    } catch (e) {
      print("Lỗi Google Sign-In: $e");
      throw Exception('Lỗi đăng nhập Google: $e');
    }
  }

  /// 3. Đăng nhập bằng Facebook
  Future<LoginResult> loginWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login();

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.token;
        final facebookAuthCredential = FacebookAuthProvider.credential(
          accessToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(
          facebookAuthCredential,
        );
        User user = userCredential.user!;

        await _ensureUserInFirestore(user, 'facebook.com');
        final UserRole role = await _getUserRole(user);
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
