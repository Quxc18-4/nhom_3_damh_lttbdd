// model/post_model.dart

// ⚡️ LƯU Ý: Bạn sẽ cần import 'cloud_firestore'
//
// nếu bạn dùng factory constructor .fromSnapshot
import 'package:cloud_firestore/cloud_firestore.dart'; 

class User {
  final String name;
  final String avatarUrl;

  User({required this.name, required this.avatarUrl});
}

class Post {
  final String id; // <-- TRƯỜNG QUAN TRỌNG
  final String authorId; // <-- TRƯỜNG QUAN TRỌNG
  final User author;
  final String timeAgo;
  final String title;
  final String content;
  final List<String> imageUrls;
  final List<String> tags;
  final int likeCount;
  final int commentCount;

  Post({
    required this.id, // <-- THÊM
    required this.authorId, // <-- THÊM
    required this.author,
    required this.timeAgo,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.tags,
    required this.likeCount,
    required this.commentCount,
  });

  // (Tùy chọn) Factory constructor để build từ Firebase
  // factory Post.fromSnapshot(DocumentSnapshot doc, User authorDetails) { ... }
}

// ======================================================
// === DỮ LIỆU ẢO (GIỮ LẠI THEO YÊU CẦU) ===
// ======================================================
final List<Post> samplePosts = [
  Post(
    id: "review_01_mock", // <-- ID ảo
    authorId: "user_khoai_lang_thang_mock", // <-- ID tác giả ảo
    author:
        User(name: "Khoai Lang Thang", avatarUrl: "assets/images/facebook.png"),
    timeAgo: "1h",
    title: "Du lịch Sài Gòn – Cẩm nang kinh nghiệm từ A đến Z",
    content:
        "Nếu Hà Nội được biết đến là thủ đô ngàn năm văn hiến với vẻ đẹp yên bình,.... xem thêm",
    imageUrls: ["assets/images/logo.png"], // Sửa lại path ảnh của bạn
    tags: ["Blog", "#TPHCM", "#Tự Túc"],
    likeCount: 2103,
    commentCount: 50,
  ),
  Post(
    id: "review_02_mock", // <-- ID ảo
    authorId: "user_khoa_pug_mock", // <-- ID tác giả ảo
    author: User(name: "Khoa Pug", avatarUrl: "assets/images/logo.png"), // Sửa path
    timeAgo: "4h",
    title: "Đà Lạt chào đón tôi bằng không khí se lạnh và những con đèo",
    content:
        "Thành phố mộng mơ, nơi thời gian như chậm lại giữa sương mù và rừng thông xanh.... xem thêm",
    imageUrls: ["assets/images/logo.png", "assets/images/logo.png"], // Sửa path
    tags: ["Review", "#ĐàLạt"],
    likeCount: 8765,
    commentCount: 120,
  ),
];