import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nhom_3_damh_lttbdd/screens/loginScreen.dart';

class SettingAccountScreen extends StatelessWidget {
  const SettingAccountScreen({Key? key}) : super(key: key);

  Future<void> _signOut(BuildContext context) async {
    // Hiển thị dialog xác nhận trước khi đăng xuất
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(false), // Trả về false
            ),
            TextButton(
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(context).pop(true), // Trả về true
            ),
          ],
        );
      },
    );

    // Nếu người dùng xác nhận
    if (confirmLogout == true) {
      try {
        // Gọi Firebase Auth để đăng xuất
        await FirebaseAuth.instance.signOut();

        // Sau khi đăng xuất thành công, chuyển về màn hình Login
        // Dùng pushAndRemoveUntil để xóa hết các màn hình cũ
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false, // Xóa hết stack
        );
      } catch (e) {
        // Hiển thị lỗi nếu có
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hàm để hiển thị SnackBar (tạm thời)
    void _showActionInProgress(BuildContext context, String actionName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chức năng "$actionName" đang được phát triển.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Cài đặt tài khoản',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Nhóm Tài khoản & Bảo mật ---
              _buildSectionTitle("Tài khoản & Bảo mật"),
              _buildClickableCard([
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: "Thông tin tài khoản",
                  onTap: () =>
                      _showActionInProgress(context, "Thông tin tài khoản"),
                ),
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: "Mật khẩu & Bảo mật",
                  onTap: () =>
                      _showActionInProgress(context, "Mật khẩu & Bảo mật"),
                ),
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: "Thiết lập chế độ riêng tư",
                  onTap: () =>
                      _showActionInProgress(context, "Thiết lập riêng tư"),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 24),

              // --- Nhóm Cài đặt ---
              _buildSectionTitle("Cài đặt"),
              _buildClickableCard([
                _buildMenuItem(
                  icon: Icons.public,
                  title: "Quốc gia",
                  trailingText: "Việt Nam",
                  onTap: () => _showActionInProgress(context, "Chọn quốc gia"),
                ),
                _buildMenuItem(
                  icon: Icons.monetization_on_outlined,
                  title: "Tiền tệ",
                  trailingText: "Việt Nam Đồng",
                  onTap: () => _showActionInProgress(context, "Chọn tiền tệ"),
                ),
                _buildMenuItem(
                  icon: Icons.translate,
                  title: "Ngôn ngữ",
                  trailingText: "Tiếng Việt",
                  onTap: () => _showActionInProgress(context, "Chọn ngôn ngữ"),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 24),

              // --- Nhóm Cài đặt khác ---
              _buildSectionTitle("Cài đặt khác"),
              _buildClickableCard([
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: "Cài đặt thông báo",
                  onTap: () =>
                      _showActionInProgress(context, "Cài đặt thông báo"),
                ),
                _buildMenuItem(
                  icon: Icons.article_outlined,
                  title: "Điều khoản & điều kiện",
                  onTap: () => _showActionInProgress(context, "Điều khoản"),
                ),
                _buildMenuItem(
                  icon: Icons.shield_outlined,
                  title: "Chính sách quyền riêng tư",
                  onTap: () => _showActionInProgress(context, "Chính sách"),
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: "Trợ giúp & Hỗ trợ",
                  onTap: () => _showActionInProgress(context, "Hỗ trợ"),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 24),

              // --- Nút Đăng xuất ---
              _buildClickableCard([
                _buildMenuItem(
                  icon: Icons.logout,
                  title: "Đăng xuất",
                  textColor: Colors.red, // Thêm màu đỏ để nhấn mạnh
                  onTap: () => _signOut(context),
                  showDivider: false,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET TÁI SỬ DỤNG (có thể tách ra file riêng để dùng chung) ---

  /// Tiêu đề của một nhóm menu
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  /// Một thẻ bao bọc danh sách các mục có thể bấm vào
  Widget _buildClickableCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  /// Một hàng (row) trong menu (được nâng cấp)
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? trailingText, // Mới: Thêm text ở cuối
    Color? textColor, // Mới: Tùy chỉnh màu chữ
    bool showDivider = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: textColor ?? Colors.grey[600]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor ?? Colors.black87,
                      ),
                    ),
                  ),
                  if (trailingText != null)
                    Text(
                      trailingText,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(left: 50.0),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey[100],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
