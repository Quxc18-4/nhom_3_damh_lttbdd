import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:intl/intl.dart';

import 'package:nhom_3_damh_lttbdd/model/comment_model.dart'; // Đảm bảo đã import CommentModel
import 'package:nhom_3_damh_lttbdd/model/post_model.dart'; // Đảm bảo đã import Post và User Model

// =======================================================================
// ĐỊNH NGHĨA CALLBACK CHO VIỆC TẠO THÔNG BÁO
// =======================================================================
typedef OnNotificationCreated =
    void Function(
      String recipientId,
      String senderId,
      String reviewId,
      String message,
    ); // Bao gồm nội dung comment

class CommentScreen extends StatefulWidget {
  final String reviewId;
  final Post post;

  // THÊM: Callback để gửi tín hiệu tạo thông báo ra bên ngoài (PostCard)
  final OnNotificationCreated onCommentSent;

  const CommentScreen({
    Key? key,
    required this.reviewId,
    required this.post,
    required this.onCommentSent, // Yêu cầu hàm callback
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final Map<String, User> _userCache = {};
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

  // =======================================================================
  // HÀM FETCH VÀ CACHE USER DATA
  // =======================================================================
  Future<User> _fetchAndCacheUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final String userName =
            data['name'] ?? data['fullName'] ?? widget.post.author.name;
        final String avatarUrl =
            data['avatarUrl'] ?? 'assets/images/default_avatar.png';

        final user = User(id: userId, name: userName, avatarUrl: avatarUrl);

        _userCache[userId] = user;
        return user;
      }
    } catch (e) {
      print('⚠️ Lỗi khi lấy user $userId: $e');
    }

    return User(
      id: userId,
      name: widget.post.author.name,
      avatarUrl: 'assets/images/default_avatar.png',
    );
  }

  // =======================================================================
  // HÀM GỬI COMMENT MỚI (HOẶC REPLY) - ĐÃ GỌI CALLBACK NOTIFICATION
  // =======================================================================
  Future<void> _sendComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || !_isAuthenticated || _isSending) return;

    setState(() {
      _isSending = true;
    });

    _commentFocus.unfocus();

    try {
      final reviewRef = FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.reviewId);
      final commentsRef = reviewRef.collection('comments');

      // 1. Chuẩn bị dữ liệu
      final Map<String, dynamic> commentData = {
        'userId': _currentUserId,
        'content': commentText,
        'commentedAt': FieldValue.serverTimestamp(),
      };

      if (_replyingToComment != null) {
        commentData['parentCommentId'] = _replyingToComment!.id;
      }

      // 2. Tạo document comment mới
      await commentsRef.add(commentData);

      // 3. Cập nhật commentCount trên document review chính
      await reviewRef.update({'commentCount': FieldValue.increment(1)});

      // 4. GỌI CALLBACK TẠO THÔNG BÁO VỚI NỘI DUNG COMMENT
      String recipientId;
      if (_replyingToComment != null) {
        // Nếu là reply, người nhận là chủ comment được reply
        recipientId = _replyingToComment!.userId;
      } else {
        // Nếu là comment gốc, người nhận là chủ bài viết
        recipientId = widget.post.authorId;
      }

      widget.onCommentSent(
        recipientId,
        _currentUserId,
        widget.reviewId,
        commentText, // TRUYỀN NỘI DUNG COMMENT
      );

      // 5. Xóa nội dung nhập và reset trạng thái
      _commentController.clear();
      setState(() {
        _replyingToComment = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bình luận đã được gửi!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi bình luận: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error sending comment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // =======================================================================
  // CÁC HÀM XỬ LÝ LIKE, REPLY
  // =======================================================================

  Future<void> _toggleCommentLike(CommentModel comment) async {
    if (!_isAuthenticated) return;

    final commentRef = FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.reviewId)
        .collection('comments')
        .doc(comment.id);

    final likeRef = commentRef.collection('likes').doc(_currentUserId);

    try {
      if (comment.isLikedByUser) {
        await likeRef.delete();
        await commentRef.update({'likeCount': FieldValue.increment(-1)});
      } else {
        await likeRef.set({'createdAt': FieldValue.serverTimestamp()});
        await commentRef.update({'likeCount': FieldValue.increment(1)});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thích bình luận: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error toggle comment like: $e');
    }
  }

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

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
      _commentController.clear();
      _commentFocus.unfocus();
    });
  }

  Future<List<CommentModel>> _mapCommentsWithUsers(
    List<QueryDocumentSnapshot> docs,
  ) async {
    try {
      final futures = docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String? ?? '';

        bool isLiked = false;
        if (_isAuthenticated) {
          final likeDoc = await FirebaseFirestore.instance
              .collection('reviews')
              .doc(widget.reviewId)
              .collection('comments')
              .doc(doc.id)
              .collection('likes')
              .doc(_currentUserId)
              .get();
          isLiked = likeDoc.exists;
        }

        User author = User.empty();
        if (userId.isNotEmpty) {
          author = await _fetchAndCacheUser(userId);
        }

        return CommentModel.fromMap(data, doc.id, author, isLiked: isLiked);
      }).toList();

      return await Future.wait(futures);
    } catch (e, stack) {
      print('🔥 Lỗi khi map comment với user: $e');
      print(stack);
      rethrow;
    }
  }

  // =======================================================================
  // WIDGET BUILDER METHODS
  // =======================================================================

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

  Widget _buildCommentItem(CommentModel comment) {
    final timeFormat = DateFormat('HH:mm, dd/MM');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: comment.author.avatarUrl.startsWith('http')
                ? NetworkImage(comment.author.avatarUrl)
                : AssetImage(comment.author.avatarUrl) as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeFormat.format(comment.commentedAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                Text(comment.content, style: const TextStyle(fontSize: 15)),

                const SizedBox(height: 8),

                Row(
                  children: [
                    // Nút Thích
                    InkWell(
                      onTap: () => _toggleCommentLike(comment),
                      child: Row(
                        children: [
                          Text(
                            'Thích',
                            style: TextStyle(
                              color: comment.isLikedByUser
                                  ? Colors.red.shade700
                                  : Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          if (comment.likeCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                '(${comment.likeCount})',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Nút Phản hồi
                    InkWell(
                      onTap: () => _startReplyToUser(comment),
                      child: Text(
                        'Phản hồi',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // TODO: Chỗ này sẽ hiển thị danh sách Replies nếu cần
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(double viewInsets) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + viewInsets,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị trạng thái đang trả lời
          if (_replyingToComment != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Trả lời ${_replyingToComment!.author.name}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _cancelReply,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          if (_replyingToComment != null) const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocus,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: _replyingToComment != null
                        ? 'Viết phản hồi...'
                        : 'Viết bình luận...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 8),
              _isSending
                  ? const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _sendComment,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // THÊM: PHƯƠNG THỨC BUILD BẮT BUỘC ĐỂ KHẮC PHỤC LỖI
  // =======================================================================
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets.bottom;
    final double maxSheetHeight = mediaQuery.size.height * 0.9;

    return Container(
      height: maxSheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .doc(widget.reviewId)
                  .collection('comments')
                  .orderBy('commentedAt', descending: false)
                  .snapshots(),
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
                  future: _mapCommentsWithUsers(commentDocs),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData) {
                      return const Center(
                        child: Text('Lỗi hiển thị dữ liệu người dùng.'),
                      );
                    }

                    final comments = userSnapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentItem(comments[index]);
                      },
                    );
                  },
                );
              },
            ),
          ),

          _buildCommentInput(viewInsets),
        ],
      ),
    );
  }
}
