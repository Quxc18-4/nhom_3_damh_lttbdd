// File: screens/user_setting/setting_account/service/setting_account_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class SettingAccountService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // (Không xử lý điều hướng ở đây, để UI tự làm)
    } catch (e) {
      print("Lỗi đăng xuất: $e");
      rethrow;
    }
  }
}
