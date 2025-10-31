// timeline_post_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:nhom_3_damh_lttbdd/model/post_model.dart';
import 'package:nhom_3_damh_lttbdd/screens/commentScreen.dart'; // Import CommentScreen

class TimelinePostCard extends StatefulWidget {
  final Post post;
  final String? currentAuthUserId;
  final VoidCallback onPostUpdated;

  const TimelinePostCard({
    Key? key,
    required this.post,
    required this.currentAuthUserId,
    required this.onPostUpdated,
  }) : super(key: key);

  @override
  State<TimelinePostCard> createState() => _TimelinePostCardState();
}

class _TimelinePostCardState extends State<TimelinePostCard> {
  late bool _isLiked;
  late int _likeCount;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByUser;
    _likeCount = widget.post.likeCount;
  }

  // ============================================================
  // 🔹 XỬ LÝ LIKE POST (Optimistic UI)
  // ============================================================
  Future<void> _toggleLike() async {
    if (widget.currentAuthUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn cần đăng nhập để thích bài viết!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isProcessing) return;

    final bool newLikedState = !_isLiked;
    final int likeChange = newLikedState ? 1 : -1;

    setState(() {
      _isProcessing = true;
      _isLiked = newLikedState;
      _likeCount += likeChange;
    });

    final reviewRef =
    FirebaseFirestore.instance.collection('reviews').doc(widget.post.id);
    final likeRef = reviewRef.collection('likes').doc(widget.currentAuthUserId);

    try {
      if (!newLikedState) {
        await likeRef.delete();
        await reviewRef.update({'likeCount': FieldValue.increment(-1)});
      } else {
        await likeRef.set({
          'userId': widget.currentAuthUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await reviewRef.update({'likeCount': FieldValue.increment(1)});
      }
    } catch (e) {
      debugPrint("Lỗi toggle like: $e");
      // rollback
      setState(() {
        _isLiked = !_isLiked;
        _likeCount -= likeChange;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lỗi: Không thể thay đổi trạng thái thích."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ============================================================
  // 🔹 SHOW COMMENT MODAL
  // ============================================================
  void _showCommentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentScreen(
          reviewId: widget.post.id,
          post: widget.post,
        );
      },
    ).whenComplete(() {
      // gọi callback khi modal đóng (nếu cần cập nhật)
      widget.onPostUpdated();
    });
  }

  // ============================================================
  // 🔹 HÌNH ẢNH & AVATAR
  // ============================================================
  Widget _getPostImage() {
    if (widget.post.imageUrls.isEmpty) return const SizedBox.shrink();
    final imageUrl = widget.post.imageUrls.first;

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Icon(Icons.error_outline, color: Colors.red),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }

  ImageProvider _fallbackAuthorAvatar() {
    if (widget.post.author.avatarUrl.startsWith('http')) {
      return NetworkImage(widget.post.author.avatarUrl);
    }
    return AssetImage(widget.post.author.avatarUrl);
  }

  // ============================================================
  // 🔹 GIAO DIỆN CHÍNH
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact(locale: "en_US");

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // hình bài
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: _getPostImage(),
          ),

          // Thông tin bài + author: dùng FutureBuilder lấy user từ Firestore
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.post.author.id)
                .get()
                .then((snap) => snap as DocumentSnapshot<Map<String, dynamic>>),
            builder: (context, authorSnap) {
              // fallback tên + avatar
              String authorName = widget.post.author.name;
              ImageProvider authorAvatar = _fallbackAuthorAvatar();

              if (authorSnap.connectionState == ConnectionState.waiting) {
                // vẫn có thể hiển thị nội dung chính, chỉ loading author nhỏ
              } else if (authorSnap.hasData && authorSnap.data!.exists) {
                final data = authorSnap.data!.data();
                if (data != null) {
                  // Lấy tên ưu tiên trường 'name' rồi 'fullName', fallback về post.author.name
                  authorName = (data['name'] as String?) ??
                      (data['fullName'] as String?) ??
                      authorName;

                  final avatarUrl = data['avatarUrl'] as String?;
                  if (avatarUrl != null && avatarUrl.isNotEmpty) {
                    authorAvatar = avatarUrl.startsWith('http')
                        ? NetworkImage(avatarUrl)
                        : AssetImage(avatarUrl);
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // tags
                    if (widget.post.tags.isNotEmpty)
                      Text(
                        widget.post.tags
                            .firstWhere((t) => t.startsWith('#'),
                            orElse: () => ""),
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // title
                    Text(
                      widget.post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // content (nếu có)
                    if (widget.post.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          widget.post.content,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // author + actions
                    Row(
                      children: [
                        CircleAvatar(radius: 12, backgroundImage: authorAvatar),
                        const SizedBox(width: 8),
                        // HIỂN THỊ TÊN LẤY TỪ FIRESTORE (userSnap.data()!['name'])
                        Text(
                          authorName,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Spacer(),

                        // LIKE
                        InkWell(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: _isLiked ? Colors.red : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                numberFormat.format(_likeCount),
                                style: TextStyle(
                                  color: _isLiked ? Colors.red : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // COMMENT -> mở CommentScreen
                        InkWell(
                          onTap: _showCommentModal,
                          child: Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(numberFormat.format(widget.post.commentCount)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
