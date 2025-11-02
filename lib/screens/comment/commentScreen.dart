// File: screens/comment/commentScreen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:intl/intl.dart';

// Import Models
import 'package:nhom_3_damh_lttbdd/model/comment_model.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';

// Import Service và Widgets đã tách
import 'service/comment_service.dart';
import 'widget/comment_item.dart';
import 'widget/comment_input_bar.dart';

// Callback cho thông báo
typedef OnNotificationCreated =
    void Function(
      String recipientId,
      String senderId,
      String reviewId,
      String message,
    );

class CommentScreen extends StatefulWidget {
  final String reviewId;
  final Post post;
  final OnNotificationCreated onCommentSent;

  const CommentScreen({
    Key? key,
    required this.reviewId,
    required this.post,
    required this.onCommentSent,
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  // Service
  final CommentService _service = CommentService();

  // Controllers
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();

  // State
  bool _isSending = false;
  CommentModel? _replyingToComment;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  String get _currentUserId =>
      auth.FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isAuthenticated => _currentUserId.isNotEmpty;

  // --- HÀM XỬ LÝ LOGIC (CONTROLLERS) ---

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || !_isAuthenticated || _isSending) return;

    setState(() => _isSending = true);
    _commentFocus.unfocus();

    try {
      // 1. Gửi comment (đã bao gồm cập nhật commentCount)
      await _service.sendComment(
        reviewId: widget.reviewId,
        currentUserId: _currentUserId,
        content: commentText,
        replyingToComment: _replyingToComment,
      );

      // 2. Kích hoạt Callback tạo thông báo
      String recipientId = (_replyingToComment != null)
          ? _replyingToComment!.userId
          : widget.post.authorId;

      // Chỉ gửi thông báo nếu người nhận không phải là chính mình
      if (recipientId != _currentUserId) {
        widget.onCommentSent(
          recipientId,
          _currentUserId,
          widget.reviewId,
          commentText,
        );
      }

      // 3. Reset UI
      _commentController.clear();
      setState(() => _replyingToComment = null);
      _showSnackBar('Bình luận đã được gửi!');
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst("Exception: ", ""),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _toggleCommentLike(CommentModel comment) async {
    if (!_isAuthenticated) return;
    try {
      await _service.toggleCommentLike(
        reviewId: widget.reviewId,
        commentId: comment.id,
        currentUserId: _currentUserId,
        isCurrentlyLiked: comment.isLikedByUser,
      );
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst("Exception: ", ""),
        isError: true,
      );
    }
  }

  void _startReplyToUser(CommentModel comment) {
    if (!_isAuthenticated) {
      _showSnackBar("Bạn cần đăng nhập để phản hồi!", isError: true);
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

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
      _commentController.clear();
      _commentFocus.unfocus();
    });
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 12, left: 16, right: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Bình luận (${widget.post.commentCount})',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double maxSheetHeight = mediaQuery.size.height * 0.9;

    return Container(
      height: maxSheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(), // Widget header giữ lại

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getCommentsStream(widget.reviewId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi tải bình luận: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final commentDocs = snapshot.data?.docs ?? [];
                if (commentDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có bình luận nào. Hãy là người đầu tiên!',
                    ),
                  );
                }

                return FutureBuilder<List<CommentModel>>(
                  // Map data (lấy user, like status)
                  future: _service.mapCommentsWithUsers(
                    commentDocs,
                    widget.reviewId,
                    _currentUserId,
                  ),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData) {
                      return const Center(
                        child: Text('Lỗi hiển thị dữ liệu bình luận.'),
                      );
                    }

                    final comments = userSnapshot.data!;

                    // Sử dụng Widget mới
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return CommentItem(
                          comment: comments[index],
                          onLike: () => _toggleCommentLike(comments[index]),
                          onReply: () => _startReplyToUser(comments[index]),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Sử dụng Widget mới
          CommentInputBar(
            controller: _commentController,
            focusNode: _commentFocus,
            isSending: _isSending,
            replyingToComment: _replyingToComment,
            onSend: _sendComment,
            onCancelReply: _cancelReply,
          ),
        ],
      ),
    );
  }
}
