import 'package:flutter/material.dart';

/// Widget hiển thị BottomSheet để người dùng chọn loại bài viết muốn tạo
class CreatePostBottomSheet extends StatelessWidget {
  final VoidCallback onBlogTap;
  final VoidCallback onCheckinTap;
  final VoidCallback onQuestionTap;

  const CreatePostBottomSheet({
    Key? key,
    required this.onBlogTap,
    required this.onCheckinTap,
    required this.onQuestionTap,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required VoidCallback onBlogTap,
    required VoidCallback onCheckinTap,
    required VoidCallback onQuestionTap,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostBottomSheet(
        onBlogTap: onBlogTap,
        onCheckinTap: onCheckinTap,
        onQuestionTap: onQuestionTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy chiều cao màn hình để tính vị trí option
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      key: const Key('create_post_bottom_sheet'),
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tạo bài viết',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 10),

          // Option Blog
          _buildOptionTile(
            key: const Key('create_post_blog_option'),
            semanticsLabel: 'create_post_blog_option',
            icon: Icons.edit_note,
            label: 'Blog',
            subLabel: 'Viết bài',
            onTap: onBlogTap,
            yPositionRatio: 0.68, // ✅ tỉ lệ ADB tap
          ),

          // Option Checkin
          _buildOptionTile(
            key: const Key('create_post_checkin_option'),
            semanticsLabel: 'create_post_checkin_option',
            icon: Icons.camera_alt_outlined,
            label: 'Checkin',
            onTap: onCheckinTap,
            yPositionRatio: 0.78,
          ),

          // Option Question
          _buildOptionTile(
            key: const Key('create_post_question_option'),
            semanticsLabel: 'create_post_question_option',
            icon: Icons.help_outline,
            label: 'Đặt câu hỏi',
            onTap: onQuestionTap,
            yPositionRatio: 0.88,
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    Key? key,
    String? semanticsLabel,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? subLabel,
    double? yPositionRatio, // tỷ lệ để Appium/ADB tap
  }) {
    return Semantics(
      label: semanticsLabel ?? label,
      button: true,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.black87, size: 28),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subLabel != null)
                    Text(
                      subLabel,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
