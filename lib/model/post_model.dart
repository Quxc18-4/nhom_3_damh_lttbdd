class User {
  final String name;
  final String avatarUrl;

  User({required this.name, required this.avatarUrl});
}

class Post {
  final User author;
  final String timeAgo;
  final String title;
  final String content;
  final List<String> imageUrls;
  final List<String> tags;
  final int likeCount;
  final int commentCount;

  Post({
    required this.author,
    required this.timeAgo,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.tags,
    required this.likeCount,
    required this.commentCount,
  });
}

// --- DỮ LIỆU GIẢ (SAU NÀY SẼ LẤY TỪ DATABASE) ---

final List<Post> samplePosts = [
  Post(
    author: User(name: "Khoai Lang Thang", avatarUrl: "assets/images/facebook.png"),
    timeAgo: "1h",
    title: "Du lịch Sài Gòn – Cẩm nang kinh nghiệm từ A đến Z",
    content: "Nếu Hà Nội được biết đến là thủ đô ngàn năm văn hiến với vẻ đẹp yên bình,.... xem thêm",
    imageUrls: ["assets/images/logo.png"],
    tags: ["Blog", "#TPHCM", "#Tự Túc"],
    likeCount: 2103, // 2.1k
    commentCount: 50,
  ),
  Post(
    author: User(name: "Khoa Pug", avatarUrl: "assets/images/logo.png"),
    timeAgo: "4h",
    title: "Đà Lạt chào đón tôi bằng không khí se lạnh và những con đèo",
    content: "Thành phố mộng mơ, nơi thời gian như chậm lại giữa sương mù và rừng thông xanh.... xem thêm",
    imageUrls: ["assets/images/logo.png", "assets/images/logo.png"],
    tags: ["Review", "#ĐàLạt"],
    likeCount: 8765, // 8.7k
    commentCount: 120,
  ),
];