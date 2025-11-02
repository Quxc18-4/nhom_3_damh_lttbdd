import 'package:cloud_firestore/cloud_firestore.dart';

/// Service xử lý dữ liệu album của user
class AlbumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy danh sách ảnh và số lượng albums của user
  ///
  /// Trả về Map với:
  /// - 'photos': List<String> chứa URL của tất cả ảnh trong các review của user
  /// - 'albumCount': số lượng album của user
  Future<Map<String, dynamic>> fetchUserAlbums(String userId) async {
    try {
      // 1️⃣ Lấy tất cả review của user, sắp xếp theo thời gian tạo mới nhất
      final reviewSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final photos = <String>[]; // Danh sách ảnh sẽ lưu URL

      // 2️⃣ Duyệt từng review, lấy các ảnh từ trường 'imageUrls'
      for (var doc in reviewSnapshot.docs) {
        final data = doc.data();
        final imageUrls = data['imageUrls'] ?? [];

        // Chỉ thêm URL hợp lệ (String không rỗng)
        for (var url in imageUrls) {
          if (url is String && url.isNotEmpty) {
            photos.add(url);
          }
        }
      }

      // 3️⃣ Lấy số lượng albums từ collection con 'albums' trong document user
      final albumSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('albums')
          .get();

      // 4️⃣ Trả về dữ liệu
      return {'photos': photos, 'albumCount': albumSnapshot.docs.length};
    } catch (e) {
      print('Lỗi khi tải album: $e');
      rethrow; // Ném lỗi ra ngoài để UI có thể handle
    }
  }
}
