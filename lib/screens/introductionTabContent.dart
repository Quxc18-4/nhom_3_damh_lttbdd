import 'package:flutter/material.dart';


// Đặt widget này vào file personal_profile_screen.dart hoặc file riêng

class IntroductionTabContent extends StatelessWidget {
  const IntroductionTabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroductionCard(),
          const SizedBox(height: 24),
          _buildAchievementsSection(),
        ],
      ),
    );
  }

  // --- WIDGETS CON CHO TAB GIỚI THIỆU ---

  Widget _buildIntroductionCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              " ●  Giới thiệu",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              "Yêu thích khám phá những vùng đất mới, trải nghiệm văn hóa địa phương và chia sẻ những câu chuyện du lịch thú vị. Đam mê nhiếp ảnh và viết blog về những chuyến đi đáng nhớ.",
              style: TextStyle(height: 1.5), // Tăng khoảng cách dòng
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on_outlined, "Thành phố Hồ Chí Minh"),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today_outlined, "Tham gia từ tháng 3, 2023"),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.work_outline, "Travel Blogger & Photographer"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            " ↳  Thành tích",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Sử dụng GridView để tạo lưới 2x2
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8, // Điều chỉnh tỉ lệ của card
          children: [
            _buildStatCard("15", "Điểm đến", Colors.blue.shade50),
            _buildStatCard("28", "Bài viết", Colors.orange.shade50),
            _buildStatCard("1.2K", "Lượt thích", Colors.green.shade50),
            _buildStatCard("456", "Bình luận", Colors.purple.shade50),
          ],
        )
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

