import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:intl/intl.dart';
import 'package:nhom_3_damh_lttbdd/screens/commentScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/personalProfileScreen.dart';
import '/model/post_model.dart';
import 'save_dialog.dart';
// Import screens
// import '../../screens/personalProfileScreen.dart';
// import '../../screens/commentScreen.dart';

// Định nghĩa kiểu hàm cho callback notification
typedef NotificationCreator =
    Future<void> Function({
      required String recipientId,
      required String senderId,
      required String reviewId,
      required String type,
      required String message,
    });

class PostCard extends StatefulWidget {
  final Post post;
  final String userId;
  final VoidCallback onPostUpdated;
  final NotificationCreator createNotification;

  const PostCard({
    Key? key,
    required this.post,
    required this.userId,
    required this.onPostUpdated,
    required this.createNotification,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // --- STATE VARIABLES ---
  late bool _isLiked;
  late int _likeCount;
  late bool _isSaved;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByUser;
    _likeCount = widget.post.likeCount;
    _isSaved = false;
    _checkIfSaved();
  }

  // =========================================================================
  // DATA OPERATIONS
  // =========================================================================

  /// Kiểm tra xem bài viết đã được lưu chưa
  Future<void> _checkIfSaved() async {
    try {
      final bookmarkQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('bookmarks')
          .where('reviewID', isEqualTo: widget.post.id)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _isSaved = bookmarkQuery.docs.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint("Lỗi kiểm tra bookmark: $e");
    }
  }

  /// Toggle Like/Unlike
  Future<void> _toggleLike() async {
    // Lấy current user ID từ Firebase Auth
    final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn cần đăng nhập để thích bài viết!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isProcessing) return;

    // Optimistic UI update
    final bool newLikedState = !_isLiked;
    final int likeChange = newLikedState ? 1 : -1;

    setState(() {
      _isProcessing = true;
      _isLiked = newLikedState;
      _likeCount += likeChange;
    });

    final reviewRef = FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.post.id);
    final likeRef = reviewRef.collection('likes').doc(currentUserId);

    try {
      if (!newLikedState) {
        // Unlike
        await likeRef.delete();
        await reviewRef.update({'likeCount': FieldValue.increment(-1)});
      } else {
        // Like
        await likeRef.set({'createdAt': FieldValue.serverTimestamp()});
        await reviewRef.update({'likeCount': FieldValue.increment(1)});

        // Tạo thông báo
        widget.createNotification(
          recipientId: widget.post.authorId,
          senderId: currentUserId,
          reviewId: widget.post.id,
          type: 'LIKE',
          message: "đã thích bài viết: ${widget.post.title}",
        );
      }
    } catch (e) {
      // Rollback nếu lỗi
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount -= likeChange;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
      debugPrint("Lỗi toggle like: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // =========================================================================
  // NAVIGATION ACTIONS
  // =========================================================================

  /// Mở màn hình Comment
  void _showCommentScreen(BuildContext context) {
    if (auth.FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn cần đăng nhập để xem/bình luận!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentScreen(
          reviewId: widget.post.id,
          post: widget.post,
          onCommentSent: (recipientId, senderId, reviewId, message) {
            widget.createNotification(
              recipientId: recipientId,
              senderId: senderId,
              reviewId: reviewId,
              type: 'COMMENT',
              message: message,
            );
          },
        );
        // return Container(); // Placeholder
      },
    ).then((_) {
      widget.onPostUpdated();
    });
  }

  /// Hiển thị Save Dialog
  void _showSaveDialog(BuildContext context) {
    if (auth.FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn cần đăng nhập để lưu bài viết!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    SaveDialog.show(
      context,
      userId: widget.userId,
      reviewId: widget.post.id,
      authorId: widget.post.authorId,
      postImageUrl: widget.post.imageUrls.isNotEmpty
          ? widget.post.imageUrls.first
          : null,
    ).then((_) {
      _checkIfSaved(); // Refresh saved state
    });
  }

  /// Navigate đến profile của author
  void _navigateToAuthorProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PersonalProfileScreen(userId: widget.post.authorId),
      ),
    );
  }

  // =========================================================================
  // UI HELPERS
  // =========================================================================

  ImageProvider _getAuthorAvatar() {
    if (widget.post.author.avatarUrl.startsWith('http')) {
      return NetworkImage(widget.post.author.avatarUrl);
    }
    return AssetImage(widget.post.author.avatarUrl);
  }

  Widget _buildImage(
    String imageUrl, {
    required double height,
    required double width,
    Widget? overlay,
    required bool isTaller,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: isTaller ? StackFit.expand : StackFit.loose,
        children: [
          Image.network(
            imageUrl,
            height: height,
            width: width,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                ),
              );
            },
          ),
          if (overlay != null) overlay,
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final images = widget.post.imageUrls;
    final int count = images.length;

    if (count == 0) return const SizedBox.shrink();

    const double mainHeight = 300;

    // 1 ảnh: Full width
    if (count == 1) {
      return SizedBox(
        height: mainHeight,
        width: double.infinity,
        child: _buildImage(
          images[0],
          height: mainHeight,
          width: double.infinity,
          isTaller: true,
        ),
      );
    }

    // 2 ảnh: 50-50
    if (count == 2) {
      return SizedBox(
        height: mainHeight,
        child: Row(
          children: [
            Expanded(
              child: _buildImage(
                images[0],
                height: mainHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildImage(
                images[1],
                height: mainHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
          ],
        ),
      );
    }

    // 3 ảnh: 2/3 - 1/3 vertical
    if (count == 3) {
      return SizedBox(
        height: mainHeight,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildImage(
                images[0],
                height: mainHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: _buildImage(
                      images[1],
                      height: double.infinity,
                      width: double.infinity,
                      isTaller: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _buildImage(
                      images[2],
                      height: double.infinity,
                      width: double.infinity,
                      isTaller: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4+ ảnh: Grid 2x2 với overlay "+N"
    final remainingCount = count - 4;

    return SizedBox(
      height: mainHeight,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImage(
                    images[0],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildImage(
                    images[1],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImage(
                    images[2],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildImage(
                    images[3],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                    overlay: remainingCount > 0
                        ? Container(
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                '+ $remainingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String? text,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey[700], size: 22),
            if (text != null) const SizedBox(width: 4),
            if (text != null)
              Text(text, style: TextStyle(color: color ?? Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // BUILD UI
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact(locale: "en_US");

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: Author info ---
          Row(
            children: [
              GestureDetector(
                onTap: _navigateToAuthorProfile,
                child: Row(
                  children: [
                    CircleAvatar(backgroundImage: _getAuthorAvatar()),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.author.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.post.timeAgo,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
            ],
          ),

          const SizedBox(height: 12),

          // --- TITLE ---
          Text(
            widget.post.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          // --- CONTENT ---
          if (widget.post.content.isNotEmpty) ...[
            Text(
              widget.post.content,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
          ],

          // --- IMAGES GRID ---
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildPhotoGrid(),
          ),

          const SizedBox(height: 12),

          // --- TAGS ---
          Wrap(
            spacing: 8.0,
            children: widget.post.tags
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

          const Divider(height: 24),

          // --- ACTION BUTTONS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Like
              _buildActionButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                text: numberFormat.format(_likeCount),
                onPressed: _toggleLike,
                color: _isLiked ? Colors.red : Colors.grey[700],
              ),

              // Comment
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                text: widget.post.commentCount.toString(),
                onPressed: () => _showCommentScreen(context),
              ),

              // Share
              _buildActionButton(
                icon: Icons.share_outlined,
                text: null,
                onPressed: () {},
              ),

              // Gift
              _buildActionButton(
                icon: Icons.card_giftcard_outlined,
                text: null,
                onPressed: () {},
              ),

              // Bookmark
              _buildActionButton(
                icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                text: null,
                onPressed: () => _showSaveDialog(context),
                color: _isSaved ? Colors.orange : Colors.grey[700],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
