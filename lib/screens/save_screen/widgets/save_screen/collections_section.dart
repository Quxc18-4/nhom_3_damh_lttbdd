import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhom_3_damh_lttbdd/model/saved_models.dart';

/// Widget hiển thị danh sách các bộ sưu tập (Albums)
/// Gồm: nút "Tạo mới", danh sách album (tối đa 5 cái), và nút "Xem tất cả"
class CollectionsSection extends StatelessWidget {
  /// Dữ liệu danh sách album (lấy từ Firebase)
  final Future<List<Album>> albumsFuture;

  /// Sự kiện khi người dùng bấm "Tạo bộ sưu tập mới"
  final VoidCallback onCreateNew;

  /// Sự kiện khi người dùng bấm "Xem tất cả"
  final VoidCallback onViewAll;

  /// Sự kiện khi người dùng chọn một album cụ thể
  final Function(String albumId, String albumTitle) onAlbumTap;

  const CollectionsSection({
    Key? key,
    required this.albumsFuture,
    required this.onCreateNew,
    required this.onViewAll,
    required this.onAlbumTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dùng FutureBuilder để lắng nghe dữ liệu album từ Firebase
    return FutureBuilder<List<Album>>(
      future: albumsFuture,
      builder: (context, snapshot) {
        // Khi đang tải dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Khi có lỗi khi tải dữ liệu
        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('Lỗi tải bộ sưu tập: ${snapshot.error}')),
          );
        }

        // Khi tải xong dữ liệu
        final albums = snapshot.data ?? [];
        final int collectionCount = albums.length;
        final bool hasMore =
            collectionCount > 5; // Nếu có hơn 5 album thì hiển thị "Xem tất cả"
        final int itemCount = hasMore ? 6 : collectionCount + 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề
            Text(
              'Bộ sưu tập',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // GridView hiển thị danh sách album
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(), // Không cuộn riêng
              shrinkWrap: true, // Để Grid nằm trong Column
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cột
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1, // Tỷ lệ vuông
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // Ô đầu tiên là nút "Tạo bộ sưu tập mới"
                if (index == 0) {
                  return _buildCreateNewButton();
                }

                // Nếu có hơn 5 album, ô thứ 6 là nút "Xem tất cả"
                if (hasMore && index == 5) {
                  return _buildViewAllButton();
                }

                // Các ô còn lại là thẻ album
                final collectionIndex = index - 1;
                final collection = albums[collectionIndex];
                return _buildAlbumCard(collection);
              },
            ),
          ],
        );
      },
    );
  }

  /// Nút tạo bộ sưu tập mới
  Widget _buildCreateNewButton() {
    return InkWell(
      onTap: onCreateNew,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade400),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Colors.green.shade700,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo bộ sưu tập mới',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nút xem tất cả bộ sưu tập (khi có >5)
  Widget _buildViewAllButton() {
    return InkWell(
      onTap: onViewAll,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.collections_bookmark_outlined,
                color: Colors.orange.shade600,
                size: 35,
              ),
              const SizedBox(height: 8),
              Text(
                'Xem tất cả\nBộ sưu tập',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thẻ hiển thị từng album (ảnh + tên + số bài viết)
  Widget _buildAlbumCard(Album album) {
    return InkWell(
      onTap: () => onAlbumTap(album.id, album.title), // Khi bấm chọn album
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Ảnh nền của album
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
              child: Image.network(
                album.coverImageUrl,
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

          // Chữ đè lên ảnh (tên album + số review)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  album.title,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${album.reviewCount} Reviews',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
