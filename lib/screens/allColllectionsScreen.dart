import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- TẠM THỜI IMPORT MOCK DATA TỪ saved_screen.dart ---
// Trong dự án thực tế, bạn nên tách các Model và Mock Data ra file riêng (ví dụ: lib/models/data.dart)
// =========================================================================

// Mô hình cho Bộ sưu tập Review theo Thành phố (Dựa trên 'reviews' collection)
class ReviewCollection {
  final String city;
  final String coverImageUrl;
  final int reviewCount;

  ReviewCollection({
    required this.city,
    required this.coverImageUrl,
    required this.reviewCount,
  });
}

// Dữ liệu giả cho các bộ sưu tập
final List<ReviewCollection> mockReviewCollections = [
  ReviewCollection(
    city: 'Đà Lạt',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-1.jpg',
    reviewCount: 45,
  ),
  ReviewCollection(
    city: 'Hà Nội',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-12.jpg',
    reviewCount: 22,
  ),
  ReviewCollection(
    city: 'TP. Hồ Chí Minh',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-17.jpg',
    reviewCount: 15,
  ),
  ReviewCollection(
    city: 'Hải Phòng',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-25.jpg',
    reviewCount: 8,
  ),
  ReviewCollection(
    city: 'Nha Trang',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-25.jpg',
    reviewCount: 12,
  ),
  ReviewCollection(
    city: 'Phú Quốc',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-25.jpg',
    reviewCount: 18,
  ),
  ReviewCollection(
    city: 'Sapa',
    coverImageUrl:
    'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20phong%20c%E1%BA%A3nh%20%C4%91%E1%BA%B9p/anh-phong-canh-dep-25.jpg',
    reviewCount: 10,
  ),
];

// =========================================================================
// 3. ALL COLLECTIONS SCREEN
// =========================================================================

class AllCollectionsScreen extends StatelessWidget {
  const AllCollectionsScreen({Key? key}) : super(key: key);

  void _createNewCollection(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở Modal tạo bộ sưu tập mới')),
    );
  }

  void _navigateToCollectionDetail(BuildContext context, String city) {
    // Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionDetailScreen(city: city)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chuyển đến danh sách Review chi tiết tại $city')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy tổng số Collection + 1 cho nút Tạo mới
    final int itemCount = mockReviewCollections.length + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bộ sưu tập',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 cột
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.0, // Tỉ lệ 1:1 cho Collection
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {

            // ITEM 1: Nút Tạo bộ sưu tập mới (index == 0)
            if (index == 0) {
              return _buildCreateCollectionButton(context);
            }

            // Các Bộ sưu tập Review theo thành phố (index > 0)
            final collection = mockReviewCollections[index - 1];
            return _buildCollectionItem(context, collection);
          },
        ),
      ),
    );
  }

  // Widget riêng cho nút Tạo bộ sưu tập mới
  Widget _buildCreateCollectionButton(BuildContext context) {
    return InkWell(
      onTap: () => _createNewCollection(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade400!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: Colors.green.shade700, size: 40),
            const SizedBox(height: 8),
            Text(
              'Tạo bộ sưu tập mới',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget riêng cho mục Collection
  Widget _buildCollectionItem(BuildContext context, ReviewCollection collection) {
    return InkWell(
      onTap: () => _navigateToCollectionDetail(context, collection.city),
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.35), // Tăng độ tối nhẹ
                BlendMode.darken,
              ),
              child: Image.network(
                collection.coverImageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.blueGrey,
                  child: const Center(child: Text('Ảnh lỗi')),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  collection.city,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20, // Tăng size cho nổi bật
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${collection.reviewCount} Reviews',
                  style:
                  GoogleFonts.montserrat(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
