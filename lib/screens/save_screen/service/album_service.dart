import 'package:cloud_firestore/cloud_firestore.dart';
import '/model/album_models.dart';

/// Dịch vụ (service) xử lý dữ liệu album và review
/// Giao tiếp trực tiếp với Firestore
class AlbumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Lấy thông tin album cụ thể từ Firestore
  ///   - `userId`: ID người dùng (thường là UID Firebase)
  ///   - `albumId`: ID của album trong collection `users/{userId}/albums`
  Future<AlbumData> fetchAlbumData(String userId, String albumId) async {
    final albumDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .get();

    // Nếu document tồn tại, parse dữ liệu thành AlbumData model
    if (albumDoc.exists) {
      return AlbumData.fromFirestore(albumDoc.data() as Map<String, dynamic>);
    }

    // Nếu không có album, trả về mặc định trống (tránh crash null)
    return AlbumData(description: '');
  }

  /// 🔹 Lấy danh sách bài viết (reviews) đã lưu trong một album
  ///   - Truy xuất qua bảng `bookmarks`
  ///   - Dùng `albumId` để lọc các bài viết thuộc album đó
  ///   - Sau đó fetch dữ liệu bài viết thực tế từ collection `reviews`
  Future<List<SavedReviewItem>> fetchAlbumReviews(
    String userId,
    String albumId,
  ) async {
    // 1️⃣ Lấy danh sách bookmark có albumId tương ứng
    final bookmarksSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .where('albumId', isEqualTo: albumId)
        .orderBy('addedAt', descending: true)
        .get();

    if (bookmarksSnap.docs.isEmpty) {
      return [];
    }

    // 2️⃣ Lấy danh sách ID bài viết
    final reviewIds = bookmarksSnap.docs
        .map((doc) => doc['reviewID'] as String)
        .toList();

    // ⚠️ Lưu ý Firestore chỉ cho phép `whereIn` tối đa 10 phần tử/lần.
    // Nếu nhiều hơn, nên chia nhỏ thành nhiều truy vấn (phòng tránh lỗi).
    // Ở đây giả định < 10.
    final reviewsSnap = await _firestore
        .collection('reviews')
        .where(FieldPath.documentId, whereIn: reviewIds)
        .get();

    // 3️⃣ Tạo map để ánh xạ id → dữ liệu review
    final reviewMap = {
      for (var doc in reviewsSnap.docs)
        doc.id: SavedReviewItem.fromReviewDoc(doc),
    };

    // 4️⃣ Giữ đúng thứ tự (theo reviewIds)
    final List<SavedReviewItem> orderedReviews = [];
    for (var reviewId in reviewIds) {
      if (reviewMap.containsKey(reviewId)) {
        orderedReviews.add(reviewMap[reviewId]!);
      }
    }

    return orderedReviews;
  }

  /// 🔹 Cập nhật ảnh bìa (cover) của album trong Firestore
  Future<void> updateAlbumCover(
    String userId,
    String albumId,
    String imageUrl,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .update({'coverImageUrl': imageUrl});
  }

  /// 🔹 Cập nhật thông tin cơ bản của album (title + description)
  Future<void> updateAlbumInfo(
    String userId,
    String albumId, {
    required String title,
    required String description,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .update({
          'title': title,
          'description': description,
          'updatedAt':
              FieldValue.serverTimestamp(), // ghi lại thời gian cập nhật
        });
  }

  /// 🔹 Xóa album khỏi Firestore
  /// - Các bài viết trong album sẽ được “gỡ liên kết” (albumId = null)
  /// - Sau đó xóa album document
  Future<void> deleteAlbum(String userId, String albumId) async {
    // 1️⃣ Lấy tất cả bookmarks thuộc album đó
    final bookmarksSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .where('albumId', isEqualTo: albumId)
        .get();

    final batch = _firestore.batch();

    // 2️⃣ Gỡ albumId của từng bookmark
    for (var doc in bookmarksSnap.docs) {
      batch.update(doc.reference, {'albumId': null});
    }

    // 3️⃣ Xóa document album chính
    batch.delete(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('albums')
          .doc(albumId),
    );

    // 4️⃣ Commit toàn bộ thay đổi một lượt
    await batch.commit();
  }
}
