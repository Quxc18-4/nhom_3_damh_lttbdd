import 'package:cloud_firestore/cloud_firestore.dart';

class AlbumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy danh sách ảnh và số lượng albums của user
  Future<Map<String, dynamic>> fetchUserAlbums(String userId) async {
    try {
      // Lấy tất cả bài viết của user
      final reviewSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final photos = <String>[];

      for (var doc in reviewSnapshot.docs) {
        final data = doc.data();
        final imageUrls = data['imageUrls'] ?? [];
        for (var url in imageUrls) {
          if (url is String && url.isNotEmpty) photos.add(url);
        }
      }

      // Lấy số lượng albums
      final albumSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('albums')
          .get();

      return {'photos': photos, 'albumCount': albumSnapshot.docs.length};
    } catch (e) {
      print('Lỗi khi tải album: $e');
      rethrow;
    }
  }
}
