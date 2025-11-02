import 'package:flutter/material.dart';

/// Widget riêng để chỉnh sửa bio
class BioEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onCancel;

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
        TextField(
          controller: controller,
          autofocus: true,
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
            TextButton(onPressed: onCancel, child: const Text("Hủy")),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSave,
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
