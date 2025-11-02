// File: screens/user_setting/setting_account/settingAccountScreen.dart

import 'package:flutter/material.dart'; // Thư viện chính của Flutter
// Cập nhật đường dẫn
import 'package:nhom_3_damh_lttbdd/screens/authentication/login/loginScreen.dart'; // Màn hình đăng nhập
// Import Service và Widget
import 'service/setting_account_service.dart'; // Service xử lý đăng xuất
import 'widget/setting_account_widgets.dart'; // Các widget menu: tiêu đề, card, item

class SettingAccountScreen extends StatelessWidget { // Màn hình cài đặt tài khoản
  const SettingAccountScreen({Key? key}) : super(key: key);

  // Hàm xử lý logic (controller)
  Future<void> _signOut( // Đăng xuất người dùng
    BuildContext context, // Context để điều hướng và hiển thị dialog
    SettingAccountService service, // Service xử lý đăng xuất
  ) async {
    bool? confirmLogout = await showDialog<bool>( // Hiển thị dialog xác nhận
      context: context,
      builder: (BuildContext context) {
        return AlertDialog( // Dialog cảnh báo
          title: const Text('Xác nhận đăng xuất'), // Tiêu đề
          content: const Text( // Nội dung
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?',
          ),
          actions: <Widget>[ // Các nút
            TextButton( // Nút hủy
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(false), // Đóng dialog, trả về false
            ),
            TextButton( // Nút xác nhận
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red), // Chữ đỏ
              ),
              onPressed: () => Navigator.of(context).pop(true), // Đóng dialog, trả về true
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) { // Nếu người dùng xác nhận
      try {
        await service.signOut(); // Gọi service đăng xuất (Firebase Auth)

        Navigator.pushAndRemoveUntil( // Xóa toàn bộ stack, chuyển về Login
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()), // Màn hình mới
          (Route<dynamic> route) => false, // Xóa hết các route cũ
        );
      } catch (e) { // Bắt lỗi
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: $e'))); // Hiển thị lỗi
      }
    }
  }

  void _showActionInProgress(BuildContext context, String actionName) { // Hiển thị thông báo "đang phát triển"
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chức năng "$actionName" đang được phát triển.'), // Thông báo
        duration: const Duration(seconds: 2), // Hiển thị 2 giây
      ),
    );
  }

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    // Khởi tạo service trong hàm build (vì đây là StatelessWidget)
    final SettingAccountService service = SettingAccountService(); // Khởi tạo service

    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền xám nhạt
      appBar: AppBar( // Thanh tiêu đề
        leading: IconButton( // Nút back
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(), // Quay lại
        ),
        title: const Text( // Tiêu đề
          'Cài đặt tài khoản',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent, // Nền trong suốt
        foregroundColor: Colors.black87, // Màu chữ/icon
        elevation: 0, // Không bóng
        centerTitle: true, // Căn giữa
      ),
      body: SingleChildScrollView( // Cho phép cuộn
        child: Padding( // Padding toàn bộ
          padding: const EdgeInsets.all(16.0), // Cách đều 16dp
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
            children: [
              // === SỬ DỤNG WIDGET TỪ FILE MỚI ===
              buildSectionTitle("Tài khoản & Bảo mật"), // Tiêu đề nhóm
              buildClickableCard([ // Khung chứa các mục
                buildMenuItem( // Mục 1
                  icon: Icons.person_outline,
                  title: "Thông tin tài khoản",
                  onTap: () =>
                      _showActionInProgress(context, "Thông tin tài khoản"), // Chưa làm
                ),
                buildMenuItem( // Mục 2
                  icon: Icons.lock_outline,
                  title: "Mật khẩu & Bảo mật",
                  onTap: () =>
                      _showActionInProgress(context, "Mật khẩu & Bảo mật"),
                ),
                buildMenuItem( // Mục 3
                  icon: Icons.privacy_tip_outlined,
                  title: "Thiết lập chế độ riêng tư",
                  onTap: () =>
                      _showActionInProgress(context, "Thiết lập riêng tư"),
                  showDivider: false, // Không có gạch ngang
                ),
              ]),
              const SizedBox(height: 24), // Khoảng cách giữa các nhóm

              buildSectionTitle("Cài đặt"), // Nhóm cài đặt
              buildClickableCard([
                buildMenuItem(
                  icon: Icons.public,
                  title: "Quốc gia",
                  trailingText: "Việt Nam", // Hiển thị giá trị hiện tại
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

              buildSectionTitle("Cài đặt khác"), // Nhóm khác
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

              buildClickableCard([ // Nhóm đăng xuất (riêng)
                buildMenuItem(
                  icon: Icons.logout,
                  title: "Đăng xuất",
                  textColor: Colors.red, // Chữ đỏ
                  onTap: () => _signOut(context, service), // Gọi hàm đăng xuất
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