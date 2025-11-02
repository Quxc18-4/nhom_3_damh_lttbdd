// File: screens/user_setting/account_setting/widget/account_setting_widgets.dart

import 'dart:io'; // Dùng cho File (ảnh)
import 'package:flutter/material.dart'; // Thư viện chính của Flutter
import 'package:intl/intl.dart'; // Định dạng ngày tháng

/// Container chung cho các nhóm
Widget buildGroupContainer({required Widget child}) { // Widget khung nhóm (có viền, bo góc)
  return Container( // Khung bao bọc
    padding: const EdgeInsets.all(16), // Padding toàn bộ 16dp
    decoration: BoxDecoration( // Trang trí khung
      color: Colors.white, // Nền trắng
      borderRadius: BorderRadius.circular(12), // Bo góc 12dp
      border: Border.all(color: Colors.grey.shade300), // Viền xám nhạt
    ),
    child: child, // Nội dung bên trong
  );
}

/// Tiêu đề của một phần (ví dụ: "Dữ liệu cá nhân")
Widget buildSectionHeader(String title) { // Tiêu đề phần
  return Padding( // Padding dưới
    padding: const EdgeInsets.only(bottom: 8.0), // Cách dưới 8dp
    child: Row( // Dòng chứa tiêu đề
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn 2 đầu
      children: [
        Text( // Văn bản tiêu đề
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Cỡ 18, in đậm
        ),
      ],
    ),
  );
}

/// Ô nhập liệu có nhãn
Widget buildLabeledTextField( // Ô nhập liệu với nhãn
  String label, // Nhãn (ví dụ: "Họ và tên")
  TextEditingController controller, // Controller quản lý text
  { // Tham số tùy chọn
  String hint = "", // Gợi ý trong ô
}) {
  return Column( // Cột dọc: nhãn + ô nhập
    crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
    children: [
      if (label.isNotEmpty) // Nếu có nhãn
        Text(label, style: const TextStyle(color: Colors.grey)), // Hiển thị nhãn màu xám
      if (label.isNotEmpty) const SizedBox(height: 4), // Khoảng cách nếu có nhãn
      TextFormField( // Ô nhập liệu
        controller: controller, // Gắn controller
        decoration: InputDecoration( // Trang trí ô
          hintText: hint, // Gợi ý
          filled: true, // Có nền
          fillColor: Colors.white, // Nền trắng
          contentPadding: const EdgeInsets.symmetric( // Padding nội dung
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder( // Viền
            borderRadius: BorderRadius.circular(8), // Bo góc
            borderSide: BorderSide(color: Colors.grey.shade300), // Màu viền
          ),
        ),
      ),
    ],
  );
}

/// Widget chọn ngày sinh
class DatePickerWidget extends StatelessWidget { // Widget chọn ngày sinh
  final DateTime? selectedDate; // Ngày đã chọn
  final VoidCallback onTap; // Hàm gọi khi nhấn

  const DatePickerWidget({Key? key, this.selectedDate, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Column( // Cột dọc: nhãn + ô chọn
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ngày sinh", style: TextStyle(color: Colors.grey)), // Nhãn
        const SizedBox(height: 4), // Khoảng cách
        InkWell( // Vùng nhấn
          onTap: onTap, // Gọi hàm khi nhấn
          child: Container( // Khung hiển thị ngày
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // Padding
            decoration: BoxDecoration( // Trang trí
              color: Colors.white, // Nền trắng
              borderRadius: BorderRadius.circular(8), // Bo góc
              border: Border.all(color: Colors.grey.shade400), // Viền
            ),
            child: Row( // Dòng: ngày + icon
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn 2 đầu
              children: [
                Text( // Hiển thị ngày
                  selectedDate == null // Nếu chưa chọn
                      ? "Chưa đặt"
                      : DateFormat('dd/MM/yyyy').format(selectedDate!), // Định dạng dd/MM/yyyy
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey), // Icon lịch
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget chọn giới tính
class GenderPickerWidget extends StatelessWidget { // Widget chọn giới tính
  final String? selectedGender; // Giới tính đã chọn
  final ValueChanged<String?> onChanged; // Hàm gọi khi thay đổi

  const GenderPickerWidget({
    Key? key,
    this.selectedGender,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Column( // Cột dọc: nhãn + dropdown
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Giới tính", style: TextStyle(color: Colors.grey)), // Nhãn
        const SizedBox(height: 4), // Khoảng cách
        DropdownButtonFormField<String>( // Dropdown trong form
          value: selectedGender, // Giá trị hiện tại
          hint: const Text("Chưa đặt"), // Gợi ý nếu chưa chọn
          decoration: InputDecoration( // Trang trí
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
          items: ["Nam", "Nữ", "Khác"] // Danh sách lựa chọn
              .map(
                (label) => DropdownMenuItem(value: label, child: Text(label)), // Tạo item
              )
              .toList(),
          onChanged: onChanged, // Gọi khi chọn
        ),
      ],
    );
  }
}

/// Widget hiển thị Email (chỉ đọc)
class EmailSection extends StatelessWidget { // Phần hiển thị email
  final TextEditingController controller; // Controller chứa email
  const EmailSection({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Column( // Cột dọc
      children: [
        buildSectionHeader("Email"), // Tiêu đề phần
        buildGroupContainer( // Khung nhóm
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text( // Mô tả
                "Email được sử dụng để đăng nhập và nhận thông báo.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8), // Khoảng cách
              TextFormField( // Ô hiển thị email
                controller: controller, // Gắn controller
                enabled: false, // Không cho chỉnh sửa
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade200, // Nền xám nhạt
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none, // Không viền
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
class PhoneSection extends StatelessWidget { // Phần số điện thoại
  final TextEditingController controller; // Controller chứa số
  final VoidCallback onDelete; // Hàm gọi khi xóa
  const PhoneSection({
    Key? key,
    required this.controller,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    bool hasPhone = controller.text.isNotEmpty; // Kiểm tra có số chưa
    return Column( // Cột dọc
      children: [
        buildSectionHeader("Số di động"), // Tiêu đề
        buildGroupContainer( // Khung nhóm
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text( // Mô tả
                "Số điện thoại để xác thực và nhận thông báo.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8), // Khoảng cách
              Stack( // Chồng lớp: ô nhập + nút xóa
                alignment: Alignment.centerRight, // Căn nút xóa bên phải
                children: [
                  TextFormField( // Ô hiển thị số
                    controller: controller,
                    enabled: !hasPhone, // Chỉ cho nhập nếu chưa có
                    keyboardType: TextInputType.phone, // Bàn phím số
                    decoration: InputDecoration(
                      hintText: "Chưa có Số di động", // Gợi ý
                      filled: true,
                      fillColor: hasPhone ? Colors.grey.shade200 : Colors.white, // Nền xám nếu có
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: hasPhone // Không viền nếu đã có số
                            ? BorderSide.none
                            : BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  if (hasPhone) // Nếu có số thì hiện nút xóa
                    IconButton(
                      onPressed: onDelete, // Gọi hàm xóa
                      icon: const Icon(Icons.delete_outline, color: Colors.red), // Icon thùng rác đỏ
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