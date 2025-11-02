import 'package:flutter/material.dart';

/// Widget để chỉnh sửa tiểu sử (bio) của user
class BioEditor extends StatelessWidget {
  final TextEditingController
  controller; // Controller để quản lý nội dung TextField
  final bool isLoading; // Trạng thái đang lưu bio hay không
  final VoidCallback onSave; // Callback khi nhấn nút Lưu
  final VoidCallback onCancel; // Callback khi nhấn nút Hủy

  const BioEditor({
    Key? key,
    required this.controller,
    required this.isLoading,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // TextField để người dùng nhập bio
        TextField(
          controller: controller,
          autofocus: true, // tự động focus khi mở editor
          maxLines: 4,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: "Viết gì đó về bạn...",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Nút Hủy
            TextButton(onPressed: onCancel, child: const Text("Hủy")),
            const SizedBox(width: 8),
            // Nút Lưu
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Lưu"),
            ),
          ],
        ),
      ],
    );
  }
}
