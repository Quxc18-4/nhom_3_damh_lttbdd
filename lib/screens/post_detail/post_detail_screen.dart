// =========================================================================
// PostDetailScreen
// Màn hình chi tiết bài viết kèm bình luận
// =========================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/personalProfileScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/post_detail/service/post_detail_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/post_detail/widgets/comment_input.dart';
import 'package:nhom_3_damh_lttbdd/screens/post_detail/widgets/comment_list.dart';
import 'package:nhom_3_damh_lttbdd/screens/post_detail/widgets/post_content_card.dart';
import '/model/post_model.dart';
import '/model/comment_model.dart';

class PostDetailScreen extends StatefulWidget {
  final String reviewId; // ID bài viết cần hiển thị

  const PostDetailScreen({Key? key, required this.reviewId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // =========================================================================
  // SERVICES & CONTROLLERS
  // =========================================================================
  final PostDetailService _service =
      PostDetailService(); // Service tương tác Firestore
  final TextEditingController _commentController =
      TextEditingController(); // Controller input comment
  final FocusNode _commentFocus =
      FocusNode(); // FocusNode để focus comment input

  // =========================================================================
  // STATE VARIABLES
  // =========================================================================
  Post? _post; // Bài viết hiện tại
  bool _isLoadingPost = true; // Flag loading bài viết
  CommentModel? _replyingToComment; // Comment đang reply
  bool _isSending = false; // Flag gửi comment

  // =========================================================================
  // AUTH HELPERS
  // =========================================================================
  String get _currentUserId =>
      auth.FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isAuthenticated => _currentUserId.isNotEmpty;

  // =========================================================================
  // LIFECYCLE
  // =========================================================================
  @override
  void initState() {
    super.initState();
    _loadPost(); // Load bài viết khi mở màn hình
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  // =========================================================================
  // DATA LOADING
  // =========================================================================

  /// Load post từ Firestore
  Future<void> _loadPost() async {
    setState(() => _isLoadingPost = true);

    try {
      final post = await _service.fetchPost(widget.reviewId, _currentUserId);

      if (post == null) {
        // Nếu bài viết không tồn tại
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bài viết không tồn tại!')),
          );
          Navigator.pop(context);
        }
        return;
      }

      if (mounted) {
        setState(() {
          _post = post;
          _isLoadingPost = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPost = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải bài viết: $e')));
      }
    }
  }

  // =========================================================================
  // POST ACTIONS
  // =========================================================================

  /// Toggle like/unlike bài viết
  Future<void> _togglePostLike() async {
    if (!_isAuthenticated || _post == null) return;

    try {
      await _service.togglePostLike(
        reviewId: widget.reviewId,
        userId: _currentUserId,
        isCurrentlyLiked: _post!.isLikedByUser,
      );
      await _loadPost(); // Reload post để cập nhật trạng thái like
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // =========================================================================
  // COMMENT ACTIONS
  // =========================================================================

  /// Gửi comment mới hoặc reply comment
  Future<void> _sendComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || !_isAuthenticated || _isSending) return;

    setState(() => _isSending = true);
    _commentFocus.unfocus();

    try {
      await _service.sendComment(
        reviewId: widget.reviewId,
        userId: _currentUserId,
        content: commentText,
        parentCommentId: _replyingToComment?.id,
      );

      _commentController.clear();
      setState(() => _replyingToComment = null);

      await _loadPost(); // Reload post để cập nhật comment count

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bình luận đã được gửi!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi bình luận: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Toggle like/unlike comment
  Future<void> _toggleCommentLike(CommentModel comment) async {
    if (!_isAuthenticated) return;

    try {
      await _service.toggleCommentLike(
        reviewId: widget.reviewId,
        commentId: comment.id,
        userId: _currentUserId,
        isCurrentlyLiked: comment.isLikedByUser,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thích bình luận: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Bắt đầu reply một comment
  void _startReplyToUser(CommentModel comment) {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn cần đăng nhập để phản hồi!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _replyingToComment = comment;
      _commentController.text = '@${comment.author.name} ';
      _commentFocus.requestFocus();
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
  }

  /// Hủy reply comment
  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
      _commentController.clear();
      _commentFocus.unfocus();
    });
  }

  // =========================================================================
  // NAVIGATION
  // =========================================================================

  /// Chuyển đến trang profile của tác giả
  void _navigateToAuthorProfile() {
    if (_post == null) return;

    // TODO: uncomment khi PersonalProfileScreen sẵn sàng
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalProfileScreen(userId: _post!.authorId),
      ),
    );

    // Temporary placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to profile: ${_post!.author.name}')),
    );
  }

  // =========================================================================
  // BUILD UI
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    // Loading post
    if (_isLoadingPost) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    // Error nếu post null
    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bài viết')),
        body: const Center(child: Text('Không thể tải bài viết')),
      );
    }

    // Main UI
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header với back button
          SafeArea(
            bottom: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Bài viết',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Nội dung post + comments
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // PostContentCard hiển thị bài viết
                PostContentCard(
                  post: _post!,
                  onLike: _togglePostLike,
                  onComment: () => _commentFocus.requestFocus(),
                  onShare: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share chức năng đang phát triển'),
                      ),
                    );
                  },
                  onAuthorTap: _navigateToAuthorProfile,
                ),

                const SizedBox(height: 8),

                // Section header cho comments
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Bình luận (${_post!.commentCount})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // CommentList: hiển thị danh sách comment real-time
                CommentList(
                  reviewId: widget.reviewId,
                  currentUserId: _currentUserId,
                  service: _service,
                  onCommentLike: _toggleCommentLike,
                  onCommentReply: _startReplyToUser,
                ),
              ],
            ),
          ),

          // CommentInput: gửi comment mới hoặc reply
          CommentInput(
            controller: _commentController,
            focusNode: _commentFocus,
            replyingTo: _replyingToComment,
            isSending: _isSending,
            onSend: _sendComment,
            onCancelReply: _cancelReply,
          ),
        ],
      ),
    );
  }
}
