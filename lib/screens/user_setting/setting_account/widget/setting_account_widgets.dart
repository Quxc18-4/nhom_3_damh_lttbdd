// File: screens/user_setting/setting_account/widget/setting_account_widgets.dart

import 'package:flutter/material.dart';

/// Tiêu đề của một nhóm menu
Widget buildSectionTitle(String title) {
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
Widget buildClickableCard(List<Widget> items) {
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

/// Một hàng (row) trong menu
Widget buildMenuItem({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  String? trailingText,
  Color? textColor,
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
              child: Divider(height: 1, thickness: 1, color: Colors.grey[100]),
            ),
        ],
      ),
    ),
  );
}
