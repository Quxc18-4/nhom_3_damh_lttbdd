import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/model/saved_models.dart';

/// Widget hiển thị danh sách các chip để lọc danh mục bài lưu.
/// Ví dụ: [Tất cả] [Bài viết] [Địa điểm]
class CategoryFilterChips extends StatelessWidget {
  /// Danh sách tất cả danh mục có thể chọn (enum SavedCategory)
  final List<SavedCategory> categories;

  /// Danh mục hiện đang được chọn
  final SavedCategory selectedCategory;

  /// Hàm callback khi người dùng chọn danh mục mới
  final Function(SavedCategory) onCategorySelected;

  const CategoryFilterChips({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal, // Cuộn ngang
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected =
                category == selectedCategory; // Kiểm tra đang chọn hay không

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                // Văn bản hiển thị trên chip (ví dụ: "Bài viết")
                label: Text(
                  categoryToVietnamese(category),
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),

                // Màu nền thay đổi theo trạng thái chọn
                backgroundColor: isSelected
                    ? Colors.orange.shade600
                    : Colors.grey.shade200,

                // Khi người dùng bấm vào chip
                onPressed: () => onCategorySelected(category),

                // Tạo viền bo tròn cho chip
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.orange.shade600
                        : Colors.grey.shade300,
                  ),
                ),

                // Khoảng cách bên trong chip
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
