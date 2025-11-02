import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/model/saved_models.dart';

/// Dịch vụ xử lý các mục đã lưu (bookmarks) của người dùng.
/// - Giao tiếp với Firestore để tải dữ liệu.
/// - Lưu cache (danh mục, người viết, nội dung) để giảm số lần đọc Firestore.
class AllSavedItemsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache dữ liệu để tránh load lại nhiều lần.
  final Map<String, dynamic> _contentCache = {}; // Lưu nội dung bài/địa điểm
  final Map<String, String> _categoryNameCache =
      {}; // Lưu tên danh mục (category)
  final Map<String, String> _authorNameCache = {}; // Lưu tên tác giả (user)

  // Getter để truy cập cache từ bên ngoài (nếu cần)
  Map<String, String> get categoryNameCache => _categoryNameCache;
  Map<String, String> get authorNameCache => _authorNameCache;

  /// 🔹 Tải toàn bộ categories từ Firestore về cache
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

  /// 🔹 Lấy tên người viết dựa trên userId (có cache để giảm truy vấn)
  Future<String> fetchAuthorName(String userId) async {
    if (_authorNameCache.containsKey(userId)) {
      return _authorNameCache[userId]!; // Lấy từ cache
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final userName = data['name'] ?? data['fullName'] ?? 'Người dùng';
        _authorNameCache[userId] = userName; // Cache lại
        return userName;
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi fetch author name: $e");
    }
    return "Người dùng ẩn danh";
  }

  /// 🔹 Tải toàn bộ mục đã lưu (bookmarks) của user
  ///    → có thể là bài review hoặc địa điểm
  Future<List<SavedItem>> loadAllSavedItems(String userId) async {
    // Lấy bookmarks của user (trừ những cái nằm trong album)
    final bookmarksRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .where('albumId', isEqualTo: null)
        .orderBy('addedAt', descending: true);

    final itemsSnap = await bookmarksRef.get();

    // Map mỗi document thành SavedItem (dạng Future vì cần load thêm dữ liệu)
    List<Future<SavedItem?>> itemFutures = itemsSnap.docs.map((
      bookmarkDoc,
    ) async {
      final bookmarkData = bookmarkDoc.data();

      // Kiểm tra loại dữ liệu được lưu
      final reviewId = bookmarkData['reviewID'] as String?;
      final placeId = bookmarkData['placeID'] as String?;
      String contentId = reviewId ?? placeId ?? '';

      // Xác định loại (review hay place)
      SavedCategory category;
      if (reviewId != null) {
        category = SavedCategory.review;
      } else if (placeId != null) {
        category = SavedCategory.place;
      } else {
        return null; // Không xác định được loại
      }

      // ✅ Cache check: nếu chưa có nội dung thì load từ Firestore
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

      // Các biến dùng để hiển thị
      String title;
      String authorOrRating;
      String location;
      String imageUrl =
          bookmarkData['postImageUrl'] ??
          'https://via.placeholder.com/180x160.png?text=No+Image';

      // 🔸 Nếu là Review
      if (category == SavedCategory.review) {
        title = contentData['title'] ?? 'Bài viết không tên';
        final authorId = contentData['userId'] ?? '';
        authorOrRating = await fetchAuthorName(authorId);
        location = contentData['placeName'] ?? 'Không rõ địa điểm';
      }
      // 🔸 Nếu là Place
      else {
        title = contentData['name'] ?? 'Địa điểm không tên';

        // Lấy danh mục chính (nếu có)
        final placeCategoryIds =
            (contentData['categories'] as List<dynamic>?)
                ?.map((c) => c['id'])
                .toList() ??
            [];
        final primaryCategory = placeCategoryIds.isNotEmpty
            ? (_categoryNameCache[placeCategoryIds.first] ?? 'Địa điểm')
            : 'Địa điểm';

        // Nếu có rating → hiển thị rating, ngược lại hiển thị tên danh mục
        authorOrRating = contentData['ratingAverage'] != null
            ? '${contentData['ratingAverage'].toStringAsFixed(1)}/5 sao'
            : primaryCategory;

        // Lấy địa chỉ hiển thị
        final locationData = contentData['location'] as Map<String, dynamic>?;
        location =
            locationData?['fullAddress'] ??
            contentData['locationName'] ??
            'Không rõ địa điểm';

        // Nếu chưa có ảnh → thử lấy từ danh sách ảnh
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

      // Tạo đối tượng SavedItem
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

    // Chờ toàn bộ Future hoàn tất và loại bỏ null
    final List<SavedItem> rawItems = (await Future.wait(
      itemFutures,
    )).whereType<SavedItem>().toList();

    return rawItems;
  }

  /// 🔹 Lọc danh sách SavedItem theo danh mục người dùng chọn
  List<SavedItem> filterItemsByCategory(
    List<SavedItem> allItems,
    SavedCategory selectedCategory,
  ) {
    if (selectedCategory == SavedCategory.all) {
      return allItems;
    }
    return allItems.where((item) => item.category == selectedCategory).toList();
  }
}
