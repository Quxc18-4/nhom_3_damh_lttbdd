// File: screens/authentication/forgot_password/service/forgot_password_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Gửi email reset mật khẩu.
  /// Sẽ ném lỗi (throw) nếu có bất kỳ vấn đề gì.
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      throw Exception('Vui lòng nhập email của bạn.');
    }
    // Để cho Firebase ném lỗi (ví dụ: invalid-email)
    // Lớp UI (màn hình) sẽ chịu trách nhiệm bắt (catch) lỗi này
    await _auth.sendPasswordResetEmail(email: email);
  }
}
