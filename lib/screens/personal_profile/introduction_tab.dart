import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/service/introduction_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/widgets/introduction_tab/bio_editor.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/widgets/introduction_tab/stat_card.dart';

class IntroductionTabContent extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final List<Post> userPosts;
  final bool isMyProfile;
  final String userId;

  const IntroductionTabContent({
    Key? key,
    required this.userData,
    required this.userPosts,
    required this.isMyProfile,
    required this.userId,
  }) : super(key: key);

  @override
  State<IntroductionTabContent> createState() => _IntroductionTabContentState();
}

class _IntroductionTabContentState extends State<IntroductionTabContent> {
  final IntroductionService _service = IntroductionService();

  bool _isEditingBio = false;
  bool _isBioLoading = false;
  bool _isLocaleReady = false;

  late TextEditingController _bioController;

  int _destinationCount = 0;
  int _postCount = 0;
  int _totalLikes = 0;
  int _totalComments = 0;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.userData?['bio'] ?? '');
    _initLocale();
    _updateAchievements();
  }

  Future<void> _initLocale() async {
    await initializeDateFormatting('vi_VN');
    setState(() => _isLocaleReady = true);
  }

  void _updateAchievements() {
    final result = _service.calculateAchievements(
      widget.userData,
      widget.userPosts,
    );
    setState(() {
      _destinationCount = result['destinationCount']!;
      _postCount = result['postCount']!;
      _totalLikes = result['totalLikes']!;
      _totalComments = result['totalComments']!;
    });
  }

  Future<void> _saveBio() async {
    if (_isBioLoading) return;
    setState(() => _isBioLoading = true);

    try {
      await _service.saveBio(widget.userId, _bioController.text.trim());
      setState(() {
        _isEditingBio = false;
        _isBioLoading = false;
        widget.userData?['bio'] = _bioController.text.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cập nhật giới thiệu thành công!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isBioLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleReady) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    final String bio = widget.userData?['bio'] ?? '';
    final String city = widget.userData?['city'] ?? 'Không xác định';
    final Timestamp? joinedAt = widget.userData?['joinedAt'];
    final joinedText = joinedAt != null
        ? "Tham gia từ ${DateFormat('MMMM, yyyy', 'vi_VN').format(joinedAt.toDate())}"
        : "Không rõ";

    final String bioText = bio.isEmpty
        ? (widget.isMyProfile
              ? "Hãy viết gì đó để mọi người biết tới bạn..."
              : "Có 1 luồng năng lượng thần bí bao quanh người dùng này")
        : bio;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroCard(bioText, city, joinedText),
          const SizedBox(height: 24),
          _buildAchievements(),
        ],
      ),
    );
  }

  Widget _buildIntroCard(String bio, String city, String joined) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "●  Giới thiệu",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (widget.isMyProfile && !_isEditingBio)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => setState(() => _isEditingBio = true),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditingBio)
              BioEditor(
                controller: _bioController,
                isLoading: _isBioLoading,
                onSave: _saveBio,
                onCancel: () {
                  setState(() {
                    _isEditingBio = false;
                    _bioController.text = widget.userData?['bio'] ?? '';
                  });
                },
              )
            else
              Text(
                bio,
                style: TextStyle(
                  color: bio.startsWith("Hãy viết")
                      ? Colors.grey
                      : Colors.black,
                  height: 1.5,
                ),
              ),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on_outlined, city),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today_outlined, joined),
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
        Expanded(
          child: Text(text, style: TextStyle(color: Colors.grey[800])),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    final format = NumberFormat.compact(locale: 'en_US');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            "↳  Thành tích",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            StatCard(
              value: '$_destinationCount',
              label: 'Điểm đến',
              color: Colors.blue.shade50,
            ),
            StatCard(
              value: '$_postCount',
              label: 'Bài viết',
              color: Colors.orange.shade50,
            ),
            StatCard(
              value: format.format(_totalLikes),
              label: 'Lượt thích',
              color: Colors.green.shade50,
            ),
            StatCard(
              value: format.format(_totalComments),
              label: 'Bình luận',
              color: Colors.purple.shade50,
            ),
          ],
        ),
      ],
    );
  }
}
