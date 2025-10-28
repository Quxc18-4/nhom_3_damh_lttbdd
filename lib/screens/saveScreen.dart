// screens/saveScreen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhom_3_damh_lttbdd/screens/allColllectionsScreen.dart';
import 'addSaveItemScreen.dart'; // Đảm bảo bạn có file này

// =========================================================================
// 1. MODELS DỮ LIỆU TỪ FIREBASE
// =========================================================================

/// Dữ liệu trả về cho phần "Sản phẩm đã lưu"
class SavedItemsData {
  final int totalCount; // Tổng số item (kể cả khi không hiển thị hết)
  final List<SavedItem> items; // Danh sách item (giới hạn 6)

  SavedItemsData({required this.totalCount, required this.items});
}

/// Model cho một item đã lưu (Lấy từ collection 'reviews')
class SavedItem {
  final String reviewId;
  final String name;
  final String imageUrl;

  SavedItem({
    required this.reviewId,
    required this.name,
    required this.imageUrl,
  });

  // Factory để tạo từ một DocumentSnapshot của 'reviews'
  factory SavedItem.fromReviewDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedItem(
      reviewId: doc.id,
      name: data['comment'] ?? 'Bài viết đã lưu',
      imageUrl: (data['imageUrls'] != null &&
              (data['imageUrls'] as List).isNotEmpty)
          ? data['imageUrls'][0]
          : 'https://via.placeholder.com/180x160.png?text=No+Image',
    );
  }
}

/// Model cho một Album (Lấy từ 'users/{userId}/albums')
class Album {
  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  // final bool creator; // <-- ĐÃ XÓA
  final int reviewCount;

  Album({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
    // this.creator = false, // <-- ĐÃ XÓA
    this.reviewCount = 0,
  });

  // Factory để tạo từ một DocumentSnapshot của 'albums'
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
      coverImageUrl: cover, // <-- SỬA: Không dùng placeholder ở đây
      // creator: data['creator'] ?? false, // <-- ĐÃ XÓA
    );
  }

  // Hàm copyWith để cập nhật reviewCount và ảnh bìa sau
  Album copyWith({
    int? reviewCount,
    String? coverImageUrl, // <-- THÊM
  }) {
    return Album(
      id: this.id,
      title: this.title,
      description: this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl, // <-- CẬP NHẬT
      // creator: this.creator, // <-- ĐÃ XÓA
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
  // Khai báo Futures để lưu trữ dữ liệu
  late Future<SavedItemsData> _savedItemsFuture;
  late Future<List<Album>> _albumsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Hàm helper để gọi/tải lại cả 2 future
  void _fetchData() {
    _savedItemsFuture = _fetchSavedItems();
    _albumsFuture = _fetchAlbums();
  }

  // --- HÀM TRUY VẤN DỮ LIỆU ---

  /// Lấy các mục đã lưu (KHÔNG thuộc album nào)
  Future<SavedItemsData> _fetchSavedItems() async {
    final bookmarksRef = FirebaseFirestore.instance
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

    final reviewIds =
        itemsSnap.docs.map((doc) => doc['reviewID'] as String).toList();

    if (reviewIds.isEmpty) {
      return SavedItemsData(totalCount: totalCount, items: []);
    }

    final reviewSnap = await FirebaseFirestore.instance
        .collection('reviews')
        .where(FieldPath.documentId, whereIn: reviewIds)
        .get();

    final reviewMap = {
      for (var doc in reviewSnap.docs) doc.id: SavedItem.fromReviewDoc(doc)
    };

    final List<SavedItem> orderedItems = [];
    for (var id in reviewIds) {
      if (reviewMap.containsKey(id)) {
        orderedItems.add(reviewMap[id]!);
      }
    }
    return SavedItemsData(totalCount: totalCount, items: orderedItems);
  }

  /// Lấy danh sách Albums, đếm số lượng item và LẤY ẢNH BÌA
  Future<List<Album>> _fetchAlbums() async {
    final albumSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('albums')
        .orderBy('createdAt', descending: true)
        .get();

    if (albumSnap.docs.isEmpty) return [];

    // SỬA LẠI LOGIC LẤY ẢNH
    List<Future<Album>> albumFutures = albumSnap.docs.map((doc) async {
      // 1. Tạo Album. coverImageUrl có thể là null.
      final album = Album.fromDoc(doc);

      final bookmarksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('bookmarks')
          .where('albumId', isEqualTo: album.id);

      // 2. Đếm số lượng review
      final countSnap = await bookmarksRef.count().get();
      final int count = countSnap.count ?? 0;

      String? finalCoverImageUrl = album.coverImageUrl;

      // 3. Nếu album KHÔNG có ảnh bìa ('photos' rỗng) VÀ có review (count > 0)
      //    thì tìm ảnh từ review mới nhất.
      if (count > 0 && finalCoverImageUrl == null) {
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
        context, MaterialPageRoute(builder: (context) => const AllSavedItemsScreen()));
  }

  void _navigateToCollectionDetail(String albumId, String albumTitle) {
    // TODO: Chuyển sang trang chi tiết album
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chuyển đến danh sách Review của $albumTitle')),
    );
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
          title: Text("Tạo bộ sưu tập mới"),
          content: TextField(
            controller: _albumNameController,
            autofocus: true,
            decoration: InputDecoration(hintText: "Nhập tên..."),
          ),
          actions: [
            TextButton(
              child: Text("Hủy"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text("Tạo"),
              onPressed: () {
                if (_albumNameController.text.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(_albumNameController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    if (newAlbumName != null && newAlbumName.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('albums')
            .add({
          'title': newAlbumName,
          'description': '',
          'createdAt': FieldValue.serverTimestamp(),
          // 'creator': true, // <-- ĐÃ XÓA
          'photos': [],
        });

        // Tải lại FutureBuilder của Album
        setState(() {
          _albumsFuture = _fetchAlbums();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Tạo bộ sưu tập thất bại: $e"),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đã lưu',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
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
            child: Center(child: CircularProgressIndicator(color: Colors.orange)),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data!.totalCount == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xem tất cả các sản phẩm đã lưu',
                style: GoogleFonts.montserrat(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10)
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

        final savedItemsData = snapshot.data!;
        final items = savedItemsData.items;
        final totalCount = savedItemsData.totalCount;
        final bool hasMore = totalCount > 6;
        final int displayCount = items.length;
        final int itemCount = hasMore ? displayCount + 1 : displayCount;

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
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward,
                        size: 18, color: Colors.black54),
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
                          border:
                              Border.all(color: Colors.grey.shade300, width: 1.0),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_forward_ios,
                                  size: 30, color: Colors.orange.shade600),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Xem chi tiết: ${item.name}')));
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1.0),
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
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(10)),
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
                                horizontal: 8.0, vertical: 4.0),
                            child: SizedBox(
                              width: 180,
                              child: Text(
                                item.name,
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
                  fontSize: 20, fontWeight: FontWeight.bold),
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
                            Icon(Icons.collections_bookmark_outlined,
                                color: Colors.orange.shade600, size: 35),
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
                  onTap: () =>
                      _navigateToCollectionDetail(collection.id, collection.title),
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
                            collection.coverImageUrl!, // <-- Đã có placeholder từ _fetchAlbums
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
                                  color: Colors.white70, fontSize: 12),
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