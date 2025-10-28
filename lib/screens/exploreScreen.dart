import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:nhom_3_damh_lttbdd/model/post_model.dart'; // <-- Bỏ import này
import 'package:nhom_3_damh_lttbdd/screens/checkinScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/personalProfileScreen.dart';

// ===================================================================
// 1. ĐỊNH NGHĨA MODEL (Thay thế cho post_model.dart)
// ===================================================================

// Class User (như bạn đã giả định)
class User {
  final String id;
  final String name;
  final String avatarUrl;
  User({required this.id, required this.name, required this.avatarUrl});
  
  factory User.empty() => User(id: '', name: 'Đang tải...', avatarUrl: 'assets/images/default_avatar.png');

  // Factory để tạo User từ Firestore
  factory User.fromDoc(DocumentSnapshot doc) {
     final data = doc.data() as Map<String, dynamic>? ?? {};
     return User(
       id: doc.id,
       name: data['fullName'] ?? data['name'] ?? 'Người dùng',
       avatarUrl: data['avatarUrl'] ?? 'assets/images/default_avatar.png',
     );
  }
}

// Class Post (dựa trên những gì PostCard đang dùng)
class Post {
  final String id;
  final User author;
  final String authorId;
  final String title;
  final String content;
  final String timeAgo;
  final List<String> imageUrls;
  final List<String> tags; // Sẽ đọc từ 'hashtags'
  final int likeCount;
  final int commentCount;

  Post({
    required this.id,
    required this.author,
    required this.authorId,
    required this.title,
    required this.content,
    required this.timeAgo,
    required this.imageUrls,
    required this.tags,
    required this.likeCount,
    required this.commentCount,
  });

  // Factory để tạo Post từ Firestore
  factory Post.fromDoc(DocumentSnapshot doc, User postAuthor) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
    final DateTime postTime = timestamp.toDate();
    
    // Dùng intl để format thời gian
    final String formattedTime = DateFormat('dd/MM/yyyy, HH:mm').format(postTime);

    return Post(
      id: doc.id,
      author: postAuthor, // User object đã fetch
      authorId: data['authorId'] ?? '',
      title: data['title'] ?? 'Không có tiêu đề',
      content: data['comment'] ?? '', // Giả định content lưu trong trường 'comment'
      timeAgo: formattedTime, // Hiển thị thời gian thực
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      
      // SỬA LỖI HASHTAG: Đọc từ 'hashtags' (do checkinScreen lưu là 'hashtags')
      tags: List<String>.from(data['hashtags'] ?? []), 
      
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
    );
  }
}
// ===================================================================
// HẾT PHẦN MODEL
// ===================================================================


class ExploreScreen extends StatefulWidget {
  final String userId;

  const ExploreScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Post> _posts = [];
  bool _isLoading = true;

  String _userName = "Đang tải...";
  String _userAvatarUrl = "assets/images/default_avatar.png";
  bool _isUserDataLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserData();
    _fetchPosts(); // <-- Sẽ gọi hàm _fetchPosts đã sửa
  }

  // Lấy thông tin người dùng từ Firestore (Giữ nguyên)
  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['fullName'] ?? data['name'] ?? 'Người dùng';
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

  // ===================================================================
  // 2. HÀM _fetchPosts (Đã sửa để lấy data thật)
  // ===================================================================
  Future<void> _fetchPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Truy vấn collection 'reviews', sắp xếp theo thời gian mới nhất
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
      
      // 2. Lặp qua từng bài viết (review)
      for (var reviewDoc in reviewSnapshot.docs) {
        final reviewData = reviewDoc.data() as Map<String, dynamic>? ?? {};
        final String? authorId = reviewData['userId'];

        User postAuthor = User.empty(); // Mặc định là 'Đang tải...'

        if (authorId != null && authorId.isNotEmpty) {
          // 3. Lấy thông tin tác giả từ 'users' collection
          try {
            DocumentSnapshot authorDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(authorId)
                .get();

            if (authorDoc.exists) {
              postAuthor = User.fromDoc(authorDoc);
            } else {
              postAuthor = User(id: authorId, name: 'Người dùng đã xóa', avatarUrl: 'assets/images/default_avatar.png');
            }
          } catch (e) {
            print("Lỗi fetch author $authorId: $e");
          }
        }
        
        // 4. Tạo đối tượng Post hoàn chỉnh
        fetchedPosts.add(Post.fromDoc(reviewDoc, postAuthor));
      }

      // 5. Cập nhật UI
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
          SnackBar(content: Text("Lỗi tải bài viết: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Hiển thị modal chọn loại bài viết (Giữ nguyên)
  void _showCreatePostOptions() {
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckinScreen(currentUserId: widget.userId),
                    ),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.camera_alt_outlined,
                label: 'Checkin',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckinScreen(currentUserId: widget.userId),
                    ),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.help_outline,
                label: 'Đặt câu hỏi',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Logic chuyển hướng đến màn hình Đặt câu hỏi
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Helper widget cho các tùy chọn trong Bottom Sheet (Giữ nguyên)
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostListView(widget.userId), // Tab "Đang theo dõi"
                      _buildPostListView(widget.userId), // Tab "Dành cho bạn"
                    ],
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

  // Header với dữ liệu người dùng (Giữ nguyên)
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
                      builder: (context) => PersonalProfileScreen(userId: widget.userId),
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
                          : CircleAvatar(radius: 20, backgroundImage: _getAvatarProvider()),
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
              IconButton(
                icon: Icon(Icons.notifications_none, color: Colors.grey[800], size: 28),
                onPressed: () {},
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

  // ===================================================================
  // 3. SỬA HÀM _buildPostListView (Trả về Widget)
  // ===================================================================
  Widget _buildPostListView(String userId) {
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
          child: PostCard(post: post, userId: userId),
        );
      },
    );
  }
}

// ===================================================================
// 4. POST CARD (Cập nhật để hiển thị ảnh từ network)
// ===================================================================

class PostCard extends StatelessWidget {
  final Post post;
  final String userId;

  const PostCard({
    Key? key,
    required this.post,
    required this.userId,
  }) : super(key: key);

  // Hiển thị dialog lưu bài viết
  void _showSaveDialog(BuildContext context) {
    final String reviewId = post.id;
    final String authorId = post.authorId;
    final String? imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _SaveDialogContent(
          userId: userId,
          reviewId: reviewId,
          authorId: authorId, 
          postImageUrl: imageUrl,
        );
      },
    );
  }

  // Helper lấy avatar
  ImageProvider _getAuthorAvatar() {
    if (post.author.avatarUrl.startsWith('http')) {
      return NetworkImage(post.author.avatarUrl);
    }
    return AssetImage(post.author.avatarUrl); // Dùng asset nếu là default
  }

  // Helper lấy ảnh bài viết
  Widget _getPostImage() {
    if (post.imageUrls.isEmpty) {
      return const SizedBox.shrink(); // Không có ảnh thì không hiển thị gì
    }
    
    String imageUrl = post.imageUrls.first;
    
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl, 
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
           if (loadingProgress == null) return child;
           return Container(
             height: 200,
             color: Colors.grey[200],
             child: Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,)),
           );
        },
        errorBuilder: (context, error, stackTrace) {
           return Container(
             height: 200,
             color: Colors.grey[200],
             child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
           );
        },
      );
    }
    
    return Image.asset(imageUrl, fit: BoxFit.cover);
  }


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
              CircleAvatar(backgroundImage: _getAuthorAvatar()), 
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
              const Spacer(),
              IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (post.content.isNotEmpty) ...[
             Text(post.content, style: TextStyle(color: Colors.grey[700])),
             const SizedBox(height: 12),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _getPostImage(), // <-- Sửa
          ),
          const SizedBox(height: 12),
          // SỬA: Hiển thị tags (đã sửa ở Post.fromDoc)
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
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                icon: Icons.favorite_border,
                text: numberFormat.format(post.likeCount),
                onPressed: () {},
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                text: post.commentCount.toString(),
                onPressed: () {},
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
                onPressed: () => _showSaveDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String? text,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700], size: 22),
            if (text != null) const SizedBox(width: 4),
            if (text != null) Text(text, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// 5. _SaveDialogContent (Giữ nguyên, đã đúng logic)
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
  // Tạo album mới
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
                  Navigator.of(dialogContext).pop(_albumNameController.text.trim());
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
            SnackBar(content: Text("Tạo album thất bại: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Lưu bookmark vào Firestore
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
          SnackBar(content: Text("Lưu thất bại: $e"), backgroundColor: Colors.red),
        );
      }
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
                final String albumTitle = albumData['title'] ?? 'Album không tên';

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