import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhom_3_damh_lttbdd/model/saved_models.dart';

/// Widget hiển thị danh sách các bài viết đã lưu (Saved Items)
/// gồm 3 phần chính:
/// - Khi đang tải dữ liệu
/// - Khi không có bài viết nào
/// - Khi có danh sách bài viết để hiển thị
class SavedItemsSection extends StatelessWidget {
  /// Future trả về dữ liệu lưu trữ (gồm danh sách item + tổng số)
  final Future<SavedItemsData> savedItemsFuture;

  /// Callback khi người dùng muốn xem tất cả
  final VoidCallback onViewAll;

  /// Callback khi người dùng nhấn vào 1 item cụ thể
  final Function(SavedItem) onItemTap;

  const SavedItemsSection({
    Key? key,
    required this.savedItemsFuture,
    required this.onViewAll,
    required this.onItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SavedItemsData>(
      future: savedItemsFuture,
      builder: (context, snapshot) {
        // ⏳ Hiển thị tiến trình tải dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        // ⚠️ Nếu xảy ra lỗi trong quá trình tải
        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}')),
          );
        }

        // ✅ Dữ liệu đã có
        final savedItemsData = snapshot.data!;
        final items = savedItemsData.items;
        final totalCount = savedItemsData.totalCount;

        // 📭 Không có bài viết nào
        if (totalCount == 0) {
          return _buildEmptyState();
        }

        // 🧾 Có dữ liệu, hiển thị danh sách
        return _buildItemsList(items, totalCount);
      },
    );
  }

  /// Giao diện hiển thị khi chưa lưu bài viết nào
  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xem tất cả các bài viết đã lưu',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              'Bạn chưa lưu bài viết nào.',
              style: GoogleFonts.montserrat(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  /// Giao diện hiển thị danh sách các bài viết đã lưu
  Widget _buildItemsList(List<SavedItem> items, int totalCount) {
    // Nếu có nhiều hơn 6 bài viết, hiển thị nút “Xem tất cả”
    final bool hasMore = totalCount > 6;
    final int displayCount = items.length;
    final int itemCount = hasMore ? displayCount + 1 : displayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề + nút xem tất cả
        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Text(
                  'Xem tất cả các bài viết đã lưu',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),

        // Danh sách ngang các item
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final isViewAllButton = hasMore && index == displayCount;

              // Nếu là ô “Xem tất cả”
              if (isViewAllButton) {
                return _buildViewAllButton(totalCount);
              }

              // Còn lại là các bài viết
              final item = items[index];
              return _buildItemCard(item);
            },
          ),
        ),
      ],
    );
  }

  /// Nút "Xem tất cả" (xuất hiện khi có nhiều hơn 6 bài)
  Widget _buildViewAllButton(int totalCount) {
    return InkWell(
      onTap: onViewAll,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300, width: 1.0),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_forward_ios,
                size: 30,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                'Xem tất cả\n($totalCount mục)',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thẻ hiển thị từng bài viết đã lưu
  Widget _buildItemCard(SavedItem item) {
    return InkWell(
      onTap: () => onItemTap(item),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bài viết
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: Image.network(
                item.imageUrl,
                width: 180,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 180,
                  height: 160,
                  color: Colors.grey[300],
                  child: const Center(child: Text('Ảnh lỗi')),
                ),
              ),
            ),

            // Tiêu đề bài viết
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: SizedBox(
                width: 180,
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.arima(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
