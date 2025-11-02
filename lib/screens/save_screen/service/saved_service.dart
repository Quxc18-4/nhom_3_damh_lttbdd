import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/model/saved_models.dart';

/// Lớp này xử lý việc tải, lưu và quản lý dữ liệu "Đã lưu" (Saved Items)
/// từ Firestore của từng người dùng.
///
/// Bao gồm:
/// - Lấy danh mục (categories)
/// - Lấy danh sách bài viết / địa điểm đã lưu
/// - Lấy danh sách album người dùng
/// - Tạo album mới
class SavedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache tên danh mục để giảm truy vấn Firestore lặp lại
  final Map<String, String> _categoryNameCache = {};

  /// Cache nội dung bài viết / địa điểm để tránh load lại nhiều lần
  final Map<String, dynamic> _contentCache = {};

  // ---------------------------------------------------------------------------
  // 🔹 1. Lấy toàn bộ danh mục (categories) và lưu cache
  Future<void> fetchCategories() async {
    try {
      final categorySnap = await _firestore.collection('categories').get();
      for (var doc in categorySnap.docs) {
        _categoryNameCache[doc.id] = doc['name'] ?? 'Không tên';
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi tải categories: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 2. Lấy các mục người dùng đã lưu (Saved Items)
  Future<SavedItemsData> fetchSavedItems(String userId) async {
    // Lấy toàn bộ bookmark trong `users/{userId}/bookmarks`
    // (chỉ lấy những cái không nằm trong album)
    final bookmarksRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .where('albumId', isEqualTo: null);

    // Lấy tổng số lượng đã lưu
    final countSnap = await bookmarksRef.count().get();
    final totalCount = countSnap.count ?? 0;

    // Nếu chưa có gì thì trả về danh sách rỗng
    if (totalCount == 0) {
      return SavedItemsData(totalCount: 0, items: []);
    }

    // Lấy tối đa 6 item gần đây nhất (hiển thị ở màn chính)
    final itemsSnap = await bookmarksRef
        .orderBy('addedAt', descending: true)
        .limit(6)
        .get();

    // Chuyển mỗi document bookmark thành 1 đối tượng SavedItem
    List<Future<SavedItem?>> itemFutures = itemsSnap.docs.map((
      bookmarkDoc,
    ) async {
      final bookmarkData = bookmarkDoc.data();

      final reviewId = bookmarkData['reviewID'] as String?;
      final placeId = bookmarkData['placeID'] as String?;
      String contentId = reviewId ?? placeId ?? '';

      // Xác định loại mục (review hoặc place)
      SavedCategory category;
      if (reviewId != null) {
        category = SavedCategory.review;
      } else if (placeId != null) {
        category = SavedCategory.place;
      } else {
        return null; // Không hợp lệ
      }

      // Nếu chưa có trong cache thì tải dữ liệu Firestore
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

      // Lấy dữ liệu nội dung từ cache
      final contentData = _contentCache[contentId]!;

      // Các trường để hiển thị
      String title;
      String authorOrRating;
      String location;
      String imageUrl =
          bookmarkData['postImageUrl'] ??
          'https://via.placeholder.com/180x160.png?text=No+Image';

      // Nếu là REVIEW
      if (category == SavedCategory.review) {
        title = contentData['title'] ?? 'Bài viết không tên';
        authorOrRating = 'Author ID: ${contentData['userId']}';
        location = contentData['placeName'] ?? 'Không rõ địa điểm';
      }
      // Nếu là PLACE
      else {
        title = contentData['name'] ?? 'Địa điểm không tên';

        // Lấy danh mục chính của địa điểm
        final placeCategoryIds =
            (contentData['categories'] as List<dynamic>?)
                ?.map((c) => c['id'])
                .toList() ??
            [];
        final primaryCategory = placeCategoryIds.isNotEmpty
            ? (_categoryNameCache[placeCategoryIds.first] ?? 'Địa điểm')
            : 'Địa điểm';

        // Nếu có rating → hiển thị rating, ngược lại hiển thị danh mục
        authorOrRating = contentData['ratingAverage'] != null
            ? '${contentData['ratingAverage'].toStringAsFixed(1)}/5 sao'
            : primaryCategory;

        // Lấy địa chỉ (nếu có)
        final locationData = contentData['location'] as Map<String, dynamic>?;
        location =
            locationData?['fullAddress'] ??
            contentData['locationName'] ??
            'Không rõ địa điểm';

        // Nếu chưa có ảnh trong bookmark → thử lấy từ `images` của place
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

      // Trả về 1 đối tượng SavedItem
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

    // Đợi tất cả Future hoàn thành và lọc bỏ null
    final List<SavedItem> rawItems = (await Future.wait(
      itemFutures,
    )).whereType<SavedItem>().toList();

    // Trả kết quả gồm tổng số và danh sách item
    return SavedItemsData(totalCount: totalCount, items: rawItems);
  }

  // ---------------------------------------------------------------------------
  // 🔹 3. Lấy danh sách Album của người dùng
  Future<List<Album>> fetchAlbums(String userId) async {
    // Lấy tất cả album người dùng
    final albumSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .orderBy('createdAt', descending: true)
        .get();

    if (albumSnap.docs.isEmpty) return [];

    // Xử lý từng album
    List<Future<Album>> albumFutures = albumSnap.docs.map((doc) async {
      final album = Album.fromDoc(doc);

      // Đếm số bookmark trong album đó
      final bookmarksRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .where('albumId', isEqualTo: album.id);

      final countSnap = await bookmarksRef.count().get();
      final int count = countSnap.count ?? 0;

      String? finalCoverImageUrl = album.coverImageUrl;

      // Nếu album chưa có ảnh cover → lấy ảnh từ bookmark đầu tiên
      if (count > 0 && finalCoverImageUrl.contains('No+Cover')) {
        final firstBookmarkSnap = await bookmarksRef
            .orderBy('addedAt', descending: true)
            .limit(1)
            .get();

        if (firstBookmarkSnap.docs.isNotEmpty) {
          final bookmarkData = firstBookmarkSnap.docs.first.data();
          if (bookmarkData.containsKey('postImageUrl') &&
              bookmarkData['postImageUrl'] != null) {
            finalCoverImageUrl = bookmarkData['postImageUrl'] as String;
          }
        }
      }

      // Nếu vẫn chưa có ảnh → ảnh mặc định
      finalCoverImageUrl ??=
          'https://via.placeholder.com/180x180.png?text=No+Cover';

      // Trả về album đã có số lượng và ảnh cover cập nhật
      return album.copyWith(
        reviewCount: count,
        coverImageUrl: finalCoverImageUrl,
      );
    }).toList();

    final List<Album> albumsWithCounts = await Future.wait(albumFutures);
    return albumsWithCounts;
  }

  // ---------------------------------------------------------------------------
  // 🔹 4. Tạo album mới cho người dùng
  Future<void> createAlbum(String userId, String albumName) async {
    await _firestore.collection('users').doc(userId).collection('albums').add({
      'title': albumName,
      'description': '',
      'createdAt': FieldValue.serverTimestamp(),
      'photos': [], // Có thể là mảng ảnh trong tương lai
    });
  }
}
