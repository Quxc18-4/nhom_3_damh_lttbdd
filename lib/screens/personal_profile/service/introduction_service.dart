import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';

/// Service xử lý dữ liệu cho tab Giới thiệu (Introduction)
class IntroductionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Lưu tiểu sử (bio) của user vào Firestore
  ///
  /// Cập nhật field 'bio' trong document của user
  Future<void> saveBio(String userId, String newBio) async {
    try {
      await _firestore.collection('users').doc(userId).update({'bio': newBio});
    } catch (e) {
      print('❌ Lỗi saveBio: $e');
      rethrow;
    }
  }

  /// 🔹 Tính toán các chỉ số thành tích dựa trên dữ liệu hiện có
  ///
  /// - `userData`: dữ liệu document user
  /// - `userPosts`: danh sách bài viết đã tải
  ///
  /// Trả về Map gồm:
  /// - 'destinationCount': số tỉnh/thành đã đến
  /// - 'postCount': số bài viết
  /// - 'totalLikes': tổng số lượt thích
  /// - 'totalComments': tổng số bình luận
  Map<String, int> calculateAchievements(
    Map<String, dynamic>? userData,
    List<Post> userPosts,
  ) {
    // Lấy danh sách các tỉnh/thành đã đến
    final List<dynamic> visited = userData?['visitedProvinces'] ?? [];

    // Đếm số bài viết
    final int posts = userPosts.length;

    // Tính tổng lượt thích và bình luận
    int likes = 0;
    int comments = 0;
    for (final post in userPosts) {
      likes += post.likeCount;
      comments += post.commentCount;
    }

    return {
      'destinationCount': visited.length,
      'postCount': posts,
      'totalLikes': likes,
      'totalComments': comments,
    };
  }
}
