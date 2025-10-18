import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart'; // Sửa lại đường dẫn file model của bạn
import 'package:nhom_3_damh_lttbdd/screens/personalProfileScreen.dart';

class ExploreScreen extends StatefulWidget {
  // 1. Dòng này của bạn đã đúng
  final String userId;

  // 2. SỬA LẠI CONSTRUCTOR ĐỂ NHẬN userId
  const ExploreScreen({
    Key? key,
    required this.userId, // Thêm 'required this.userId' vào đây
  }) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _posts = samplePosts;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Bỏ appBar ở đây để có toàn quyền kiểm soát trong body
      // appBar: _buildAppBar(),
      body: Column(
        children: [
          // 1. Header tùy chỉnh (nội dung AppBar cũ)
          SafeArea(bottom: false, child: _buildCustomHeader()),

          // 👇 2. KHOẢNG TRỐNG (SIZEBOX) BẠN MUỐN
          const SizedBox(height: 10),

          // 3. Nội dung chính (phải bọc trong Expanded)
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
        onPressed: () {},
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Widget mới chứa toàn bộ nội dung của AppBar cũ
  Widget _buildCustomHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Phần Title và
        SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  // TODO: Thêm logic điều hướng đến trang cá nhân ở đây
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PersonalProfileScreen(userId: widget.userId),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(
                  30,
                ), // Giúp hiệu ứng gợn sóng đẹp hơn
                child: Padding(
                  padding: const EdgeInsets.all(
                    8.0,
                  ), // Thêm padding để vùng bấm lớn hơn một chút
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage("assets/images/logo.png"),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Quoc Danh",
                        style: TextStyle(
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
                icon: Icon(
                  Icons.notifications_none,
                  color: Colors.grey[800],
                  size: 28,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
        // Phần TextField tìm kiếm
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
        // Phần TabBar
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

  ListView _buildPostListView() {
    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          // Giả sử PostCard đã được định nghĩa ở đâu đó trong file
          child: PostCard(post: post),
        );
      },
    );
  }
}

// Widget PostCard không thay đổi
class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({Key? key, required this.post}) : super(key: key);

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
              CircleAvatar(backgroundImage: AssetImage(post.author.avatarUrl)),
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
          Text(post.content, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(post.imageUrls.first, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
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
                Icons.favorite_border,
                numberFormat.format(post.likeCount),
              ),
              _buildActionButton(
                Icons.chat_bubble_outline,
                post.commentCount.toString(),
              ),
              _buildActionButton(Icons.share_outlined, null),
              _buildActionButton(Icons.card_giftcard_outlined, null),
              _buildActionButton(Icons.bookmark_border, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String? text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700], size: 22),
        if (text != null) const SizedBox(width: 4),
        if (text != null) Text(text, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }
}
