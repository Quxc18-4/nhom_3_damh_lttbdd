import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhom_3_damh_lttbdd/screens/allColllectionsScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/addSaveItemScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/postDetailScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/albumDetailScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/addSaveItemScreen.dart'; // Import màn hình mới

// =========================================================================
// 1. MODELS DỮ LIỆU TỪ FIREBASE (ĐÃ TỐI ƯU HÓA)
//    NOTE: Các enum và class này được chia sẻ và sử dụng bởi AllSavedItemsScreen.
// =========================================================================

enum SavedCategory {
  all,
  review, // Bài viết
  place, // Địa điểm (Hotel/Activity/Công viên)
}

String categoryToVietnamese(SavedCategory category) {
  switch (category) {
    case SavedCategory.all:
      return 'Tất cả';
    case SavedCategory.place:
      return 'Địa điểm';
    case SavedCategory.review:
      return 'Bài viết';
  }
}

/// Dữ liệu trả về cho phần "Sản phẩm đã lưu" (Preview Dashboard)
class SavedItemsData {
  final int totalCount;
  final List<SavedItem> items;

  SavedItemsData({required this.totalCount, required this.items});
}

/// Model cho một mục đã lưu (Đã sửa để hỗ trợ Place và Review)
class SavedItem {
  final String id;
  final String contentId; // reviewId hoặc placeId
  final String title;
  final String subtitle;
  final SavedCategory category;
  final String imageUrl;
  final String authorOrRating; // Dành cho Review (Author) hoặc Place (Rating)
  final String location;

  // Dữ liệu thô từ bookmark (tùy chọn)
  final DocumentSnapshot bookmarkDoc;

  SavedItem({
    required this.id,
    required this.contentId,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.imageUrl,
    required this.authorOrRating,
    required this.location,
    required this.bookmarkDoc,
  });

  // Factory để tạo từ DocumentSnapshot của 'bookmarks' (chủ yếu được dùng trong logic fetch)
  factory SavedItem.fromBookmarkDoc(
    DocumentSnapshot bookmarkDoc, {
    required String contentId,
    required String title,
    required String subtitle,
    required SavedCategory category,
    required String imageUrl,
    required String authorOrRating,
    required String location,
  }) {
    // Không cần data map ở đây vì dữ liệu đã được fetch và xử lý từ bên ngoài
    return SavedItem(
      id: bookmarkDoc.id,
      contentId: contentId,
      title: title,
      subtitle: subtitle,
      category: category,
      imageUrl: imageUrl,
      authorOrRating: authorOrRating,
      location: location,
      bookmarkDoc: bookmarkDoc,
    );
  }
}

/// Model cho một Album (Lấy từ 'users/{userId}/albums')
class Album {
  final String id;
  final String title;
  final String? description;
  final String coverImageUrl; // Không null vì luôn có placeholder
  final int reviewCount;

  Album({
    required this.id,
    required this.title,
    this.description,
    required this.coverImageUrl,
    this.reviewCount = 0,
  });

  factory Album.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String? cover;
    if (data.containsKey('photos') &&
        data['photos'] is List &&
        (data['photos'] as List).isNotEmpty) {
      cover = (data['photos'] as List).first as String?;
    }

    return Album(
      id: doc.id,
      title: data['title'] ?? 'Không có tiêu đề',
      description: data['description'],
      coverImageUrl:
          cover ?? 'https://via.placeholder.com/180x180.png?text=No+Cover',
      reviewCount: data['reviewCount'] ?? 0, // Dùng reviewCount đã có hoặc 0
    );
  }

  Album copyWith({int? reviewCount, String? coverImageUrl}) {
    return Album(
      id: this.id,
      title: this.title,
      description: this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

// =========================================================================
// 2. SAVED SCREEN (UI CỦA MÀN HÌNH ĐÃ LƯU)
// =========================================================================

class SavedScreen extends StatefulWidget {
  final String userId;

  const SavedScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Khai báo Futures để lưu trữ dữ liệu
  late Future<SavedItemsData> _savedItemsFuture;
  late Future<List<Album>> _albumsFuture;

  // Cache Tên Category từ Firestore
  final Map<String, String> _categoryNameCache = {};
  // Cache data chi tiết của Review/Place để tránh fetch lặp lại
  final Map<String, dynamic> _contentCache = {};

  // 🆕 CACHE KẾT QUẢ CỦA _savedItemsFuture
  SavedItemsData? _savedItemsCache;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchCategories();
  }

  // Hàm helper để gọi/tải lại cả 2 future
  void _fetchData() {
    // 🆕 LƯU KẾT QUẢ VÀO CACHE SAU KHI FUTURE HOÀN TẤT
    _savedItemsFuture = _fetchSavedItems().then((data) {
      if (mounted) {
        setState(() {
          _savedItemsCache = data;
        });
      }
      return data;
    });
    _albumsFuture = _fetchAlbums();
  }

  Future<void> _fetchCategories() async {
    try {
      final categorySnap = await _firestore.collection('categories').get();
      if (mounted) {
        for (var doc in categorySnap.docs) {
          _categoryNameCache[doc.id] = doc['name'] ?? 'Không tên';
        }
        // Có thể cần tải lại data sau khi cache categories
        // setState(() {});
      }
    } catch (e) {
      debugPrint("Lỗi tải categories: $e");
    }
  }

  // --- HÀM TRUY VẤN DỮ LIỆU ---

  /// Lấy các mục đã lưu (KHÔNG thuộc album nào)
  Future<SavedItemsData> _fetchSavedItems() async {
    final bookmarksRef = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('bookmarks')
        .where('albumId', isEqualTo: null);

    final countSnap = await bookmarksRef.count().get();
    final totalCount = countSnap.count ?? 0;

    if (totalCount == 0) {
      return SavedItemsData(totalCount: 0, items: []);
    }

    final itemsSnap = await bookmarksRef
        .orderBy('addedAt', descending: true)
        .limit(6)
        .get();

    List<Future<SavedItem?>> itemFutures = itemsSnap.docs.map((
      bookmarkDoc,
    ) async {
      final bookmarkData = bookmarkDoc.data();
      final reviewId = bookmarkData['reviewID'] as String?;
      final placeId = bookmarkData['placeID'] as String?;

      String contentId = reviewId ?? placeId ?? '';
      SavedCategory category;

      if (reviewId != null) {
        category = SavedCategory.review;
      } else if (placeId != null) {
        category = SavedCategory.place;
      } else {
        return null;
      }

      if (!_contentCache.containsKey(contentId)) {
        final collection = reviewId != null ? 'reviews' : 'places';
        final docSnap = await _firestore
            .collection(collection)
            .doc(contentId)
            .get();
        if (docSnap.exists) {
          _contentCache[contentId] = docSnap.data()!;
        } else {
          return null;
        }
      }

      final contentData = _contentCache[contentId]!;

      // Xử lý thông tin hiển thị
      String title;
      String authorOrRating;
      String location;
      String imageUrl =
          bookmarkData['postImageUrl'] ??
          'https://via.placeholder.com/180x160.png?text=No+Image';

      if (category == SavedCategory.review) {
        title = contentData['title'] ?? 'Bài viết không tên';
        authorOrRating = 'Author ID: ${contentData['userId']}';
        location = contentData['placeName'] ?? 'Không rõ địa điểm';
      } else {
        // Category.place
        title = contentData['name'] ?? 'Địa điểm không tên';

        final placeCategoryIds =
            (contentData['categories'] as List<dynamic>?)
                ?.map((c) => c['id'])
                .toList() ??
            [];
        final primaryCategory = placeCategoryIds.isNotEmpty
            ? (_categoryNameCache[placeCategoryIds.first] ?? 'Địa điểm')
            : 'Địa điểm';
        authorOrRating = contentData['ratingAverage'] != null
            ? '${contentData['ratingAverage'].toStringAsFixed(1)}/5 sao'
            : primaryCategory;

        final locationData = contentData['location'] as Map<String, dynamic>?;
        location =
            locationData?['fullAddress'] ??
            contentData['locationName'] ??
            'Không rõ địa điểm';

        if (!bookmarkData.containsKey('postImageUrl') ||
            bookmarkData['postImageUrl'] == null) {
          final placeImages = (contentData['images'] as List<dynamic>?) ?? [];
          if (placeImages.isNotEmpty && placeImages.first is Map) {
            imageUrl = placeImages.first['url'] ?? imageUrl;
          } else if (placeImages.isNotEmpty && placeImages.first is String) {
            imageUrl = placeImages.first;
          }
        }
      }

      return SavedItem.fromBookmarkDoc(
        bookmarkDoc,
        contentId: contentId,
        title: title,
        subtitle: authorOrRating,
        category: category,
        imageUrl: imageUrl,
        authorOrRating: authorOrRating,
        location: location,
      );
    }).toList();

    final List<SavedItem> rawItems = (await Future.wait(
      itemFutures,
    )).whereType<SavedItem>().toList();

    return SavedItemsData(totalCount: totalCount, items: rawItems);
  }

  /// Lấy danh sách Albums, đếm số lượng item và LẤY ẢNH BÌA
  Future<List<Album>> _fetchAlbums() async {
    final albumSnap = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('albums')
        .orderBy('createdAt', descending: true)
        .get();

    if (albumSnap.docs.isEmpty) return [];

    // SỬA LẠI LOGIC LẤY ẢNH
    List<Future<Album>> albumFutures = albumSnap.docs.map((doc) async {
      final album = Album.fromDoc(doc);

      final bookmarksRef = _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('bookmarks')
          .where('albumId', isEqualTo: album.id);

      final countSnap = await bookmarksRef.count().get();
      final int count = countSnap.count ?? 0;

      String? finalCoverImageUrl = album.coverImageUrl;

      if (count > 0 && finalCoverImageUrl.contains('No+Cover')) {
        final firstBookmarkSnap = await bookmarksRef
            .orderBy('addedAt', descending: true) // Lấy review mới nhất
            .limit(1)
            .get();

        if (firstBookmarkSnap.docs.isNotEmpty) {
          final bookmarkData = firstBookmarkSnap.docs.first.data();
          // Kiểm tra xem bookmark có lưu 'postImageUrl' không
          if (bookmarkData.containsKey('postImageUrl') &&
              bookmarkData['postImageUrl'] != null) {
            finalCoverImageUrl = bookmarkData['postImageUrl'] as String;
          }
        }
      }

      // 4. Nếu vẫn không có ảnh (kể cả từ review), dùng placeholder
      finalCoverImageUrl ??=
          'https://via.placeholder.com/180x180.png?text=No+Cover';

      // 5. Trả về Album đã cập nhật
      return album.copyWith(
        reviewCount: count,
        coverImageUrl: finalCoverImageUrl,
      );
    }).toList();

    final List<Album> albumsWithCounts = await Future.wait(albumFutures);
    return albumsWithCounts;
  }

  // --- HÀM XỬ LÝ CHUYỂN HƯỚNG ---
  void _navigateToAllSavedItems() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllSavedItemsScreen(userId: widget.userId),
      ),
    );
  }

  void _navigateToItemDetail(SavedItem item) {
    // Điều hướng đến chi tiết Review hoặc Place
    if (item.category == SavedCategory.review) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(reviewId: item.contentId),
        ),
      ).then((_) => _fetchData());
    } else if (item.category == SavedCategory.place) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chuyển đến chi tiết Địa điểm (PlaceDetailScreen)'),
        ),
      );
      // TODO: Thêm logic điều hướng thực tế đến PlaceDetailScreen
    }
  }

  void _navigateToCollectionDetail(String albumId, String albumTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumDetailScreen(
          userId: widget.userId,
          albumId: albumId,
          albumTitle: albumTitle,
        ),
      ),
    ).then((_) => _fetchData());
  }

  void _navigateToAllCollections() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllCollectionsScreen()),
    );
  }

  // --- HÀM TẠO BỘ SƯU TẬP MỚI ---
  void _createNewCollection() async {
    final TextEditingController _albumNameController = TextEditingController();

    final String? newAlbumName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Tạo bộ sưu tập mới"),
          content: TextField(
            controller: _albumNameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Nhập tên..."),
          ),
          actions: [
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text("Tạo"),
              onPressed: () {
                if (_albumNameController.text.trim().isNotEmpty) {
                  Navigator.of(
                    dialogContext,
                  ).pop(_albumNameController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    if (newAlbumName != null && newAlbumName.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('albums')
            .add({
              'title': newAlbumName,
              'description': '',
              'createdAt': FieldValue.serverTimestamp(),
              'photos': [],
            });

        // Tải lại FutureBuilder của Album
        setState(() {
          _albumsFuture = _fetchAlbums();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Tạo bộ sưu tập thất bại: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Đã lưu',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildSavedItemsSection(),
            const SizedBox(height: 32),
            _buildCollectionsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
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

  /// Widget cho "Sản phẩm đã lưu"
  Widget _buildSavedItemsSection() {
    return FutureBuilder<SavedItemsData>(
      future: _savedItemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}')),
          );
        }

        final savedItemsData = snapshot.data!;
        final items = savedItemsData.items;
        final totalCount = savedItemsData.totalCount;
        final bool hasMore = totalCount > 6;
        final int displayCount = items.length;
        final int itemCount = hasMore ? displayCount + 1 : displayCount;

        if (totalCount == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xem tất cả các sản phẩm đã lưu',
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
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _navigateToAllSavedItems,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Xem tất cả các sản phẩm đã lưu',
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
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final isViewAllButton = hasMore && index == displayCount;

                  if (isViewAllButton) {
                    return InkWell(
                      onTap: _navigateToAllSavedItems,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.0,
                          ),
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

                  final item = items[index];
                  return InkWell(
                    onTap: () {
                      // 🆕 CHUYỂN ĐẾN MÀN HÌNH CHI TIẾT DỰA TRÊN CATEGORY/CONTENTID
                      _navigateToItemDetail(item);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.0,
                        ),
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
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: SizedBox(
                              width: 180,
                              child: Text(
                                item.title, // 🆕 SỬ DỤNG item.title
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
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Widget cho "Bộ sưu tập"
  Widget _buildCollectionsSection() {
    return FutureBuilder<List<Album>>(
      future: _albumsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('Lỗi tải bộ sưu tập: ${snapshot.error}')),
          );
        }

        final albums = snapshot.data ?? [];
        final int collectionCount = albums.length;
        final bool hasMore = collectionCount > 5;
        final int itemCount = hasMore ? 6 : collectionCount + 1; // +1 "Tạo mới"

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bộ sưu tập',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // ITEM 1: Nút Tạo bộ sưu tập mới
                if (index == 0) {
                  return InkWell(
                    onTap: _createNewCollection, // <-- HÀM ĐÃ CÓ LOGIC
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

                // Nút XEM TẤT CẢ
                if (hasMore && index == 5) {
                  return InkWell(
                    onTap: _navigateToAllCollections,
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

                // CÁC BỘ SƯU TẬP (ALBUMS)
                final collectionIndex = index - 1;
                final collection = albums[collectionIndex];

                return InkWell(
                  onTap: () => _navigateToCollectionDetail(
                    collection.id,
                    collection.title,
                  ),
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
                            collection
                                .coverImageUrl, // <-- Đã có placeholder từ _fetchAlbums
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
                              collection.title,
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${collection.reviewCount} Reviews',
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
              },
            ),
          ],
        );
      },
    );
  }
}
