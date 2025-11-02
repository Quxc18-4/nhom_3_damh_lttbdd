import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';

/// Service xử lý dữ liệu cho tab Giới thiệu
class IntroductionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lưu tiểu sử (bio) của user
  Future<void> saveBio(String userId, String newBio) async {
    await _firestore.collection('users').doc(userId).update({'bio': newBio});
  }

  /// Tính toán các chỉ số thành tích (dựa trên dữ liệu đã có)
  Map<String, int> calculateAchievements(
    Map<String, dynamic>? userData,
    List<Post> userPosts,
  ) {
    final List<dynamic> visited = userData?['visitedProvinces'] ?? [];
    final int posts = userPosts.length;

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
