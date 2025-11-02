import 'package:flutter/material.dart';
import '/model/post_model.dart';
import 'post_card.dart';

/// Widget hiển thị danh sách bài viết dạng ListView
/// Nếu danh sách rỗng sẽ show message tùy tab Explore hay Following
class PostListView extends StatelessWidget {
  final List<Post> posts; // Danh sách bài viết
  final String userId; // Current user ID
  final VoidCallback onPostUpdated; // Callback khi bài viết thay đổi
  final NotificationCreator createNotification; // Callback tạo notification
  final bool isExploreTab; // Biến để xác định đang ở tab Explore hay Following

  const PostListView({
    Key? key,
    required this.posts,
    required this.userId,
    required this.onPostUpdated,
    required this.createNotification,
    required this.isExploreTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nếu không có bài viết nào
    if (posts.isEmpty) {
      final message = isExploreTab
          ? "Chưa có bài viết nào để khám phá. Hãy là người đầu tiên tạo một bài!"
          : "Bạn chưa có bài viết nào hoặc chưa theo dõi ai.";

      return Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Nếu có bài viết, hiển thị bằng ListView.builder
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: PostCard(
            post: post,
            userId: userId,
            onPostUpdated: onPostUpdated,
            createNotification: createNotification,
          ),
        );
      },
    );
  }
}
