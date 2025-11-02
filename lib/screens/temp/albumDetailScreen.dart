// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:nhom_3_damh_lttbdd/screens/postDetailScreen.dart';
// import 'package:image_picker/image_picker.dart'; // ✅ Mới: Dùng để chọn ảnh
// import 'dart:io'; // ✅ Mới
// import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart'; // ✅ Mới

// // ===================================================================
// // MODEL CLASS (Giữ nguyên)
// // ===================================================================

// class SavedReviewItem {
//   final String reviewId;
//   final String title;
//   final String content;
//   final String imageUrl;

//   SavedReviewItem({
//     required this.reviewId,
//     required this.title,
//     required this.content,
//     required this.imageUrl,
//   });

//   factory SavedReviewItem.fromReviewDoc(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return SavedReviewItem(
//       reviewId: doc.id,
//       title: data['title'] ?? 'Không có tiêu đề',
//       content: data['comment'] ?? '',
//       imageUrl: (data['imageUrls'] != null &&
//           (data['imageUrls'] as List).isNotEmpty)
//           ? data['imageUrls'][0]
//           : 'https://via.placeholder.com/300x200.png?text=No+Image',
//     );
//   }
// }

// // ===================================================================
// // ALBUM DETAIL SCREEN
// // ===================================================================

// class AlbumDetailScreen extends StatefulWidget {
//   final String userId;
//   final String albumId;
//   final String albumTitle;

//   const AlbumDetailScreen({
//     Key? key,
//     required this.userId,
//     required this.albumId,
//     required this.albumTitle,
//   }) : super(key: key);

//   @override
//   State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
// }

// class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
//   // --- STATES & SERVICES ---
//   bool _isLoading = true;
//   List<SavedReviewItem> _savedReviews = [];
//   String _albumDescription = '';
//   String? _albumCoverUrl; // URL ảnh bìa chính (có thể là null)
//   final CloudinaryService _cloudinaryService = CloudinaryService();

//   @override
//   void initState() {
//     super.initState();
//     _loadAlbumData();
//   }

//   // ===================================================================
//   // LOAD DATA
//   // ===================================================================

//   Future<void> _loadAlbumData() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // 1. Load thông tin album
//       final albumDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('albums')
//           .doc(widget.albumId)
//           .get();

//       if (albumDoc.exists) {
//         final albumData = albumDoc.data() as Map<String, dynamic>;
//         _albumDescription = albumData['description'] ?? '';
//         // ✅ Lấy ảnh bìa chính
//         _albumCoverUrl = albumData['coverImageUrl'] as String?;
//       }

//       // 2. Load danh sách bookmarks
//       final bookmarksSnap = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('bookmarks')
//           .where('albumId', isEqualTo: widget.albumId)
//           .orderBy('addedAt', descending: true)
//           .get();

//       if (bookmarksSnap.docs.isEmpty) {
//         if (mounted) {
//           setState(() {
//             _savedReviews = [];
//             _isLoading = false;
//           });
//         }
//         return;
//       }

//       // 3. Lấy reviewIds
//       final reviewIds = bookmarksSnap.docs
//           .map((doc) => doc['reviewID'] as String)
//           .toList();

//       // 4. Fetch reviews từ collection 'reviews'
//       final reviewsSnap = await FirebaseFirestore.instance
//           .collection('reviews')
//           .where(FieldPath.documentId, whereIn: reviewIds)
//           .get();

//       // 5. Tạo map và sắp xếp
//       final reviewMap = {
//         for (var doc in reviewsSnap.docs)
//           doc.id: SavedReviewItem.fromReviewDoc(doc)
//       };

//       final List<SavedReviewItem> orderedReviews = [];
//       for (var reviewId in reviewIds) {
//         if (reviewMap.containsKey(reviewId)) {
//           orderedReviews.add(reviewMap[reviewId]!);
//         }
//       }

//       if (mounted) {
//         setState(() {
//           _savedReviews = orderedReviews;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading album data: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Lỗi tải dữ liệu: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // ===================================================================
//   // UI ACTIONS
//   // ===================================================================

//   // ✅ HÀM CẬP NHẬT ẢNH BÌA
//   Future<void> _updateAlbumCover(String imageUrl) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('albums')
//           .doc(widget.albumId)
//           .update({'coverImageUrl': imageUrl});

//       if (mounted) {
//         setState(() {
//           _albumCoverUrl = imageUrl;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Đã cập nhật ảnh bìa!'), backgroundColor: Colors.green),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Lỗi cập nhật ảnh bìa: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }


//   // ✅ HIỂN THỊ DIALOG CHỌN ẢNH BÌA TỪ DANH SÁCH BÀI VIẾT
//   void _showCoverPickerDialog() {
//     if (_savedReviews.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Không có bài viết nào để chọn ảnh bìa.'), backgroundColor: Colors.orange),
//       );
//       return;
//     }

//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Container(
//           height: MediaQuery.of(context).size.height * 0.7,
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               const Text('Chọn ảnh bìa từ bài viết đã lưu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 16),
//               Expanded(
//                 child: GridView.builder(
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 3,
//                     crossAxisSpacing: 8,
//                     mainAxisSpacing: 8,
//                   ),
//                   itemCount: _savedReviews.length,
//                   itemBuilder: (context, index) {
//                     final item = _savedReviews[index];
//                     return InkWell(
//                       onTap: () {
//                         Navigator.pop(context);
//                         _updateAlbumCover(item.imageUrl); // Cập nhật ảnh bìa
//                       },
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.network(
//                           item.imageUrl,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) => Container(
//                             color: Colors.grey[300],
//                             child: const Icon(Icons.broken_image),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _showEditAlbumDialog() async {
//     final TextEditingController titleController =
//     TextEditingController(text: widget.albumTitle);
//     final TextEditingController descController =
//     TextEditingController(text: _albumDescription);

//     final result = await showDialog<Map<String, String>>(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title: const Text("Chỉnh sửa bộ sưu tập"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: titleController,
//                 decoration: const InputDecoration(
//                   labelText: 'Tên bộ sưu tập',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: descController,
//                 maxLines: 3,
//                 decoration: const InputDecoration(
//                   labelText: 'Mô tả',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               child: const Text("Hủy"),
//               onPressed: () => Navigator.of(dialogContext).pop(),
//             ),
//             TextButton(
//               child: const Text("Lưu"),
//               onPressed: () {
//                 Navigator.of(dialogContext).pop({
//                   'title': titleController.text.trim(),
//                   'description': descController.text.trim(),
//                 });
//               },
//             ),
//           ],
//         );
//       },
//     );

//     if (result != null) {
//       try {
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(widget.userId)
//             .collection('albums')
//             .doc(widget.albumId)
//             .update({
//           'title': result['title'],
//           'description': result['description'],
//         });

//         if (mounted) {
//           setState(() {
//             // Cần reload lại dữ liệu để tiêu đề AppBar thay đổi
//             _albumDescription = result['description']!;
//             // Giả định tiêu đề widget.albumTitle không thay đổi trong widget này
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Đã cập nhật bộ sưu tập!'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Lỗi cập nhật: $e'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }
//   }

//   void _deleteAlbum() async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title: const Text("Xóa bộ sưu tập"),
//           content: const Text(
//             "Bạn có chắc chắn muốn xóa bộ sưu tập này?\n\n"
//                 "Lưu ý: Các bài viết sẽ được chuyển về danh sách 'Đã lưu' chính.",
//           ),
//           actions: [
//             TextButton(
//               child: const Text("Hủy"),
//               onPressed: () => Navigator.of(dialogContext).pop(false),
//             ),
//             TextButton(
//               child: const Text("Xóa", style: TextStyle(color: Colors.red)),
//               onPressed: () => Navigator.of(dialogContext).pop(true),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirmed == true) {
//       try {
//         // 1. Chuyển tất cả bookmarks về albumId = null
//         final bookmarksSnap = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(widget.userId)
//             .collection('bookmarks')
//             .where('albumId', isEqualTo: widget.albumId)
//             .get();

//         final batch = FirebaseFirestore.instance.batch();

//         for (var doc in bookmarksSnap.docs) {
//           batch.update(doc.reference, {'albumId': null});
//         }

//         // 2. Xóa album
//         batch.delete(
//           FirebaseFirestore.instance
//               .collection('users')
//               .doc(widget.userId)
//               .collection('albums')
//               .doc(widget.albumId),
//         );

//         await batch.commit();

//         if (mounted) {
//           Navigator.pop(context); // Quay lại màn hình trước
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Đã xóa bộ sưu tập!'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Lỗi xóa: $e'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }
//   }

//   // ===================================================================
//   // BUILD UI
//   // ===================================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           _buildSliverAppBar(),

//           _isLoading
//               ? SliverFillRemaining(
//             child: const Center(
//               child: CircularProgressIndicator(color: Colors.orange),
//             ),
//           )
//               : _savedReviews.isEmpty
//               ? SliverFillRemaining(
//             child: _buildEmptyState(),
//           )
//               : SliverPadding(
//             padding: const EdgeInsets.all(16),
//             sliver: SliverGrid(
//               gridDelegate:
//               const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//                 childAspectRatio: 0.75,
//               ),
//               delegate: SliverChildBuilderDelegate(
//                     (context, index) {
//                   return _buildReviewCard(_savedReviews[index]);
//                 },
//                 childCount: _savedReviews.length,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSliverAppBar() {
//     // ✅ Logic chọn ảnh bìa
//     final String fallbackCoverUrl = _savedReviews.isNotEmpty
//         ? _savedReviews.first.imageUrl // Ảnh đầu tiên của bài viết đầu tiên
//         : 'https://via.placeholder.com/600x400.png?text=Album+Cover';

//     final String coverUrl = _albumCoverUrl ?? fallbackCoverUrl;


//     return SliverAppBar(
//       expandedHeight: 250,
//       pinned: true,
//       backgroundColor: Colors.orange,
//       flexibleSpace: FlexibleSpaceBar(
//         title: Text(
//           widget.albumTitle,
//           style: GoogleFonts.montserrat(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         background: Stack(
//           fit: StackFit.expand,
//           children: [
//             // ✅ HIỂN THỊ ẢNH BÌA (Cover URL hoặc Fallback)
//             Image.network(
//               coverUrl,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) {
//                 return Container(
//                   color: Colors.orange.shade300,
//                   child: const Icon(
//                     Icons.photo_library,
//                     size: 80,
//                     color: Colors.white,
//                   ),
//                 );
//               },
//             ),
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.transparent,
//                     Colors.black.withOpacity(0.7),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         PopupMenuButton<String>(
//           icon: const Icon(Icons.more_vert, color: Colors.white),
//           onSelected: (value) {
//             if (value == 'edit') {
//               _showEditAlbumDialog();
//             } else if (value == 'delete') {
//               _deleteAlbum();
//             } else if (value == 'change_cover') {
//               _showCoverPickerDialog(); // ✅ GỌI DIALOG CHỌN ẢNH BÌA
//             }
//           },
//           itemBuilder: (context) => [
//             const PopupMenuItem(
//               value: 'edit',
//               child: Row(
//                 children: [
//                   Icon(Icons.edit, size: 20),
//                   SizedBox(width: 8),
//                   Text('Chỉnh sửa thông tin'),
//                 ],
//               ),
//             ),
//             const PopupMenuItem(
//               value: 'change_cover', // ✅ THÊM TÙY CHỌN MỚI
//               child: Row(
//                 children: [
//                   Icon(Icons.image, size: 20),
//                   SizedBox(width: 8),
//                   Text('Đổi ảnh bìa'),
//                 ],
//               ),
//             ),
//             const PopupMenuItem(
//               value: 'delete',
//               child: Row(
//                 children: [
//                   Icon(Icons.delete, size: 20, color: Colors.red),
//                   SizedBox(width: 8),
//                   Text('Xóa bộ sưu tập', style: TextStyle(color: Colors.red)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.bookmark_border,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Chưa có bài viết nào',
//             style: GoogleFonts.montserrat(
//               fontSize: 18,
//               color: Colors.grey[600],
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Lưu bài viết vào bộ sưu tập này',
//             style: GoogleFonts.montserrat(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildReviewCard(SavedReviewItem item) {
//     return InkWell(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => PostDetailScreen(reviewId: item.reviewId),
//           ),
//         );
//       },
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.2),
//               spreadRadius: 1,
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image
//             Expanded(
//               flex: 3,
//               child: ClipRRect(
//                 borderRadius:
//                 const BorderRadius.vertical(top: Radius.circular(12)),
//                 child: Image.network(
//                   item.imageUrl,
//                   width: double.infinity,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) => Container(
//                     color: Colors.grey[300],
//                     child: const Center(
//                       child: Icon(Icons.broken_image, size: 40),
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             // Content
//             Expanded(
//               flex: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       item.title,
//                       style: GoogleFonts.montserrat(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const Spacer(),
//                     if (item.content.isNotEmpty)
//                       Text(
//                         item.content,
//                         style: GoogleFonts.montserrat(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Lớp Helper cho SliverAppBar
// class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
//   final TabBar _tabBar;

//   _SliverAppBarDelegate(this._tabBar);

//   @override
//   double get minExtent => _tabBar.preferredSize.height;
//   @override
//   double get maxExtent => _tabBar.preferredSize.height;

//   @override
//   Widget build(
//       BuildContext context,
//       double shrinkOffset,
//       bool overlapsContent,
//       ) {
//     return Container(color: Colors.white, child: _tabBar);
//   }

//   @override
//   bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
//     return false;
//   }
// }
