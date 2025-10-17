import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int? _selectedMethod;

  // --- HÀM XỬ LÝ KHI NHẤN NÚT "TIẾP TỤC" ---
  void _handleContinue() {
    // Chỉ xử lý khi phương thức Email được chọn
    if (_selectedMethod == 0) {
      // Gọi trực tiếp dialog nhập email tùy chỉnh
      _showCustomEmailInputDialog();
    }
  }

  // --- HÀM GỬI EMAIL ĐẶT LẠI MẬT KHẨU (LOGIC XỬ LÝ) ---
  Future<void> _sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      _showResultDialog(
        title: 'Lỗi',
        content: 'Vui lòng nhập email của bạn để tiếp tục.',
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Navigator.of(context).pop(); // Tắt loading

      // Hiển thị dialog thành công
      _showResultDialog(
        title: 'Yêu Cầu Thành Công',
        content:
            'Nếu email $email tồn tại trong hệ thống, một liên kết sẽ được gửi đến. Vui lòng kiểm tra hộp thư (và cả mục Spam).',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );
    } on FirebaseAuthException {
      Navigator.of(context).pop(); // Tắt loading

      // Dù lỗi là gì, vẫn hiển thị thông báo thành công để bảo mật
      _showResultDialog(
        title: 'Yêu Cầu Thành Công',
        content:
            'Nếu email $email tồn tại trong hệ thống, một liên kết sẽ được gửi đến. Vui lòng kiểm tra hộp thư.',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );
    }
  }

  // --- CÁC HÀM HIỂN THỊ DIALOG (GIAO DIỆN) ---

  // Dialog 1: Nhập email (đã được refactor)
  // Thay thế hàm này trong file forgotPasswordScreen.dart

  Future<void> _showCustomEmailInputDialog() async {
    final TextEditingController emailController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible:
          true, // <-- Đảm bảo dialog có thể đóng khi nhấn ra ngoài
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Nhập email của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chúng tôi sẽ gửi một liên kết đặt lại mật khẩu đến email này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'example@email.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Gửi'),
                  onPressed: () {
                    final String email = emailController.text.trim();
                    Navigator.of(context).pop();
                    _sendPasswordResetEmail(email);
                  },
                ),
                // NÚT "HỦY" ĐÃ ĐƯỢC XÓA KHỎI ĐÂY
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog 2: Hiển thị kết quả (tên đã được đổi cho rõ ràng)
  Future<void> _showResultDialog({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Đóng dialog
                      if (title.contains('Thành Công')) {
                        // Quay về màn hình trước đó (Login)
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- PHẦN BUILD GIAO DIỆN (KHÔNG THAY ĐỔI) ---
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Chọn phương thức xác minh mà bạn muốn đặt lại mật khẩu.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildMethodOption(
                index: 0,
                imagePath: 'assets/images/forgotpasswordgmail.png',
                title: 'Email đặt lại mật khẩu',
                isEnabled: true,
                onTap: () => setState(() => _selectedMethod = 0),
              ),
              const SizedBox(height: 16),
              _buildMethodOption(
                index: 1,
                imagePath: 'assets/images/forgotpasswordgoogle.png',
                title: 'Google Authenticator (Sắp ra mắt)',
                isEnabled: false,
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _buildMethodOption(
                index: 2,
                imagePath: 'assets/images/forgotpasswordnumberphone.png',
                title: 'Số điện thoại/SMS (Sắp ra mắt)',
                isEnabled: false,
                onTap: () {},
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedMethod == 0 ? _handleContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[400],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.orange[200],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tiếp tục',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET CHỌN PHƯƠNG THỨC (KHÔNG THAY ĐỔI) ---
  Widget _buildMethodOption({
    required int index,
    required String imagePath,
    required String title,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    final isSelected = _selectedMethod == index;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.blue[400]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isEnabled)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue[400]! : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue[400],
                            ),
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
