// File: screens/authentication/forgot_password/service/forgot_password_service.dart

import 'package:firebase_auth/firebase_auth.dart'; // Import thư viện Firebase Auth

// Lớp dịch vụ này chứa logic nghiệp vụ
class ForgotPasswordService {
  // `final`: Biến `_auth` được khởi tạo 1 lần và không bao giờ thay đổi.
  // `_auth`: Một instance (thể hiện) của dịch vụ Firebase Authentication.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Gửi email reset mật khẩu.
  /// Sẽ ném lỗi (throw) nếu có bất kỳ vấn đề gì.
  // `Future<void>`: Đây là một hàm `async` (bất đồng bộ)
  // và nó không trả về giá trị gì (`void`).
  Future<void> sendPasswordResetEmail(String email) async {
    // **Validation (Kiểm tra) cơ bản:**
    // Thực hiện kiểm tra cơ bản ngay tại Service.
    if (email.isEmpty) {
      // `throw Exception`: "Ném" ra một lỗi.
      // Lỗi này sẽ được "bắt" (catch) bởi lớp UI (Screen)
      // và hiển thị cho người dùng.
      throw Exception('Vui lòng nhập email của bạn.');
    }

    // **Logic nghiệp vụ:**
    // `await`: Tạm dừng hàm `sendPasswordResetEmail` tại đây
    // cho đến khi Firebase xử lý xong việc gửi email
    // (hoặc trả về lỗi).
    //
    // **Tại sao không dùng `try-catch` ở đây?**
    // Đây là một lựa chọn thiết kế. Service này "ủy thác"
    // việc xử lý lỗi cho lớp UI (màn hình).
    // Bất kỳ lỗi nào từ Firebase (ví dụ: 'invalid-email',
    // 'user-not-found') sẽ được `await` "ném" thẳng ra ngoài.
    await _auth.sendPasswordResetEmail(email: email);
  }
}
