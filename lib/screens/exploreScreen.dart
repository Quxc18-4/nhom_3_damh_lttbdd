import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:nhom_3_damh_lttbdd/screens/checkinScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/personalProfileScreen.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';
import 'package:nhom_3_damh_lttbdd/screens/commentScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/notificationScreen.dart'; // Import NotificationScreen

class ExploreScreen extends StatefulWidget {
  final String userId;

  const ExploreScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Post> _posts = [];
  bool _isLoading = true;

  String _userName = "Đang tải...";
  String _userAvatarUrl = "assets/images/default_avatar.png";
  bool _isUserDataLoading = true;

  // Biến đếm thông báo chưa đọc (được cập nhật từ HomePage)
  int _unreadNotificationCount = 0;

  bool get _isAuthenticated => auth.FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserData();
    _fetchPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['name'] ?? data['fullName'] ?? 'Người dùng';
          _userAvatarUrl = data['avatarUrl'] ?? _userAvatarUrl;
          _isUserDataLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _userName = 'Không tìm thấy user';
          _isUserDataLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Lỗi tải data';
          _isUserDataLoading = false;
        });
      }
      print("Lỗi tải thông tin người dùng: $e");
    }
  }

  // Cập nhật hàm fetch post để tải lại dữ liệu
  Future<void> _fetchPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      if (reviewSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _posts = [];
            _isLoading = false;
          });
        }
        return;
      }

      List<Post> fetchedPosts = [];
      Map<String, User> userCache = {};
      final currentUserId = widget.userId;

      for (var reviewDoc in reviewSnapshot.docs) {
        final reviewData = reviewDoc.data() as Map<String, dynamic>? ?? {};
        final String authorId = reviewData['userId'] ?? '';

        User postAuthor = User.empty();

        if (authorId.isNotEmpty) {
          if (userCache.containsKey(authorId)) {
            postAuthor = userCache[authorId]!;
          } else {
            try {
              DocumentSnapshot authorDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(authorId)
                  .get();

              if (authorDoc.exists) {
                final authorData = authorDoc.data() as Map<String, dynamic>;
                // Ưu tiên 'name', nếu không có thì dùng 'fullName'
                final displayName =
                    authorData['name']?.toString().trim().isNotEmpty == true
                    ? authorData['name']
                    : (authorData['fullName'] ?? 'Người dùng ẩn danh');

                postAuthor = User(
                  id: authorDoc.id,
                  name: displayName,
                  avatarUrl:
                      authorData['avatarUrl'] ??
                      'assets/images/default_avatar.png',
                );
                userCache[authorId] = postAuthor;
              } else {
                postAuthor = User(
                  id: authorId,
                  name: 'Người dùng ẩn danh',
                  avatarUrl: 'assets/images/default_avatar.png',
                );
              }
            } catch (e) {
              print("Lỗi fetch author $authorId: $e");
              postAuthor = User(
                id: authorId,
                name: 'Lỗi tải User',
                avatarUrl: 'assets/images/default_avatar.png',
              );
            }
          }
        }

        bool isLiked = false;
        if (_isAuthenticated) {
          try {
            final likeDoc = await FirebaseFirestore.instance
                .collection('reviews')
                .doc(reviewDoc.id)
                .collection('likes')
                .doc(currentUserId)
                .get();
            isLiked = likeDoc.exists;
          } catch (e) {
            print("Lỗi kiểm tra like: $e");
          }
        }

        fetchedPosts.add(Post.fromDoc(reviewDoc, postAuthor, isLiked: isLiked));
      }

      if (mounted) {
        setState(() {
          _posts = fetchedPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi tải bài viết: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreatePostOptions() {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn cần đăng nhập để tạo bài viết!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tạo bài viết',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 10),
              _buildOptionTile(
                icon: Icons.edit_note,
                label: 'Blog',
                subLabel: 'Viết bài',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CheckinScreen(currentUserId: widget.userId),
                    ),
                  ).then((_) => _fetchPosts());
                },
              ),
              _buildOptionTile(
                icon: Icons.camera_alt_outlined,
                label: 'Checkin',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CheckinScreen(currentUserId: widget.userId),
                    ),
                  ).then((_) => _fetchPosts());
                },
              ),
              _buildOptionTile(
                icon: Icons.help_outline,
                label: 'Đặt câu hỏi',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Chuyển đến màn hình đặt câu hỏi
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? subLabel,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subLabel != null)
                  Text(
                    subLabel,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          SafeArea(bottom: false, child: _buildCustomHeader()),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [_buildPostListView(), _buildPostListView()],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostOptions,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 🆕 HÀM TẠO THÔNG BÁO (DÙNG CHO POSTCARD)
  Future<void> _createNotification({
    required String recipientId,
    required String senderId,
    required String reviewId,
    required String type,
    required String message,
  }) async {
    // Tránh gửi thông báo cho chính mình
    if (recipientId == senderId || recipientId.isEmpty || senderId.isEmpty)
      return;

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': recipientId,
        'senderId': senderId,
        'referenceId': reviewId,
        'type': type,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Lỗi tạo thông báo: $e");
    }
  }

  Widget _buildCustomHeader() {
    ImageProvider _getAvatarProvider() {
      if (_userAvatarUrl.startsWith('http')) {
        return NetworkImage(_userAvatarUrl);
      }
      return AssetImage(_userAvatarUrl);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PersonalProfileScreen(userId: widget.userId),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isUserDataLoading
                          ? const CircleAvatar(
                              radius: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : CircleAvatar(
                              radius: 20,
                              backgroundImage: _getAvatarProvider(),
                            ),
                      const SizedBox(width: 12),
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Nút Thông báo (hiện chưa có badge ở đây, badge nằm ở HomePage)
              IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: Colors.grey[800],
                  size: 28,
                ),
                onPressed: () {
                  // Điều hướng đến NotificationScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NotificationScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Đang theo dõi"),
            Tab(text: "Dành cho bạn"),
          ],
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildPostListView() {
    if (_posts.isEmpty) {
      return const Center(
        child: Text(
          "Chưa có bài viết nào.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: PostCard(
            // Sử dụng PostCard
            post: post,
            userId: widget.userId,
            onPostUpdated: () => _fetchPosts(),
            // 🆕 TRUYỀN HÀM TẠO THÔNG BÁO VÀO POSTCARD
            createNotification: _createNotification,
          ),
        );
      },
    );
  }
}

// ===================================================================
// 3. POST CARD (ĐÃ CẬP NHẬT ĐỂ NHẬN HÀM TẠO THÔNG BÁO)
// ===================================================================

// Định nghĩa lại kiểu hàm cho rõ ràng
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

  // 🆕 NHẬN HÀM TẠO THÔNG BÁO
  final NotificationCreator createNotification;

  const PostCard({
    Key? key,
    required this.post,
    required this.userId,
    required this.onPostUpdated,
    required this.createNotification, // 🆕 YÊU CẦU THAM SỐ
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByUser;
    _likeCount = widget.post.likeCount;
  }

  // ✅ Toggle Like/Unlike (ĐÃ GỌI NOTIFICATION)
  Future<void> _toggleLike() async {
    final currentUserId = widget.userId;
    if (auth.FirebaseAuth.instance.currentUser == null) {
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

        // 🆕 TẠO THÔNG BÁO LIKE
        widget.createNotification(
          recipientId: widget.post.authorId,
          senderId: currentUserId,
          reviewId: widget.post.id,
          type: 'LIKE',
          message: "đã thích bài viết: ${widget.post.title}",
        );
      }
    } catch (e) {
      // rollback
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

  // ✅ Mở màn hình Comment (ĐÃ TRUYỀN CALLBACK)
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
          // 🆕 TRUYỀN HÀM TẠO THÔNG BÁO TỪ EXPLORESCREEN
          onCommentSent:
              (
                String recipientId,
                String senderId,
                String reviewId,
                String message,
              ) {
                widget.createNotification(
                  recipientId: recipientId,
                  senderId: senderId,
                  reviewId: reviewId,
                  type: 'COMMENT',
                  message:
                      message, // Message đã được xử lý trong CommentScreen (nếu cần)
                );
              },
        );
      },
    ).then((_) {
      widget.onPostUpdated();
    });
  }

  ImageProvider _getAuthorAvatar() {
    if (widget.post.author.avatarUrl.startsWith('http')) {
      return NetworkImage(widget.post.author.avatarUrl);
    }
    return AssetImage(widget.post.author.avatarUrl);
  }

  // ... (Giữ nguyên _buildImage, _buildPhotoGrid, _buildActionButton, _SaveDialogContent)

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

  // [Build Action Button - Giữ nguyên]
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

  // [Build Method - Giữ nguyên]
  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact(locale: "en_US");

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PersonalProfileScreen(userId: widget.post.authorId),
                    ),
                  );
                },
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
          Text(
            widget.post.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (widget.post.content.isNotEmpty) ...[
            Text(
              widget.post.content,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildPhotoGrid(),
          ),
          const SizedBox(height: 12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nút Like
              _buildActionButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                text: numberFormat.format(_likeCount),
                onPressed: _toggleLike,
                color: _isLiked ? Colors.red : Colors.grey[700],
              ),
              // Nút Comment
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                text: widget.post.commentCount.toString(),
                onPressed: () => _showCommentScreen(context),
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                text: null,
                onPressed: () {},
              ),
              _buildActionButton(
                icon: Icons.card_giftcard_outlined,
                text: null,
                onPressed: () {},
              ),
              _buildActionButton(
                icon: Icons.bookmark_border,
                text: null,
                onPressed: () {}, // Sử dụng _showSaveDialog nếu có
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// 4. SAVE DIALOG (Giữ nguyên logic)
// ===================================================================

class _SaveDialogContent extends StatefulWidget {
  final String userId;
  final String reviewId;
  final String authorId;
  final String? postImageUrl;

  const _SaveDialogContent({
    required this.userId,
    required this.reviewId,
    required this.authorId,
    this.postImageUrl,
  });

  @override
  State<_SaveDialogContent> createState() => _SaveDialogContentState();
}

class _SaveDialogContentState extends State<_SaveDialogContent> {
  Future<void> _showCreateAlbumDialog() async {
    final TextEditingController _albumNameController = TextEditingController();

    final String? newAlbumName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Tạo album mới"),
          content: TextField(
            controller: _albumNameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Nhập tên album..."),
          ),
          actions: [
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text("Tạo"),
              onPressed: () {
                if (_albumNameController.text.trim().isNotEmpty) {
                  Navigator.of(
                    dialogContext,
                  ).pop(_albumNameController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    if (newAlbumName != null && newAlbumName.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('albums')
            .add({
              'title': newAlbumName,
              'description': '',
              'createdAt': FieldValue.serverTimestamp(),
              'photos': [],
            });
        if (mounted) setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Tạo album thất bại: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveBookmark({String? albumId}) async {
    final bool isCreator = (widget.userId == widget.authorId);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('bookmarks')
          .add({
            'reviewID': widget.reviewId,
            'albumId': albumId,
            'addedAt': FieldValue.serverTimestamp(),
            'postImageUrl': widget.postImageUrl,
            'creator': isCreator,
          });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(albumId == null ? "Đã lưu!" : "Đã lưu vào album!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lưu thất bại: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint("Lỗi lưu bookmark: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Lưu vào bộ sưu tập"),
      content: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('albums')
            .orderBy('createdAt', descending: true)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Text("Không thể tải album. Vui lòng thử lại.");
          }
          final albums = snapshot.data?.docs ?? [];

          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: albums.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.add_box_outlined),
                    title: const Text("Tạo album mới..."),
                    onTap: _showCreateAlbumDialog,
                  );
                }
                final albumDoc = albums[index - 1];
                final albumData = albumDoc.data() as Map<String, dynamic>;
                final String albumId = albumDoc.id;
                final String albumTitle =
                    albumData['title'] ?? 'Album không tên';

                return ListTile(
                  leading: const Icon(Icons.photo_album_outlined),
                  title: Text(albumTitle),
                  onTap: () => _saveBookmark(albumId: albumId),
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          child: const Text("Hủy"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text("LƯU (KHÔNG THÊM VÀO ALBUM)"),
          onPressed: () => _saveBookmark(albumId: null),
        ),
      ],
    );
  }
}
