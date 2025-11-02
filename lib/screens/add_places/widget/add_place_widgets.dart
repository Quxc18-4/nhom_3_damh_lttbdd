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
            InkWell(
              onTap: onAdd, // Khi bấm, gọi callback `onAdd` (của cha)
              borderRadius: BorderRadius.circular(20),
              child: Container(
                // (Đây là code UI tạo nút "Thêm" có dấu +)
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Ngắn vừa đủ
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Thêm',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
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
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          // 1. "Trải" các `_ImageThumbnail` ra
          ...selectedImages
              .map(
                (imageFile) => _ImageThumbnail(
                  imageFile: imageFile,
                  onRemove: () => onRemove(imageFile),
                ),
              )
              .toList(),
          // 2. Hiển thị nút "Thêm ảnh" nếu còn chỗ
          if (selectedImages.length < maxImages)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.grey.shade600,
                      size: 30,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thêm ảnh',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
