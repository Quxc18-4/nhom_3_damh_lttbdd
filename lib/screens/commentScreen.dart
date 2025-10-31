import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:intl/intl.dart';

import 'package:nhom_3_damh_lttbdd/model/comment_model.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';

class CommentScreen extends StatefulWidget {
  final String reviewId;
  final Post post;

  const CommentScreen({
    Key? key,
    required this.reviewId,
    required this.post,
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final Map<String, User> _userCache = {}; // Cache thông tin User
  bool _isSending = false;

  // ✅ Trạng thái cho việc Phản hồi
  CommentModel? _replyingToComment;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  // Lấy User ID của người dùng hiện tại
  String get _currentUserId => auth.FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isAuthenticated => _currentUserId.isNotEmpty;

  // =======================================================================
  // HÀM FETCH VÀ CACHE USER DATA
  // =======================================================================
  /// Fetches user data from Firestore or returns from cache.
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
        // ✅ Ưu tiên name → fullName → fallback post.author.name
        final String userName =
            data['name'] ??
                data['fullName'] ??
                widget.post.author.name; // fallback khi không có name/fullName
        final String avatarUrl =
            data['avatarUrl'] ?? 'assets/images/default_avatar.png';

        final user = User(
          id: userId,
          name: userName,
          avatarUrl: avatarUrl,
        );

        _userCache[userId] = user;
        return user;
      }
    } catch (e) {
      print('⚠️ Lỗi khi lấy user $userId: $e');
    }

    // Trường hợp lỗi hoặc không tồn tại user
    return User(
      id: userId,
      name: widget.post.author.name,
      avatarUrl: 'assets/images/default_avatar.png',
    );
  }



  // =======================================================================
  // HÀM GỬI COMMENT MỚI (HOẶC REPLY)
  // =======================================================================
  Future<void> _sendComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || !_isAuthenticated || _isSending) return;

    setState(() {
      _isSending = true;
    });

    _commentFocus.unfocus();

    try {
      final reviewRef = FirebaseFirestore.instance.collection('reviews').doc(widget.reviewId);
      final commentsRef = reviewRef.collection('comments');

      // Chuẩn bị dữ liệu
      final Map<String, dynamic> commentData = {
        'userId': _currentUserId,
        'content': commentText,
        'commentedAt': FieldValue.serverTimestamp(),
      };

      // ✅ Thêm parentCommentId nếu đang phản hồi
      if (_replyingToComment != null) {
        commentData['parentCommentId'] = _replyingToComment!.id;
      }

      // Tạo document comment mới
      await commentsRef.add(commentData);

      // Cập nhật commentCount trên document review chính
      await reviewRef.update({'commentCount': FieldValue.increment(1)});

      // Xóa nội dung nhập và reset trạng thái
      _commentController.clear();
      setState(() {
        _replyingToComment = null; // ✅ Reset trạng thái reply
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bình luận đã được gửi!'), duration: Duration(seconds: 1)),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi bình luận: $e'), backgroundColor: Colors.red),
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
  // HÀM XỬ LÝ LIKE TRÊN COMMENT
  // =======================================================================
  Future<void> _toggleCommentLike(CommentModel comment) async {
    if (!_isAuthenticated) return;

    final commentRef = FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.reviewId)
        .collection('comments')
        .doc(comment.id);

    // ID của document Like là ID của người dùng (theo Rules)
    final likeRef = commentRef.collection('likes').doc(_currentUserId);

    try {
      if (comment.isLikedByUser) {
        // Unlike: Xóa document Like và giảm số lượng
        await likeRef.delete();
        await commentRef.update({'likeCount': FieldValue.increment(-1)});
      } else {
        // Like: Tạo document Like và tăng số lượng
        await likeRef.set({'createdAt': FieldValue.serverTimestamp()});
        await commentRef.update({'likeCount': FieldValue.increment(1)});
      }

      // ✅ CẬP NHẬT TRẠNG THÁI CỤC BỘ (Không cần setState vì StreamBuilder sẽ refresh)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi thích bình luận: $e'), backgroundColor: Colors.red),
      );
      print('Error toggle comment like: $e');
    }
  }


  // =======================================================================
  // HÀM XỬ LÝ REPLY
  // =======================================================================
  void _startReplyToUser(CommentModel comment) {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn cần đăng nhập để phản hồi!"), backgroundColor: Colors.orange),
      );
      return;
    }

    // ✅ Thiết lập trạng thái Reply
    setState(() {
      _replyingToComment = comment;
      _commentController.text = '@${comment.author.name} '; // Thêm tag tên
      _commentFocus.requestFocus(); // Focus vào input
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


  // =======================================================================
  // WIDGET BUILDER
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
                  .orderBy('commentedAt', descending: false) // Sửa thành ascending để hiển thị comment cũ nhất ở trên
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi tải bình luận: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final commentDocs = snapshot.data?.docs ?? [];
                if (commentDocs.isEmpty) {
                  return const Center(child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!'));
                }

                return FutureBuilder<List<CommentModel>>(
                  future: _mapCommentsWithUsers(commentDocs),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData) {
                      return const Center(child: Text('Lỗi hiển thị dữ liệu người dùng.'));
                    }

                    final comments = userSnapshot.data!;

                    return ListView.builder(
                      // reverse: true, // Bỏ reverse để comment cũ nhất ở trên
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

          // ✅ COMMENT INPUT SECTION
          _buildCommentInput(viewInsets),
        ],
      ),
    );
  }

  // Hàm Map comment documents thành CommentModel và fetch User
  Future<List<CommentModel>> _mapCommentsWithUsers(List<QueryDocumentSnapshot> docs) async {
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
                // Tên và Thời gian
                Row(
                  children: [
                    Text(
                      comment.author.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeFormat.format(comment.commentedAt),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Nội dung bình luận
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 15),
                ),

                const SizedBox(height: 8),

                // Nút Thích và Phản hồi
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
                                color: comment.isLikedByUser ? Colors.red.shade700 : Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 12
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
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500, fontSize: 12),
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
                      style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 16, color: Colors.blue.shade800),
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
                    hintText: _replyingToComment != null ? 'Viết phản hồi...' : 'Viết bình luận...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
}
