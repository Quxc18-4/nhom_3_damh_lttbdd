// File: screens/user_setting/profile_screen.dart
// (Đổi tên file từ profileScreen.dart)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Cập nhật đường dẫn import
import 'setting_account/settingAccountScreen.dart';
import 'account_info/accountSettingScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/journey_map/journeyMapScreen.dart';
// Import widget đã tách
import 'widget/profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu người dùng
    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
  }

  void _showFeatureComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName sắp ra mắt!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Hàm điều hướng (tách ra cho rõ ràng)
  void _navigateToAccountSetting() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountSettingScreen(userId: widget.userId),
      ),
    ).then((_) {
      // Tải lại dữ liệu khi quay về
      setState(() {
        _userFuture = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
      });
    });
  }

  void _navigateToSettingAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingAccountScreen()),
    );
  }

  void _navigateToJourneyMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyMapScreen(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text('Không thể tải dữ liệu người dùng.'),
            );
          }

          // Lấy dữ liệu
          final userData = snapshot.data!.data();
          final String userName = userData?['name'] ?? 'Chưa có tên';
          final String userEmail = userData?['email'] ?? 'Không có email';
          final String userRank = userData?['userRank'] ?? 'Chưa có hạng';
          // ✅ Lấy avatarUrl động
          final String avatarUrl =
              userData?['avatarUrl'] ?? "assets/images/logo.png";

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // === SỬ DỤNG WIDGET MỚI ===
                  UserInfoCard(
                    // ✅ Truyền avatarUrl động
                    avatarPath: avatarUrl.startsWith('http')
                        ? avatarUrl
                        : "assets/images/logo.png", // Cần xử lý Image.network nếu là URL
                    userName: userName,
                    userEmail: userEmail,
                    userRank: userRank,
                    onViewProfile: _navigateToAccountSetting,
                  ),
                  const SizedBox(height: 20),

                  const VipBanner(),
                  const SizedBox(height: 24),

                  const SectionTitle("Hành trình của bạn"),
                  ClickableCard([
                    MenuItem(
                      icon: Icons.map_outlined,
                      title: "Bản đồ hành trình",
                      onTap: _navigateToJourneyMap,
                    ),
                    MenuItem(
                      icon: Icons.description_outlined,
                      title: "Kế hoạch khám phá",
                      onTap: () =>
                          _showFeatureComingSoon(context, "Kế hoạch khám phá"),
                      showDivider: false,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  const SectionTitle("Quản lý thanh toán"),
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

                  const SectionTitle("Ưu đãi & Phần thưởng"),
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

                  const SectionTitle("Tài khoản & Bảo mật"),
                  ClickableCard([
                    MenuItem(
                      icon: Icons.settings_outlined,
                      title: "Cài đặt tài khoản",
                      onTap: _navigateToSettingAccount,
                    ),
                    MenuItem(
                      icon: Icons.person_outline,
                      title: "Thông tin cá nhân",
                      onTap: _navigateToAccountSetting,
                      showDivider: false,
                    ),
                  ]),
                  const SizedBox(height: 40),
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
