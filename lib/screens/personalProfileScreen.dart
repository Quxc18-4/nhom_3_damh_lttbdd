import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:nhom_3_damh_lttbdd/screens/accountSettingScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/albumTabContent.dart';
import 'package:nhom_3_damh_lttbdd/screens/introductionTabContent.dart';
import 'package:nhom_3_damh_lttbdd/screens/followingTabContent.dart';

// ===================================================================
// 1. MODEL CLASSES
// ===================================================================

class User {
  final String id;
  final String name;
  final String avatarUrl;

  User({required this.id, required this.name, required this.avatarUrl});

  factory User.empty() => User(
    id: '',
    name: 'Đang tải...',
    avatarUrl: 'assets/images/default_avatar.png',
  );

  factory User.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return User(
      id: doc.id,
      name: data['fullName'] ?? data['name'] ?? 'Người dùng',
      avatarUrl: data['avatarUrl'] ?? 'assets/images/default_avatar.png',
    );
  }
}

class Post {
  final String id;
  final User author;
  final String authorId;
  final String title;
  final String content;
  final String timeAgo;
  final List<String> imageUrls;
  final List<String> tags;
  int likeCount; // ✅ Không final để có thể cập nhật
  final int commentCount;
  bool isLikedByUser; // ✅ Thêm trạng thái like

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
    this.isLikedByUser = false,
  });

  factory Post.fromDoc(
    DocumentSnapshot doc,
    User postAuthor, {
    bool isLiked = false,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
    final DateTime postTime = timestamp.toDate();
    final String formattedTime = DateFormat(
      'dd/MM/yyyy, HH:mm',
    ).format(postTime);

    return Post(
      id: doc.id,
      author: postAuthor,
      authorId: data['userId'] ?? '', // ✅ Sửa từ 'authorId' thành 'userId'
      title: data['title'] ?? 'Không có tiêu đề',
      content: data['comment'] ?? '',
      timeAgo: formattedTime,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['hashtags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      isLikedByUser: isLiked,
    );
  }
}

// ===================================================================
// 2. PERSONAL PROFILE SCREEN
// ===================================================================

class PersonalProfileScreen extends StatefulWidget {
  final String userId;

  const PersonalProfileScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User _currentUser = User.empty();
  List<Post> _myPosts = [];
  bool _isLoading = true;

  bool _isMyProfile = false;
  bool _isFollowing = false;
  bool _isFollowLoading = false; // Để tránh double-tap
  int _followersCount = 0;
  int _followingCount = 0;
  String? _currentAuthUserId; // ID của user đang đăng nhập

  // ✅ Kiểm tra authentication
  bool get _isAuthenticated => auth.FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===================================================================
  // FETCH DATA
  // ===================================================================

  Future<void> _loadProfileData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // 1. Lấy ID user đang đăng nhập
    _currentAuthUserId = auth.FirebaseAuth.instance.currentUser?.uid;
    if (_currentAuthUserId != null) {
      // 2. So sánh để biết đây có phải profile của tôi không
      _isMyProfile = (widget.userId == _currentAuthUserId);
    } else {
      _isMyProfile = false;
    }

    try {
      // 3. Tải thông tin người dùng (profile đang xem)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        _currentUser = User.fromDoc(userDoc);
        final data = userDoc.data() as Map<String, dynamic>? ?? {};

        // 4. Lấy số count từ document, nếu không có thì mặc định là -1
        int followers = data['followersCount'] ?? -1;
        int following = data['followingCount'] ?? -1;

        // 5. Nếu field không tồn tại (== -1), khởi tạo chúng
        if (followers == -1 || following == -1) {
          // Chạy nền, không cần await
          _initializeFollowCounts(userDoc.reference);
          followers = 0; // Set default cho UI ngay lập tức
          following = 0; // Set default cho UI ngay lập tức
        }

        if (mounted) {
          setState(() {
            _followersCount = followers;
            _followingCount = following;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentUser = User(
              id: widget.userId,
              name: "Không tìm thấy",
              avatarUrl: 'assets/images/default_avatar.png',
            );
            _isLoading = false;
          });
          return;
        }
      }

      // 6. Tải bài viết
      await _fetchMyPosts();

      // 7. Tải trạng thái follow (chỉ khi xem trang người khác)
      if (!_isMyProfile) {
        await _fetchFollowStatus();
      }
    } catch (e) {
      print("Lỗi tải dữ liệu Profile: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ HÀM MỚI: Khởi tạo count nếu chưa có
  Future<void> _initializeFollowCounts(DocumentReference userRef) async {
    try {
      // Dùng merge: true để chỉ cập nhật hoặc tạo mới field này
      // mà không ghi đè các field khác
      await userRef.set({
        'followersCount': 0,
        'followingCount': 0,
      }, SetOptions(merge: true));
      print("Initialized follow counts for ${userRef.id}");
    } catch (e) {
      print("Error initializing follow counts: $e");
    }
  }

  // ✅ HÀM MỚI: Chỉ kiểm tra trạng thái follow
  Future<void> _fetchFollowStatus() async {
    if (!_isAuthenticated || _currentAuthUserId == null) return;

    try {
      // Kiểm tra xem user đang đăng nhập có follow profile này không
      final followDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentAuthUserId) // User đang đăng nhập
          .collection('following')
          .doc(widget.userId) // User của trang profile
          .get();

      if (mounted) {
        setState(() {
          _isFollowing = followDoc.exists;
        });
      }
    } catch (e) {
      print("Lỗi tải data follow status: $e");
    }
  }

  Future<void> _fetchMyPosts() async {
    if (!mounted) return;

    try {
      // Lọc bài viết theo userId
      QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Post> fetchedPosts = [];
      final postAuthor = _currentUser.id.isNotEmpty
          ? _currentUser
          : User.empty();

      for (var reviewDoc in reviewSnapshot.docs) {
        // ✅ Kiểm tra trạng thái like (nếu đã đăng nhập)
        bool isLiked = false;
        if (_isAuthenticated) {
          try {
            final likeDoc = await FirebaseFirestore.instance
                .collection('reviews')
                .doc(reviewDoc.id)
                .collection('likes')
                .doc(widget.userId)
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
          _myPosts = fetchedPosts;
        });
      }
    } catch (e) {
      print("Lỗi fetch posts: $e");
    }
  }

  Future<void> _toggleFollow() async {
    // Phải đăng nhập mới cho follow
    if (_currentAuthUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn cần đăng nhập để thực hiện hành động này!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isFollowLoading || _isMyProfile) return;

    setState(() {
      _isFollowLoading = true;
    });

    // Tham chiếu đến 4 vị trí cần cập nhật
    final authUserFollowingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentAuthUserId)
        .collection('following')
        .doc(widget.userId);

    final profileUserFollowerRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .doc(_currentAuthUserId);

    final authUserDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentAuthUserId);
    final profileUserDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);

    try {
      if (_isFollowing) {
        // --- UNFOLLOW ---
        await authUserFollowingRef.delete();
        await profileUserFollowerRef.delete();
        // Cập nhật count
        await authUserDocRef.update({
          'followingCount': FieldValue.increment(-1),
        });
        await profileUserDocRef.update({
          'followersCount': FieldValue.increment(-1),
        });

        if (mounted) {
          setState(() {
            _isFollowing = false;
            _followersCount--; // Cập nhật UI ngay
          });
        }
      } else {
        // --- FOLLOW ---
        final timestamp = FieldValue.serverTimestamp();
        await authUserFollowingRef.set({
          'followedAt': timestamp,
          'userId': widget.userId,
        });
        await profileUserFollowerRef.set({
          'followedAt': timestamp,
          'userId': _currentAuthUserId!,
        });
        // Cập nhật count
        await authUserDocRef.update({
          'followingCount': FieldValue.increment(1),
        });
        await profileUserDocRef.update({
          'followersCount': FieldValue.increment(1),
        });

        if (mounted) {
          setState(() {
            _isFollowing = true;
            _followersCount++; // Cập nhật UI ngay
          });
        }
      }
    } catch (e) {
      print("Lỗi toggle follow: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã xảy ra lỗi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
  }

  // ✅ HÀM MỚI: Widget cho nút Follow/Unfollow
  Widget _buildFollowButton() {
    if (_isFollowLoading) {
      // Hiển thị loading nhỏ
      return const SizedBox(
        width: 110,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange,
            ),
          ),
        ),
      );
    }

    if (_isFollowing) {
      // Nút Hủy Follow (chữ vàng, nền trắng, viền vàng)
      return OutlinedButton(
        onPressed: _toggleFollow,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.orange),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(110, 36),
        ),
        child: const Text('Hủy Follow'),
      );
    } else {
      // Nút Follow (chữ trắng, nền vàng)
      return ElevatedButton(
        onPressed: _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white, // Chữ trắng
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(110, 36),
        ),
        child: const Text('Follow'),
      );
    }
  }
  // ===================================================================
  // BUILD UI
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(child: _buildProfileHeader(_currentUser)),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Dòng thời gian'),
                    Tab(text: 'Giới thiệu'),
                    Tab(text: 'Album'),
                    Tab(text: 'Theo dõi'),
                  ],
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTimelineListView(),
            const IntroductionTabContent(),
            AlbumTabContent(userId: widget.userId), // ✅ Truyền userId
            const FollowingTabContent(),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // WIDGETS
  // ===================================================================

  Widget _buildProfileHeader(User user) {
    ImageProvider _getAvatarProvider() {
      if (user.avatarUrl.startsWith('http')) {
        return NetworkImage(user.avatarUrl);
      }
      return AssetImage(user.avatarUrl);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                // ✅ THAY ĐỔI: Chỉ hiển thị Settings nếu là profile của tôi
                if (_isMyProfile)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AccountSettingScreen(userId: widget.userId),
                        ),
                      );
                    },
                  )
                else
                  // Placeholder để giữ layout, nếu không nút back sẽ bị đẩy vào giữa
                  const SizedBox(width: 48),
              ],
            ),
          ),
          Row(
            children: [
              CircleAvatar(radius: 40, backgroundImage: _getAvatarProvider()),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // ✅ THAY ĐỔI: Cập nhật stats
                    _buildStatColumn("${_myPosts.length}", "Bài viết"),
                    _buildStatColumn("$_followersCount", "Người theo dõi"),
                    _buildStatColumn("$_followingCount", "Đang theo dõi"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ✅ THAY ĐỔI: Hiển thị Tên + Nút Follow (nếu là profile người khác)
          if (!_isMyProfile)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                // ✅ Nút Follow/Unfollow MỚI
                _buildFollowButton(),
              ],
            )
          else
            // ✅ Layout cũ (nếu là profile của tôi)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ✅ THAY ĐỔI: Hiển thị các nút chỉnh sửa (nếu là profile của tôi)
          if (_isMyProfile) ...[
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Chỉnh sửa Travel Map',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text('Viết bài'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Check-in'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTimelineListView() {
    if (_myPosts.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có bài viết nào.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _myPosts.length,
      itemBuilder: (context, index) {
        return TimelinePostCard(
          post: _myPosts[index],
          currentAuthUserId: _currentAuthUserId,
          onPostUpdated: () => _fetchMyPosts(),
        );
      },
    );
  }
}

// ===================================================================
// 3. TIMELINE POST CARD (Stateful để xử lý like)
// ===================================================================

class TimelinePostCard extends StatefulWidget {
  final Post post;
  final String? currentAuthUserId; // User đang đăng nhập
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

  // ✅ Toggle Like/Unlike
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

    setState(() {
      _isProcessing = true;
    });

    final reviewRef = FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.post.id);
    final likeRef = reviewRef.collection('likes').doc(widget.currentAuthUserId);

    try {
      if (_isLiked) {
        // Unlike
        await likeRef.delete();
        await reviewRef.update({'likeCount': FieldValue.increment(-1)});

        if (mounted) {
          setState(() {
            _isLiked = false;
            _likeCount--;
            _isProcessing = false;
          });
        }
      } else {
        // Like
        await likeRef.set({
          'userId': widget.currentAuthUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await reviewRef.update({'likeCount': FieldValue.increment(1)});

        if (mounted) {
          setState(() {
            _isLiked = true;
            _likeCount++;
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
      print("Lỗi toggle like: $e");
    }
  }

  Widget _getPostImage() {
    if (widget.post.imageUrls.isEmpty) return const SizedBox.shrink();
    String imageUrl = widget.post.imageUrls.first;

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
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
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.error_outline, color: Colors.red),
          ),
        ),
      );
    }
    return Image.asset(
      imageUrl,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  ImageProvider _getAuthorAvatar() {
    if (widget.post.author.avatarUrl.startsWith('http')) {
      return NetworkImage(widget.post.author.avatarUrl);
    }
    return AssetImage(widget.post.author.avatarUrl);
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact(locale: "en_US");

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: _getPostImage(),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.tags.isNotEmpty)
                  Text(
                    widget.post.tags.firstWhere(
                      (t) => t.startsWith('#'),
                      orElse: () => "",
                    ),
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  widget.post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: _getAuthorAvatar(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.post.author.name,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                    // ✅ Nút Like với trạng thái động
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
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(numberFormat.format(widget.post.commentCount)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// 4. SLIVER APP BAR DELEGATE
// ===================================================================

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
