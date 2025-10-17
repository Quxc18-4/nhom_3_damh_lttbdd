import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Giữ lại import này cho mục đích tham chiếu
import 'package:google_fonts/google_fonts.dart';
// =========================================================================
// 1. MOCK DATA MODELS (Mô hình dữ liệu giả lập)
// =========================================================================

// Mô hình cho Địa điểm đã lưu (Dựa trên 'places' collection)
class Place {
  final String id;
  final String name;
  final String city;
  final String imageUrl;
  final double ratingAverage;

  Place({
    required this.id,
    required this.name,
    required this.city,
    required this.imageUrl,
    this.ratingAverage = 0.0,
  });
}

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

// Dữ liệu giả cho các địa điểm đã lưu
final List<Place> mockSavedPlaces = [
  Place(
    id: 'p1',
    name: 'Dalat Palace Heritage Hotel',
    city: 'Đà Lạt',
    imageUrl:
    'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/1-1512755474911.jpg',
    ratingAverage: 4.8,
  ),
  Place(
    id: 'p2',
    name: 'Đà Lạt và hồ Xuân Tầm và những chuyến đi lãng mạn',
    city: 'Đà Lạt',
    imageUrl:
    'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/13-1512755474971.jpg',
    ratingAverage: 4.5,
  ),
  Place(
    id: 'p3',
    name: 'Tham quan Đại Nội Huế và khu vực Hoàng Thành',
    city: 'Huế',
    imageUrl:
    'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/13-1512755474971.jpg',
    ratingAverage: 4.7,
  ),
  Place(
    id: 'p4',
    name: 'Phố cổ Hội An',
    city: 'Hội An',
    imageUrl:
    'https://statictuoitre.mediacdn.vn/thumb_w/730/2017/6-1512755474939.jpg',
    ratingAverage: 4.9,
  ),
];

// Dữ liệu giả cho các bộ sưu tập (nhóm theo city từ reviews)
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
];

// =========================================================================
// 2. SAVED SCREEN (UI CỦA MÀN HÌNH ĐÃ LƯU)
// =========================================================================

class SavedScreen extends StatefulWidget {
  final String userId; // Dùng để truy vấn dữ liệu đã lưu của người dùng

  const SavedScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  // Hàm xử lý chuyển hướng (Bạn sẽ điền screen cụ thể sau)
  void _navigateToAllSavedItems() {
    // Navigator.push(context, MaterialPageRoute(builder: (context) => const AllSavedItemsScreen()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Chuyển đến màn hình "Tất cả sản phẩm đã lưu"')),
    );
  }

  void _navigateToCollectionDetail(String city) {
    // Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionDetailScreen(city: city)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chuyển đến danh sách Review tại $city')),
    );
  }

  void _createNewCollection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở Modal tạo bộ sưu tập mới')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đã lưu',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- THANH TÌM KIẾM ---
            _buildSearchBar(),
            const SizedBox(height: 24),

            // --- XEM TẤT CẢ SẢN PHẨM ĐÃ LƯU (HORIZONTAL LIST) ---
            _buildSavedItemsSection(),
            const SizedBox(height: 32),

            // --- BỘ SƯU TẬP (COLLECTIONS) ---
            _buildCollectionsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      // Giả lập Bottom Navigation Bar (Nếu cần)
      // bottomNavigationBar: ...
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.grey, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm đã lưu...',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Icon(Icons.filter_list, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSavedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0), // Padding cho tiêu đề
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Xem tất cả các sản phẩm đã lưu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _navigateToAllSavedItems,
                icon: const Icon(Icons.arrow_forward, color: Colors.black),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200 , // Chiều cao cố định cho Horizontal ListView
          child: ListView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: mockSavedPlaces.length,
            itemBuilder: (context, index) {
              final item = mockSavedPlaces[index];

              return InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Xem chi tiết: ${item.name}')));
                },
                borderRadius: BorderRadius.circular(10), // Bo góc cho InkWell

                // ⚡️ SỬA CHỮA: BỌC CẢ ẢNH VÀ TÊN VÀO CONTAINER DUY NHẤT
                child: Container(
                  width: 180, // Chiều rộng cố định cho toàn bộ Item
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10), // Bo góc cho Container
                    border: Border.all(color: Colors.grey.shade300, width: 1.0), // Viền
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
                      // --- IMAGE (Phải bo góc riêng) ---
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          item.imageUrl,
                          width: 180,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 180,
                                height: 160,
                                color: Colors.grey[300],
                                child: const Center(child: Text('Ảnh lỗi')),
                              ),
                        ),
                      ),

                      // --- TEXT (ĐÃ CÓ PADDING VÀ XỬ LÝ TRÀN) ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: SizedBox(
                          width: 180, // Đảm bảo Text không tràn ra khỏi 180px
                          child: Text(
                            item.name,
                            textAlign:TextAlign.center ,
                            style: GoogleFonts.arima( // ⚡️ SỬ DỤNG GOOGLE FONTS
                              fontWeight: FontWeight.w600,
                              fontSize: 13.0,
                            ),
                            maxLines: 1, // Đã sửa lại thành 2 dòng
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bộ sưu tập',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // --- GRIDVIEW CHO BỘ SƯU TẬP (Theo thành phố) ---
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(), // Không cuộn GridView
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 cột
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1, // Tỷ lệ chiều rộng/chiều cao
          ),
          itemCount: mockReviewCollections.length + 1, // +1 cho nút Tạo mới
          itemBuilder: (context, index) {
            if (index == 0) {
              // Nút Tạo bộ sưu tập mới
              return InkWell(
                onTap: _createNewCollection,
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
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Các Bộ sưu tập Review theo thành phố
            final collection = mockReviewCollections[index - 1];
            return InkWell(
              onTap: () => _navigateToCollectionDetail(collection.city),
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                      child: Image.network(
                        collection.coverImageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${collection.reviewCount} Reviews',
                          style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // --- NÚT XEM TẤT CẢ BỘ SƯU TẬP ---
        Center(
          child: TextButton(
            onPressed: () {
              // Navigator.push(context, MaterialPageRoute(builder: (context) => const AllCollectionsScreen()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Chuyển đến màn hình "Tất cả bộ sưu tập"')),
              );
            },
            child: Text(
              'Xem tất cả',
              style: TextStyle(
                color: Colors.orange.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
