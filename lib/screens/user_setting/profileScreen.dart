// File: screens/user_setting/profile_screen.dart
// (Đổi tên file từ profileScreen.dart)

import 'package:flutter/material.dart'; // Thư viện chính của Flutter
import 'package:cloud_firestore/cloud_firestore.dart'; // Kết nối Firestore
// Cập nhật đường dẫn import
import 'setting_account/settingAccountScreen.dart'; // Màn hình cài đặt tài khoản
import 'account_info/accountSettingScreen.dart'; // Màn hình chỉnh sửa thông tin cá nhân
import 'package:nhom_3_damh_lttbdd/screens/journey_map/journeyMapScreen.dart'; // Màn hình bản đồ hành trình
// Import widget đã tách
import 'widget/profile_widgets.dart'; // Các widget: UserInfoCard, VipBanner, SectionTitle, v.v.

class ProfileScreen extends StatefulWidget { // Màn hình hồ sơ người dùng
  final String userId; // ID người dùng từ Firebase Auth

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState(); // Tạo state
}

class _ProfileScreenState extends State<ProfileScreen> { // State của màn hình
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture; // Future để tải dữ liệu người dùng

  @override
  void initState() { // Khởi tạo khi widget được tạo
    super.initState();
    // Tải dữ liệu người dùng
    _userFuture = FirebaseFirestore.instance // Gọi Firestore
        .collection('users') // Collection users
        .doc(widget.userId) // Document theo userId
        .get(); // Lấy dữ liệu
  }

  void _showFeatureComingSoon(BuildContext context, String featureName) { // Hiển thị thông báo "sắp ra mắt"
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName sắp ra mắt!'), // Nội dung
        duration: const Duration(seconds: 2), // Hiển thị 2 giây
      ),
    );
  }

  // Hàm điều hướng (tách ra cho rõ ràng)
  void _navigateToAccountSetting() { // Chuyển sang màn hình chỉnh sửa thông tin
    Navigator.push( // Mở màn hình mới
      context,
      MaterialPageRoute(
        builder: (context) => AccountSettingScreen(userId: widget.userId), // Truyền userId
      ),
    ).then((_) { // Khi quay lại
      // Tải lại dữ liệu khi quay về
      setState(() {
        _userFuture = FirebaseFirestore.instance // Tải lại dữ liệu mới
            .collection('users')
            .doc(widget.userId)
            .get();
      });
    });
  }

  void _navigateToSettingAccount() { // Chuyển sang màn hình cài đặt tài khoản
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingAccountScreen()), // Không cần userId
    );
  }

  void _navigateToJourneyMap() { // Chuyển sang màn hình bản đồ hành trình
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyMapScreen(userId: widget.userId), // Truyền userId
      ),
    );
  }

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền xám nhạt
      appBar: AppBar( // Thanh tiêu đề
        backgroundColor: Colors.transparent, // Nền trong suốt
        elevation: 0, // Không bóng
        foregroundColor: Colors.black, // Màu chữ/icon
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>( // Tải dữ liệu bất đồng bộ
        future: _userFuture, // Future đã khởi tạo
        builder: (context, snapshot) { // Xử lý các trạng thái
          if (snapshot.connectionState == ConnectionState.waiting) { // Đang tải
            return const Center(child: CircularProgressIndicator()); // Hiển thị loading
          }
          if (snapshot.hasError || // Có lỗi
              !snapshot.hasData || // Không có dữ liệu
              !snapshot.data!.exists) { // Document không tồn tại
            return const Center(
              child: Text('Không thể tải dữ liệu người dùng.'), // Thông báo lỗi
            );
          }

          // Lấy dữ liệu
          final userData = snapshot.data!.data(); // Dữ liệu người dùng
          final String userName = userData?['name'] ?? 'Chưa có tên'; // Tên, mặc định nếu null
          final String userEmail = userData?['email'] ?? 'Không có email'; // Email
          final String userRank = userData?['userRank'] ?? 'Chưa có hạng'; // Hạng
          // Lấy avatarUrl động
          final String avatarUrl =
              userData?['avatarUrl'] ?? "assets/images/logo.png"; // Ảnh đại diện

          return SingleChildScrollView( // Cho phép cuộn
            child: Padding( // Padding hai bên
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
                children: [
                  const SizedBox(height: 10), // Khoảng cách trên

                  // === SỬ DỤNG WIDGET MỚI ===
                  UserInfoCard( // Thẻ thông tin người dùng
                    // Truyền avatarUrl động
                    avatarPath: avatarUrl.startsWith('http') // Nếu là URL
                        ? avatarUrl // Dùng URL
                        : "assets/images/logo.png", // Nếu không, dùng ảnh mặc định
                    userName: userName,
                    userEmail: userEmail,
                    userRank: userRank,
                    onViewProfile: _navigateToAccountSetting, // Nhấn nút → sang chỉnh sửa
                  ),
                  const SizedBox(height: 20),

                  const VipBanner(), // Banner quảng cáo VIP
                  const SizedBox(height: 24),

                  const SectionTitle("Hành trình của bạn"), // Tiêu đề nhóm
                  ClickableCard([ // Khung chứa các mục
                    MenuItem( // Mục 1
                      icon: Icons.map_outlined,
                      title: "Bản đồ hành trình",
                      onTap: _navigateToJourneyMap, // Chuyển sang bản đồ
                    ),
                    MenuItem( // Mục 2
                      icon: Icons.description_outlined,
                      title: "Kế hoạch khám phá",
                      onTap: () =>
                          _showFeatureComingSoon(context, "Kế hoạch khám phá"), // Chưa làm
                      showDivider: false, // Không gạch ngang
                    ),
                  ]),
                  const SizedBox(height: 24),

                  const SectionTitle("Quản lý thanh toán"), // Nhóm thanh toán
                  ClickableCard([
                    MenuItem(
                      icon: Icons.credit_card,
                      title: "Thẻ tín dụng/ghi nợ",
                      onTap: () =>
                          _showFeatureComingSoon(context, "Quản lý thẻ"),
                    ),
                    MenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Ví điện tử",
                      onTap: () =>
                          _showFeatureComingSoon(context, "Ví điện tử"),
                    ),
                    MenuItem(
                      icon: Icons.account_balance_outlined,
                      title: "Chuyển khoản ngân hàng",
                      onTap: () => _showFeatureComingSoon(
                        context,
                        "Tài khoản ngân hàng",
                      ),
                    ),
                    MenuItem(
                      icon: Icons.star_border_outlined,
                      title: "Trả góp 0%",
                      onTap: () => _showFeatureComingSoon(context, "Trả góp"),
                      showDivider: false,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  const SectionTitle("Ưu đãi & Phần thưởng"), // Nhóm ưu đãi
                  ClickableCard([
                    MenuItem(
                      icon: Icons.confirmation_number_outlined,
                      title: "Đổi Xu Lấy Mã Ưu Đãi",
                      onTap: () =>
                          _showFeatureComingSoon(context, "Phần thưởng"),
                      showDivider: false,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  const SectionTitle("Tài khoản & Bảo mật"), // Nhóm cài đặt
                  ClickableCard([
                    MenuItem(
                      icon: Icons.settings_outlined,
                      title: "Cài đặt tài khoản",
                      onTap: _navigateToSettingAccount, // Sang cài đặt chung
                    ),
                    MenuItem(
                      icon: Icons.person_outline,
                      title: "Thông tin cá nhân",
                      onTap: _navigateToAccountSetting, // Sang chỉnh sửa hồ sơ
                      showDivider: false,
                    ),
                  ]),
                  const SizedBox(height: 40), // Khoảng cách dưới cùng
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Lưu ý: Cần sửa UserInfoCard để xử lý NetworkImage