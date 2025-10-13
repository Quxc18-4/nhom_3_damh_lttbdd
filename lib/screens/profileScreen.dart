import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/screens/settingAccountScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/accountSettingScreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dữ liệu tĩnh (sau này sẽ thay bằng dữ liệu từ database)
    const String userName = "Mydei Nguyễn";
    const String userPhone = "+84 123 456 789";
    const String userRank = "Bronze";
    // Lưu ý: Đảm bảo bạn có file logo.png trong assets/images/
    const String avatarPath = "assets/images/logo.png";

    // Hàm để hiển thị SnackBar khi bấm vào
    void _showFeatureComingSoon(BuildContext context, String featureName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$featureName sắp ra mắt!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      // 👇 WIDGET QUAN TRỌNG NHẤT ĐỂ TRÁNH TRÀN MÀN HÌNH
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // --- Thẻ thông tin người dùng ---
              _buildUserInfoCard(
                context,
                avatarPath: avatarPath,
                userName: userName,
                userPhone: userPhone,
                userRank: userRank,
              ),
              const SizedBox(height: 20),

              // --- Banner VIP ---
              _buildVipBanner(context),
              const SizedBox(height: 24),

              // --- Nhóm menu chính ---
              _buildSectionTitle("Hành trình của bạn"),
              _buildClickableCard(
                context,
                [
                  _buildMenuItem(
                    icon: Icons.map_outlined,
                    title: "Bản đồ hành trình",
                    onTap: () => _showFeatureComingSoon(context, "Bản đồ hành trình"),
                  ),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: "Kế hoạch khám phá",
                    onTap: () => _showFeatureComingSoon(context, "Kế hoạch khám phá"),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Nhóm Lựa chọn thanh toán ---
              _buildSectionTitle("Quản lý thanh toán"),
              _buildClickableCard(
                context,
                [
                  _buildMenuItem(
                    icon: Icons.credit_card,
                    title: "Thẻ tín dụng/ghi nợ",
                    onTap: () => _showFeatureComingSoon(context, "Quản lý thẻ"),
                  ),
                  _buildMenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Ví điện tử",
                    onTap: () => _showFeatureComingSoon(context, "Ví điện tử"),
                  ),
                  _buildMenuItem(
                    icon: Icons.account_balance_outlined,
                    title: "Chuyển khoản ngân hàng",
                    onTap: () => _showFeatureComingSoon(context, "Tài khoản ngân hàng"),
                  ),
                  _buildMenuItem(
                    icon: Icons.star_border_outlined,
                    title: "Trả góp 0%",
                    onTap: () => _showFeatureComingSoon(context, "Trả góp"),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Nhóm Phần thưởng ---
              _buildSectionTitle("Ưu đãi & Phần thưởng"),
              _buildClickableCard(
                context,
                [
                  _buildMenuItem(
                    icon: Icons.confirmation_number_outlined,
                    title: "Đổi Xu Lấy Mã Ưu Đãi",
                    onTap: () => _showFeatureComingSoon(context, "Phần thưởng"),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Nhóm Cài đặt & Thông tin ---
              _buildSectionTitle("Tài khoản & Bảo mật"),
              _buildClickableCard(
                context,
                [
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: "Cài đặt tài khoản",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingAccountScreen()));
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: "Thông tin cá nhân",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AccountInfoScreen()));
                    },
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET TÁI SỬ DỤNG ---

  Widget _buildUserInfoCard(BuildContext context,
      {required String avatarPath,
        required String userName,
        required String userPhone,
        required String userRank}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage: AssetImage(avatarPath),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userPhone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        userRank,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AccountInfoScreen())
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Xem hồ sơ của tôi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVipBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200)),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text.rich(TextSpan(
                text: "Nâng cấp ",
                style: TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                      text: 'TriplyVIP ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'để tận hưởng nhiều ưu đãi hơn.')
                ])),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildClickableCard(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: Colors.grey[600]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style:
                      const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 50.0),
            child: Divider(height: 1, thickness: 1, color: Colors.grey[100]),
          )
      ],
    );
  }
}