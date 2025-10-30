// screens/postDetailScreen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:intl/intl.dart';
import 'package:nhom_3_damh_lttbdd/model/comment_model.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';
import 'package:nhom_3_damh_lttbdd/screens/personalProfileScreen.dart';

// ===================================================================
// POST DETAIL SCREEN - Hiển thị bài viết đầy đủ + Comment
// ===================================================================

class PostDetailScreen extends StatefulWidget {
  final String reviewId;

  const PostDetailScreen({
    Key? key,
    required this.reviewId,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final Map<String, User> _userCache = {};
  bool _isSending = false;

  Post? _post;
  bool _isLoadingPost = true;
  CommentModel? _replyingToComment;

  String get _currentUserId => auth.FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isAuthenticated => _currentUserId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  // ===================================================================
  // LOAD POST DATA
  // ===================================================================

  Future<void> _loadPost() async {
    try {
      final reviewDoc = await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.reviewId)
          .get();

      if (!reviewDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bài viết không tồn tại!')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final reviewData = reviewDoc.data() as Map<String, dynamic>;
      final String authorId = reviewData['userId'] ?? '';

      User postAuthor = User.empty();
      if (authorId.isNotEmpty) {
        postAuthor = await _fetchAndCacheUser(authorId);
      }

      // Kiểm tra like status
      bool isLiked = false;
      if (_currentUserId.isNotEmpty) {
        final likeDoc = await FirebaseFirestore.instance
            .collection('reviews')
            .doc(widget.reviewId)
            .collection('likes')
            .doc(_currentUserId)
            .get();
        isLiked = likeDoc.exists;
      }

      if (mounted) {
        setState(() {
          _post = Post.fromDoc(reviewDoc, postAuthor, isLiked: isLiked);
          _isLoadingPost = false;
        });
      }
    } catch (e) {
      print('Error loading post: $e');
      if (mounted) {
        setState(() {
          _isLoadingPost = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bài viết: $e')),
        );
      }
    }
  }

  // ===================================================================
  // USER CACHE
  // ===================================================================

  Future<User> _fetchAndCacheUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final user = User.fromDoc(userDoc);
        _userCache[userId] = user;
        return user;
      }
    } catch (e) {
      print('Error fetching user $userId: $e');
    }
    return User(
      id: userId,
      name: 'Người dùng đã xóa',
      avatarUrl: 'assets/images/default_avatar.png',
    );
  }

  // ===================================================================
  // COMMENT ACTIONS
  // ===================================================================

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

      final Map<String, dynamic> commentData = {
        'userId': _currentUserId,
        'content': commentText,
        'commentedAt': FieldValue.serverTimestamp(),
      };

      if (_replyingToComment != null) {
        commentData['parentCommentId'] = _replyingToComment!.id;
      }

      await commentsRef.add(commentData);
      await reviewRef.update({'commentCount': FieldValue.increment(1)});

      _commentController.clear();
      setState(() {
        _replyingToComment = null;
      });

      // Reload post để cập nhật commentCount
      await _loadPost();

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

  // ===================================================================
  // POST ACTIONS
  // ===================================================================

  Future<void> _togglePostLike() async {
    if (!_isAuthenticated || _post == null) return;

    final reviewRef = FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.reviewId);
    final likeRef = reviewRef.collection('likes').doc(_currentUserId);

    try {
      if (_post!.isLikedByUser) {
        await likeRef.delete();
        await reviewRef.update({'likeCount': FieldValue.increment(-1)});
      } else {
        await likeRef.set({
          'userId': _currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await reviewRef.update({'likeCount': FieldValue.increment(1)});
      }

      // Reload post
      await _loadPost();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ===================================================================
  // BUILD UI
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPost) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bài viết')),
        body: const Center(child: Text('Không thể tải bài viết')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
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

          // Content: Post + Comments
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ✅ POST DETAIL CARD
                _buildPostDetail(),

                const SizedBox(height: 8),

                // ✅ COMMENTS SECTION
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

                _buildCommentsList(),
              ],
            ),
          ),

          // Comment Input
          _buildCommentInput(),
        ],
      ),
    );
  }

  // ===================================================================
  // POST DETAIL WIDGET
  // ===================================================================

  Widget _buildPostDetail() {
    final post = _post!;
    final numberFormat = NumberFormat.compact(locale: "en_US");

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Info
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PersonalProfileScreen(userId: post.authorId),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.author.avatarUrl.startsWith('http')
                      ? NetworkImage(post.author.avatarUrl)
                      : AssetImage(post.author.avatarUrl) as ImageProvider,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      post.timeAgo,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            post.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Content
          if (post.content.isNotEmpty) ...[
            Text(
              post.content,
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
            const SizedBox(height: 16),
          ],

          // Images
          if (post.imageUrls.isNotEmpty) ...[
            _buildImageGallery(post.imageUrls),
            const SizedBox(height: 16),
          ],

          // Tags
          if (post.tags.isNotEmpty) ...[
            Wrap(
              spacing: 8.0,
              children: post.tags
                  .map(
                    (tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          const Divider(),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPostActionButton(
                icon: post.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                label: numberFormat.format(post.likeCount),
                onPressed: _togglePostLike,
                color: post.isLikedByUser ? Colors.red : Colors.grey[700],
              ),
              _buildPostActionButton(
                icon: Icons.chat_bubble_outline,
                label: numberFormat.format(post.commentCount),
                onPressed: () {
                  // Scroll to comments or focus input
                  _commentFocus.requestFocus();
                },
              ),
              _buildPostActionButton(
                icon: Icons.share_outlined,
                label: 'Chia sẻ',
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> imageUrls) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrls[0],
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrls[index],
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey[700], size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color ?? Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // COMMENTS LIST
  // ===================================================================

  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.reviewId)
          .collection('comments')
          .orderBy('commentedAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Text('Lỗi tải bình luận: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final commentDocs = snapshot.data?.docs ?? [];
        if (commentDocs.isEmpty) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(32),
            child: const Center(
              child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!'),
            ),
          );
        }

        return FutureBuilder<List<CommentModel>>(
          future: _mapCommentsWithUsers(commentDocs),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

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

            return Container(
              color: Colors.white,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  return _buildCommentItem(comments[index]);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<CommentModel>> _mapCommentsWithUsers(
      List<QueryDocumentSnapshot> docs) async {
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
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // COMMENT INPUT
  // ===================================================================

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_replyingToComment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
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
      ),
    );
  }
}