import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/screens/comment/widget/comment_item.dart';
import 'package:nhom_3_damh_lttbdd/screens/post_detail/service/post_detail_service.dart';
import '/model/comment_model.dart';

/// Widget hiển thị danh sách comment cho một bài viết
/// Kết hợp Stream + Future để lấy comment + thông tin user
class CommentList extends StatelessWidget {
  /// ID bài viết
  final String reviewId;

  /// ID user hiện tại (để check like)
  final String currentUserId;

  /// Service xử lý data từ Firestore
  final PostDetailService service;

  /// Callback khi user nhấn like comment
  final Function(CommentModel) onCommentLike;

  /// Callback khi user nhấn reply comment
  final Function(CommentModel) onCommentReply;

  const CommentList({
    Key? key,
    required this.reviewId,
    required this.currentUserId,
    required this.service,
    required this.onCommentLike,
    required this.onCommentReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Lắng nghe realtime các bình luận
      stream: service.getCommentsStream(reviewId),
      builder: (context, snapshot) {
        // ==================================
        // Xử lý trạng thái lỗi
        // ==================================
        if (snapshot.hasError) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Text('Lỗi tải bình luận: ${snapshot.error}'),
          );
        }

        // ==================================
        // Loading state khi đang fetch dữ liệu
        // ==================================
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final commentDocs = snapshot.data?.docs ?? [];

        // ==================================
        // Empty state nếu chưa có bình luận nào
        // ==================================
        if (commentDocs.isEmpty) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(32),
            child: const Center(
              child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!'),
            ),
          );
        }

        // ==================================
        // Fetch thông tin user tương ứng với mỗi comment
        // ==================================
        return FutureBuilder<List<CommentModel>>(
          future: service.mapCommentsWithUsers(
            commentDocs,
            reviewId,
            currentUserId,
          ),
          builder: (context, userSnapshot) {
            // Loading khi đang fetch thông tin user
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            // Xử lý lỗi khi fetch user
            if (userSnapshot.hasError || !userSnapshot.hasData) {
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text('Lỗi hiển thị dữ liệu người dùng.'),
                ),
              );
            }

            final comments = userSnapshot.data!;

            // ==================================
            // Render danh sách comment
            // ==================================
            return Container(
              color: Colors.white,
              child: ListView.builder(
                shrinkWrap: true, // Để ListView trong Column/ListView khác
                physics:
                    const NeverScrollableScrollPhysics(), // Không scroll độc lập
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return CommentItem(
                    comment: comment,
                    onLike: () => onCommentLike(comment),
                    onReply: () => onCommentReply(comment),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
