import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:nhom_3_damh_lttbdd/screens/checkinScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/accountSettingScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/albumTabContent.dart';
import 'package:nhom_3_damh_lttbdd/screens/introductionTabContent.dart';
import 'package:nhom_3_damh_lttbdd/screens/followingTabContent.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';


// ===================================================================
// LƯU Ý: ĐÃ XÓA KHỐI final List<Post> mockPosts KHỎI ĐÂY
// ===================================================================


class PersonalProfileScreen extends StatefulWidget {
  final String userId;

  const PersonalProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User _currentUser = User.empty();
  List<Post> _myPosts = [];
  bool _isLoading = true;

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

    try {
      // 1. Tải thông tin người dùng
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        _currentUser = User.fromDoc(userDoc);
      }

      // 2. Tải bài viết
      await _fetchMyPosts();

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
      final postAuthor = _currentUser.id.isNotEmpty ? _currentUser : User.empty();

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
            AlbumTabContent(userId: widget.userId),
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
                ),
              ],
            ),
          ),

          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _getAvatarProvider(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn("${_myPosts.length}", "Bài viết"),
                    _buildStatColumn("?", "Người theo dõi"),
                    _buildStatColumn("?", "Đang theo dõi"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              user.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

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
        // ✅ GỌI CLASS TimelinePostCard đã được định nghĩa dưới đây
        return TimelinePostCard(
          post: _myPosts[index],
          userId: widget.userId,
          onPostUpdated: () => _fetchMyPosts(),
        );
      },
    );
  }
} // End of _PersonalProfileScreenState

// ===================================================================
// 3. TIMELINE POST CARD (Stateful để xử lý like) - ĐÃ TÁCH RA
// ===================================================================

class TimelinePostCard extends StatefulWidget {
  final Post post;
  final String userId;
  final VoidCallback onPostUpdated; // ✅ Giữ nguyên

  const TimelinePostCard({
    Key? key,
    required this.post,
    required this.userId,
    required this.onPostUpdated,
  }) : super(key: key);

  @override
  State<TimelinePostCard> createState() => _TimelinePostCardState();
}

class _TimelinePostCardState extends State<TimelinePostCard> {
  // Lỗi "The method 'onPostUpdated' isn't defined for the type 'PersonalProfileScreen'"
  // đã được sửa vì nó nằm trong widget, không phải class cha.
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

    setState(() {
      _isProcessing = true;
    });

    final reviewRef = FirebaseFirestore.instance.collection('reviews').doc(widget.post.id);
    final likeRef = reviewRef.collection('likes').doc(widget.userId);

    try {
      if (_isLiked) {
        await likeRef.delete();
        await reviewRef.update({'likeCount': FieldValue.increment(-1)});
      } else {
        await likeRef.set({'createdAt': FieldValue.serverTimestamp()});
        await reviewRef.update({'likeCount': FieldValue.increment(1)});
      }

      // Gọi hàm cập nhật dữ liệu của Profile Screen
      widget.onPostUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
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
          child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
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
} // End of TimelinePostCard


// Lớp Helper để giữ TabBar "dính" lại khi cuộn
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
