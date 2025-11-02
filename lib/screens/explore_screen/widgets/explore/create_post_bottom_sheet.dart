import 'package:flutter/material.dart';

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
    return Container(
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
          _buildOptionTile(
            icon: Icons.edit_note,
            label: 'Blog',
            subLabel: 'Viết bài',
            onTap: onBlogTap,
          ),
          _buildOptionTile(
            icon: Icons.camera_alt_outlined,
            label: 'Checkin',
            onTap: onCheckinTap,
          ),
          _buildOptionTile(
            icon: Icons.help_outline,
            label: 'Đặt câu hỏi',
            onTap: onQuestionTap,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? subLabel,
  }) {
    return InkWell(
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
    );
  }
}
