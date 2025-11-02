// File: screens/user_setting/account_setting/widget/account_setting_widgets.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Container chung cho các nhóm
Widget buildGroupContainer({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: child,
  );
}

/// Tiêu đề của một phần (ví dụ: "Dữ liệu cá nhân")
Widget buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

/// Ô nhập liệu có nhãn
Widget buildLabeledTextField(
  String label,
  TextEditingController controller, {
  String hint = "",
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label.isNotEmpty)
        Text(label, style: const TextStyle(color: Colors.grey)),
      if (label.isNotEmpty) const SizedBox(height: 4),
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    ],
  );
}

/// Widget chọn ngày sinh
class DatePickerWidget extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const DatePickerWidget({Key? key, this.selectedDate, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ngày sinh", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate == null
                      ? "Chưa đặt"
                      : DateFormat('dd/MM/yyyy').format(selectedDate!),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget chọn giới tính
class GenderPickerWidget extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String?> onChanged;

  const GenderPickerWidget({
    Key? key,
    this.selectedGender,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Giới tính", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: selectedGender,
          hint: const Text("Chưa đặt"),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          items: ["Nam", "Nữ", "Khác"]
              .map(
                (label) => DropdownMenuItem(value: label, child: Text(label)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Widget hiển thị Email (chỉ đọc)
class EmailSection extends StatelessWidget {
  final TextEditingController controller;
  const EmailSection({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildSectionHeader("Email"),
        buildGroupContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Email được sử dụng để đăng nhập và nhận thông báo.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller,
                enabled: false,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget hiển thị Số điện thoại (có thể xóa)
class PhoneSection extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onDelete;
  const PhoneSection({
    Key? key,
    required this.controller,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool hasPhone = controller.text.isNotEmpty;
    return Column(
      children: [
        buildSectionHeader("Số di động"),
        buildGroupContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Số điện thoại để xác thực và nhận thông báo.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextFormField(
                    controller: controller,
                    enabled: !hasPhone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Chưa có Số di động",
                      filled: true,
                      fillColor: hasPhone ? Colors.grey.shade200 : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: hasPhone
                            ? BorderSide.none
                            : BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  if (hasPhone)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
