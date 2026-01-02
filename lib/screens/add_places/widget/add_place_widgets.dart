// File: screens/add_places/widget/add_place_widgets.dart

import 'dart:io'; // Cần `File` để hiển thị `Image.file`
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Cần `XFile`
import 'package:nhom_3_damh_lttbdd/model/category_model.dart'; // Cần `CategoryModel`

// === WIDGET 1: KHU VỰC CHỌN DANH MỤC ===
// `StatelessWidget`: Vì nó không tự quản lý state.
// State của nó (danh sách category) được "sở hữu"
// bởi `_AddPlaceScreenState` (widget cha).
class CategoryChipsArea extends StatelessWidget {
  // `final`: Nhận dữ liệu và hàm từ cha
  final List<CategoryModel> selectedCategories;
  final int maxCategories;
  final VoidCallback onAdd; // Hàm cha `_showCategoryDialog`
  final Function(CategoryModel) onRemove; // Hàm cha `_removeCategory`

  const CategoryChipsArea({
    Key? key,
    required this.selectedCategories,
    required this.maxCategories,
    required this.onAdd,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(
        minHeight: 60,
      ), // Đảm bảo có chiều cao tối thiểu
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      // `Wrap`: Widget này tự động "ngắt" xuống dòng
      // nếu các `Chip` vượt quá chiều ngang.
      child: Wrap(
        spacing: 8.0, // Khoảng cách ngang
        runSpacing: 8.0, // Khoảng cách dọc (nếu ngắt dòng)
        children: [
          // `...` (Spread Operator):
          // 1. `selectedCategories.map(...)`: Biến `List<CategoryModel>`
          //    thành `List<_CategoryChip>`.
          // 2. `...`: "Trải" các `_CategoryChip` này ra
          //    như các con của `Wrap`.
          ...selectedCategories
              .map(
                (category) => _CategoryChip(
                  category: category,
                  // Truyền callback `onRemove` xuống cho
                  // chip con (`_CategoryChip`).
                  onRemove: () => onRemove(category),
                ),
              )
              .toList(),

          // **Logic hiển thị nút "Thêm":**
          // Chỉ hiển thị nút này nếu số lượng đã chọn
          // chưa đạt tối đa.
          if (selectedCategories.length < maxCategories)
            Semantics(
              label: 'btn_add_category', // ID dùng cho Appium
              child: ActionChip(
                avatar: const Icon(Icons.add, size: 18, color: Colors.blue),
                label: const Text('Thêm'),
                onPressed: onAdd,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.blue),
                labelStyle: const TextStyle(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// === WIDGET 1.1: CHIP DANH MỤC (Private) ===
// `_` (gạch dưới): Widget này là `private`,
// chỉ dùng nội bộ trong file này (bởi `CategoryChipsArea`).
class _CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onRemove; // Nhận callback `onRemove`

  const _CategoryChip({
    Key? key,
    required this.category,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // (Code UI cho cái Chip màu cam)
      padding: const EdgeInsets.only(left: 6, right: 10, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onRemove, // Khi bấm nút "X"... gọi `onRemove`
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Icon(Icons.close, size: 14, color: Colors.orange.shade800),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            category.name, // Hiển thị tên
            style: TextStyle(
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// === WIDGET 2: KHU VỰC CHỌN ẢNH ===
// Cấu trúc y hệt `CategoryChipsArea`.
class ImageSelectionArea extends StatelessWidget {
  final List<XFile> selectedImages;
  final int maxImages;
  final VoidCallback onAdd;
  final Function(XFile) onRemove;

  const ImageSelectionArea({
    Key? key,
    required this.selectedImages,
    required this.maxImages,
    required this.onAdd,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      // Số lượng item = số ảnh đã chọn + 1 nút thêm (nếu chưa full)
      itemCount:
          selectedImages.length + (selectedImages.length < maxImages ? 1 : 0),
      itemBuilder: (context, index) {
        // Nếu index bằng độ dài list ảnh -> Đây là vị trí nút thêm
        if (index == selectedImages.length) {
          return Semantics(
            label: 'btn_add_image', // ID dùng cho Appium
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(12),
              // Thay DottedBorder bằng Container có viền nét đứt giả lập (hoặc nét liền)
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ), // Viền thường
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt, color: Colors.grey, size: 32),
                    SizedBox(height: 4),
                    Text('Đăng ảnh', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }

        // Hiển thị ảnh đã chọn
        final file = selectedImages[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(file.path), fit: BoxFit.cover),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(file),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// === WIDGET 2.1: THUMBNAIL ẢNH (Private) ===
class _ImageThumbnail extends StatelessWidget {
  final XFile imageFile;
  final VoidCallback onRemove;

  const _ImageThumbnail({
    Key? key,
    required this.imageFile,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // `Stack`: Dùng để chồng 2 widget lên nhau
    // (nút "X" chồng lên trên ảnh).
    return Stack(
      clipBehavior: Clip.none, // Cho phép nút "X" tràn ra ngoài
      children: [
        // Lớp 1: Ảnh
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          // `Image.file`: Widget để hiển thị ảnh từ
          // `File` trên thiết bị.
          child: Image.file(
            File(imageFile.path), // Chuyển `XFile` -> `File`
            width: 80,
            height: 80,
            fit: BoxFit.cover, // Cắt ảnh để lấp đầy 80x80
            // `errorBuilder`: Hiển thị nếu file ảnh bị lỗi
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.error_outline, color: Colors.red, size: 30),
              ),
            ),
          ),
        ),
        // Lớp 2: Nút "X"
        Positioned(
          right: -4, // Đặt ở góc
          top: -4,
          child: InkWell(
            onTap: onRemove, // Gọi callback `onRemove`
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
