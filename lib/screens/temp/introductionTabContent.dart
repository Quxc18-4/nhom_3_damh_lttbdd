// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// // ✅ SỬA 1: Sửa lỗi cú pháp và thêm import cho hàm khởi tạo
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';

// // ✅ SỬA 2: Import model cho đúng
// import 'package:nhom_3_damh_lttbdd/model/post_model.dart';

// class IntroductionTabContent extends StatefulWidget {
//   final Map<String, dynamic>? userData; // Dữ liệu từ userDoc.data()
//   final List<Post> userPosts; // Danh sách bài viết đã tải từ màn hình cha
//   final bool isMyProfile; // Check xem đây có phải profile của tôi không
//   final String userId; // ID của user này

//   const IntroductionTabContent({
//     Key? key,
//     required this.userData,
//     required this.userPosts,
//     required this.isMyProfile,
//     required this.userId,
//   }) : super(key: key);

//   @override
//   State<IntroductionTabContent> createState() => _IntroductionTabContentState();
// }

// class _IntroductionTabContentState extends State<IntroductionTabContent> {
//   bool _isEditingBio = false;
//   late TextEditingController _bioController;
//   bool _isBioLoading = false;

//   // Biến state cho thành tích
//   int _destinationCount = 0;
//   int _postCount = 0;
//   int _totalLikes = 0;
//   int _totalComments = 0;

//   // ✅ SỬA 3: Thêm biến state để kiểm tra locale đã sẵn sàng chưa
//   bool _isLocaleInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     // Khởi tạo bio controller
//     final String currentBio = widget.userData?['bio'] ?? '';
//     _bioController = TextEditingController(text: currentBio);

//     // Xử lý tính toán thành tích
//     _calculateAchievements();

//     // ✅ SỬA 4: Gọi hàm khởi tạo locale
//     _initializeLocale();
//   }

//   // ✅ SỬA 5: Thêm hàm khởi tạo locale
//   Future<void> _initializeLocale() async {
//     try {
//       // Khởi tạo ngôn ngữ 'vi_VN'
//       await initializeDateFormatting('vi_VN');
//     } catch (e) {
//       // Có thể locale đã được khởi tạo ở đâu đó, bỏ qua lỗi
//       print("Lỗi khởi tạo locale (có thể bỏ qua): $e");
//     }

//     if (mounted) {
//       setState(() {
//         _isLocaleInitialized = true;
//       });
//     }
//   }

//   @override
//   void didUpdateWidget(covariant IntroductionTabContent oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Cập nhật bio nếu user data thay đổi (vd: sau khi lưu)
//     if (widget.userData?['bio'] != oldWidget.userData?['bio']) {
//       final String currentBio = widget.userData?['bio'] ?? '';
//       _bioController.text = currentBio;
//     }
//     // Tính toán lại thành tích nếu danh sách bài viết thay đổi
//     if (widget.userPosts != oldWidget.userPosts ||
//         widget.userData != oldWidget.userData) {
//       _calculateAchievements();
//     }
//   }

//   @override
//   void dispose() {
//     _bioController.dispose();
//     super.dispose();
//   }

//   /// Tính toán các chỉ số thành tích từ dữ liệu đã có
//   void _calculateAchievements() {
//     // 1. Đếm điểm đến
//     final List<dynamic> visited = widget.userData?['visitedProvinces'] ?? [];

//     // 2. Đếm bài viết
//     final int posts = widget.userPosts.length;

//     // 3. & 4. Tính tổng like và comment
//     int likes = 0;
//     int comments = 0;
//     for (final post in widget.userPosts) {
//       likes += post.likeCount;
//       comments += post.commentCount;
//     }

//     // Cập nhật state để UI thay đổi
//     // Dùng mounted check để tránh lỗi nếu widget build xong trước khi tính toán
//     if (mounted) {
//       setState(() {
//         _destinationCount = visited.length;
//         _postCount = posts;
//         _totalLikes = likes;
//         _totalComments = comments;
//       });
//     }
//   }

//   /// Lưu bio mới vào Firestore
//   Future<void> _saveBio() async {
//     if (_isBioLoading) return;

//     setState(() {
//       _isBioLoading = true;
//     });

//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .update({'bio': _bioController.text.trim()});

//       if (mounted) {
//         setState(() {
//           _isEditingBio = false;
//           _isBioLoading = false;
//           // Cập nhật lại UI ngay lập tức
//           widget.userData?['bio'] = _bioController.text.trim();
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Cập nhật giới thiệu thành công!"),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isBioLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ✅ SỬA 6: Hiển thị loading cho đến khi locale sẵn sàng
//     if (!_isLocaleInitialized) {
//       return const Center(
//         child: Padding(
//           padding: EdgeInsets.all(32.0),
//           child: CircularProgressIndicator(color: Colors.orange),
//         ),
//       );
//     }

//     // Xử lý dữ liệu để hiển thị
//     final String bio = widget.userData?['bio'] ?? '';
//     final String city = widget.userData?['city'] ?? '';
//     final Timestamp? joinedTimestamp = widget.userData?['joinedAt'];

//     String bioText = bio;
//     if (bio.isEmpty) {
//       bioText = widget.isMyProfile
//           ? "Hãy viết gì đó để mọi người biết tới bạn..."
//           : "Có 1 luồng năng lượng thần bí bao quanh người dùng này";
//     }

//     String cityText = city.isNotEmpty ? city : "Không xác định";

//     String joinedText = "Không rõ";
//     if (joinedTimestamp != null) {
//       // Định dạng ngày: "tháng 3, 2023"
//       // Dòng này giờ đã an toàn để chạy
//       final DateFormat formatter = DateFormat('MMMM, yyyy', 'vi_VN');
//       joinedText = "Tham gia từ ${formatter.format(joinedTimestamp.toDate())}";
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildIntroductionCard(bioText, cityText, joinedText),
//           const SizedBox(height: 24),
//           _buildAchievementsSection(),
//         ],
//       ),
//     );
//   }

//   // --- WIDGETS CON CHO TAB GIỚI THIỆU ---

//   Widget _buildIntroductionCard(
//     String bioText,
//     String cityText,
//     String joinedText,
//   ) {
//     return Card(
//       elevation: 1,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   " ●  Giới thiệu",
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 // Nút chỉnh sửa, chỉ hiển thị cho chủ sở hữu
//                 if (widget.isMyProfile && !_isEditingBio)
//                   IconButton(
//                     icon: const Icon(Icons.edit_outlined, size: 20),
//                     onPressed: () {
//                       setState(() {
//                         _isEditingBio = true;
//                       });
//                     },
//                   ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Hiển thị Text hoặc TextField tùy trạng thái
//             if (_isEditingBio)
//               _buildBioEditor()
//             else
//               Text(
//                 bioText,
//                 style: TextStyle(
//                   height: 1.5,
//                   color:
//                       bioText.startsWith("Hãy viết") ||
//                           bioText.startsWith("Có 1 luồng")
//                       ? Colors.grey
//                       : Colors.black,
//                 ),
//               ),

//             const Divider(height: 24),
//             _buildInfoRow(Icons.location_on_outlined, cityText),
//             const SizedBox(height: 8),
//             _buildInfoRow(Icons.calendar_today_outlined, joinedText),
//             // Đã bỏ dòng "Travel Blogger"
//           ],
//         ),
//       ),
//     );
//   }

//   /// Widget chỉnh sửa Bio
//   Widget _buildBioEditor() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.end,
//       children: [
//         TextField(
//           controller: _bioController,
//           autofocus: true,
//           maxLines: 4,
//           maxLength: 200,
//           decoration: const InputDecoration(
//             hintText: "Viết gì đó về bạn...",
//             border: OutlineInputBorder(),
//             contentPadding: EdgeInsets.all(12),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   _isEditingBio = false;
//                   // Reset text về giá trị cũ
//                   _bioController.text = widget.userData?['bio'] ?? '';
//                 });
//               },
//               child: const Text("Hủy"),
//             ),
//             const SizedBox(width: 8),
//             ElevatedButton(
//               onPressed: _saveBio,
//               child: _isBioLoading
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     )
//                   : const Text("Lưu"),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, color: Colors.grey[600], size: 20),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Text(text, style: TextStyle(color: Colors.grey[800])),
//         ),
//       ],
//     );
//   }

//   Widget _buildAchievementsSection() {
//     // Định dạng số cho đẹp (vd: 1200 -> 1.2K)
//     final NumberFormat compactFormat = NumberFormat.compact(locale: 'en_US');

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Padding(
//           padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
//           child: Text(
//             " ↳  Thành tích",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//         ),
//         GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           mainAxisSpacing: 12,
//           crossAxisSpacing: 12,
//           childAspectRatio: 1.8,
//           children: [
//             _buildStatCard(
//               _destinationCount.toString(),
//               "Điểm đến",
//               Colors.blue.shade50,
//             ),
//             _buildStatCard(
//               _postCount.toString(),
//               "Bài viết",
//               Colors.orange.shade50,
//             ),
//             _buildStatCard(
//               compactFormat.format(_totalLikes),
//               "Lượt thích",
//               Colors.green.shade50,
//             ),
//             _buildStatCard(
//               compactFormat.format(_totalComments),
//               "Bình luận",
//               Colors.purple.shade50,
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard(String value, String label, Color color) {
//     return Card(
//       elevation: 0,
//       color: color,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               value,
//               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 4),
//             Text(label, style: const TextStyle(color: Colors.black54)),
//           ],
//         ),
//       ),
//     );
//   }
// }
