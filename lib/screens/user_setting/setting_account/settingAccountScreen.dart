// File: screens/user_setting/setting_account/settingAccountScreen.dart

import 'package:flutter/material.dart';
// Cập nhật đường dẫn
import 'package:nhom_3_damh_lttbdd/screens/authentication/login/loginScreen.dart';
// Import Service và Widget
import 'service/setting_account_service.dart';
import 'widget/setting_account_widgets.dart';

class SettingAccountScreen extends StatelessWidget {
  const SettingAccountScreen({Key? key}) : super(key: key);

  // Hàm xử lý logic (controller)
  Future<void> _signOut(
    BuildContext context,
    SettingAccountService service,
  ) async {
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
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      try {
        await service.signOut(); // Gọi service

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: $e')));
      }
    }
  }

  void _showActionInProgress(BuildContext context, String actionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chức năng "$actionName" đang được phát triển.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Khởi tạo service trong hàm build (vì đây là StatelessWidget)
    final SettingAccountService service = SettingAccountService();

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
              // === SỬ DỤNG WIDGET TỪ FILE MỚI ===
              buildSectionTitle("Tài khoản & Bảo mật"),
              buildClickableCard([
                buildMenuItem(
                  icon: Icons.person_outline,
                  title: "Thông tin tài khoản",
                  onTap: () =>
                      _showActionInProgress(context, "Thông tin tài khoản"),
                ),
                buildMenuItem(
                  icon: Icons.lock_outline,
                  title: "Mật khẩu & Bảo mật",
                  onTap: () =>
                      _showActionInProgress(context, "Mật khẩu & Bảo mật"),
                ),
                buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: "Thiết lập chế độ riêng tư",
                  onTap: () =>
                      _showActionInProgress(context, "Thiết lập riêng tư"),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 24),

              buildSectionTitle("Cài đặt"),
              buildClickableCard([
                buildMenuItem(
                  icon: Icons.public,
                  title: "Quốc gia",
                  trailingText: "Việt Nam",
                  onTap: () => _showActionInProgress(context, "Chọn quốc gia"),
                ),
                buildMenuItem(
                  icon: Icons.monetization_on_outlined,
                  title: "Tiền tệ",
                  trailingText: "Việt Nam Đồng",
                  onTap: () => _showActionInProgress(context, "Chọn tiền tệ"),
                ),
                buildMenuItem(
                  icon: Icons.translate,
                  title: "Ngôn ngữ",
                  trailingText: "Tiếng Việt",
                  onTap: () => _showActionInProgress(context, "Chọn ngôn ngữ"),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 24),

              buildSectionTitle("Cài đặt khác"),
              buildClickableCard([
                buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: "Cài đặt thông báo",
                  onTap: () =>
                      _showActionInProgress(context, "Cài đặt thông báo"),
                ),
                buildMenuItem(
                  icon: Icons.article_outlined,
                  title: "Điều khoản & điều kiện",
                  onTap: () => _showActionInProgress(context, "Điều khoản"),
                ),
                buildMenuItem(
                  icon: Icons.shield_outlined,
                  title: "Chính sách quyền riêng tư",
                  onTap: () => _showActionInProgress(context, "Chính sách"),
                ),
                buildMenuItem(
                  icon: Icons.help_outline,
                  title: "Trợ giúp & Hỗ trợ",
                  onTap: () => _showActionInProgress(context, "Hỗ trợ"),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 24),

              buildClickableCard([
                buildMenuItem(
                  icon: Icons.logout,
                  title: "Đăng xuất",
                  textColor: Colors.red,
                  onTap: () => _signOut(context, service), // Gọi hàm xử lý
                  showDivider: false,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
