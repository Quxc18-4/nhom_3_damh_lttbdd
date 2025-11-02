import 'package:flutter/material.dart';
import '/model/post_model.dart';
import 'post_card.dart';

class PostListView extends StatelessWidget {
  final List<Post> posts;
  final String userId;
  final VoidCallback onPostUpdated;
  final NotificationCreator createNotification;
  final bool isExploreTab;

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
    if (posts.isEmpty) {
      final message = isExploreTab
          ? "Chưa có bài viết nào để khám phá. Hãy là người đầu tiên tạo một bài!"
          : "Bạn chưa có bài viết nào hoặc chưa theo dõi ai.";

      return Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

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
