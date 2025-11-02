// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_fonts/google_fonts.dart';

// // [IMPORTS BẮT BUỘC] Tái sử dụng các Models và Enum từ SavedScreen
// import 'package:nhom_3_damh_lttbdd/screens/save_screen/saved_screen.dart';
// import 'package:nhom_3_damh_lttbdd/screens/postDetailScreen.dart';
// import 'package:nhom_3_damh_lttbdd/screens/albumDetailScreen.dart';
// import 'package:nhom_3_damh_lttbdd/model/post_model.dart'; // Import User model
// import 'package:nhom_3_damh_lttbdd/model/saved_models.dart';

// // =========================================================================
// // 1. ALL SAVED ITEMS SCREEN (Danh sách đầy đủ + Lọc)
// // =========================================================================

// class AllSavedItemsScreen extends StatefulWidget {
//   // UserId là bắt buộc để fetch data
//   final String userId;

//   const AllSavedItemsScreen({Key? key, required this.userId}) : super(key: key);

//   @override
//   State<AllSavedItemsScreen> createState() => _AllSavedItemsScreenState();
// }

// class _AllSavedItemsScreenState extends State<AllSavedItemsScreen> {
//   SavedCategory _selectedCategory = SavedCategory.all;

//   // Futures
//   late Future<List<SavedItem>> _fullItemsFuture;

//   // Cache data chi tiết của Review/Place để tránh fetch lặp lại
//   final Map<String, dynamic> _contentCache = {};
//   // Cache Tên Category từ Firestore
//   final Map<String, String> _categoryNameCache = {};
//   // Cache Tên Tác giả (dùng ID)
//   final Map<String, String> _authorNameCache = {};

//   // Danh sách các category để hiển thị thanh lọc
//   final List<SavedCategory> _categories = [
//     SavedCategory.all,
//     SavedCategory.review,
//     SavedCategory.place,
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _fetchCategories();
//     _fetchFullSavedItems(); // Tải toàn bộ items
//   }

//   // --- HELPER FETCH FUNCTIONS ---

//   // Cần hàm này để hiển thị tên Category cho Place
//   Future<void> _fetchCategories() async {
//     try {
//       final categorySnap = await FirebaseFirestore.instance
//           .collection('categories')
//           .get();
//       if (mounted) {
//         for (var doc in categorySnap.docs) {
//           _categoryNameCache[doc.id] = doc['name'] ?? 'Không tên';
//         }
//         _fetchFullSavedItems();
//       }
//     } catch (e) {
//       debugPrint("Lỗi tải categories: $e");
//     }
//   }

//   // Fetch tên tác giả (name ?? fullName)
//   Future<String> _fetchAuthorName(String userId) async {
//     if (_authorNameCache.containsKey(userId)) {
//       return _authorNameCache[userId]!;
//     }

//     try {
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .get();
//       if (userDoc.exists) {
//         final data = userDoc.data() as Map<String, dynamic>;
//         final userName = data['name'] ?? data['fullName'] ?? 'Người dùng';
//         _authorNameCache[userId] = userName;
//         return userName;
//       }
//     } catch (e) {
//       debugPrint("Lỗi fetch author name: $e");
//     }
//     return "Người dùng ẩn danh";
//   }

//   // --- LOGIC TRUY VẤN TẤT CẢ ITEMS ---

//   void _fetchFullSavedItems() {
//     setState(() {
//       _fullItemsFuture = _loadAllItems();
//     });
//   }

//   Future<List<SavedItem>> _loadAllItems() async {
//     final bookmarksRef = FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.userId)
//         .collection('bookmarks')
//         .where('albumId', isEqualTo: null)
//         .orderBy('addedAt', descending: true);

//     final itemsSnap = await bookmarksRef.get();

//     List<Future<SavedItem?>> itemFutures = itemsSnap.docs.map((
//       bookmarkDoc,
//     ) async {
//       final bookmarkData = bookmarkDoc.data();
//       final reviewId = bookmarkData['reviewID'] as String?;
//       final placeId = bookmarkData['placeID'] as String?;

//       String contentId = reviewId ?? placeId ?? '';
//       SavedCategory category;

//       if (reviewId != null) {
//         category = SavedCategory.review;
//       } else if (placeId != null) {
//         category = SavedCategory.place;
//       } else {
//         return null;
//       }

//       // Cache check: Content
//       if (!_contentCache.containsKey(contentId)) {
//         final collection = reviewId != null ? 'reviews' : 'places';
//         final docSnap = await FirebaseFirestore.instance
//             .collection(collection)
//             .doc(contentId)
//             .get();
//         if (docSnap.exists) {
//           _contentCache[contentId] = docSnap.data()!;
//         } else {
//           return null;
//         }
//       }

//       final contentData = _contentCache[contentId]!;

//       // Xử lý thông tin hiển thị
//       String title;
//       String authorOrRating;
//       String location;
//       String imageUrl =
//           bookmarkData['postImageUrl'] ??
//           'https://via.placeholder.com/180x160.png?text=No+Image';

//       if (category == SavedCategory.review) {
//         title = contentData['title'] ?? 'Bài viết không tên';
//         // 🆕 FETCH VÀ SỬ DỤNG TÊN TÁC GIẢ THAY CHO ID
//         final authorId = contentData['userId'] ?? '';
//         authorOrRating = await _fetchAuthorName(authorId);
//         location = contentData['placeName'] ?? 'Không rõ địa điểm';
//       } else {
//         // Category.place
//         title = contentData['name'] ?? 'Địa điểm không tên';

//         final placeCategoryIds =
//             (contentData['categories'] as List<dynamic>?)
//                 ?.map((c) => c['id'])
//                 .toList() ??
//             [];
//         final primaryCategory = placeCategoryIds.isNotEmpty
//             ? (_categoryNameCache[placeCategoryIds.first] ?? 'Địa điểm')
//             : 'Địa điểm';
//         authorOrRating = contentData['ratingAverage'] != null
//             ? '${contentData['ratingAverage'].toStringAsFixed(1)}/5 sao'
//             : primaryCategory;

//         final locationData = contentData['location'] as Map<String, dynamic>?;
//         location =
//             locationData?['fullAddress'] ??
//             contentData['locationName'] ??
//             'Không rõ địa điểm';

//         if (!bookmarkData.containsKey('postImageUrl') ||
//             bookmarkData['postImageUrl'] == null) {
//           final placeImages = (contentData['images'] as List<dynamic>?) ?? [];
//           if (placeImages.isNotEmpty && placeImages.first is Map) {
//             imageUrl = placeImages.first['url'] ?? imageUrl;
//           } else if (placeImages.isNotEmpty && placeImages.first is String) {
//             imageUrl = placeImages.first;
//           }
//         }
//       }

//       return SavedItem.fromBookmarkDoc(
//         bookmarkDoc,
//         contentId: contentId,
//         title: title,
//         subtitle: authorOrRating,
//         category: category,
//         imageUrl: imageUrl,
//         authorOrRating: authorOrRating,
//         location: location,
//       );
//     }).toList();

//     // Lọc bỏ các mục null (lỗi fetch hoặc item gốc không tồn tại)
//     final List<SavedItem> rawItems = (await Future.wait(
//       itemFutures,
//     )).whereType<SavedItem>().toList();

//     return rawItems;
//   }

//   // Lấy danh sách mục đã lưu dựa trên category được chọn
//   List<SavedItem> _getFilteredItems(List<SavedItem> allItems) {
//     if (_selectedCategory == SavedCategory.all) {
//       return allItems;
//     }
//     return allItems
//         .where((item) => item.category == _selectedCategory)
//         .toList();
//   }

//   // --- HÀM CHUYỂN HƯỚNG ---
//   void _navigateToContentDetail(SavedItem item) {
//     if (item.category == SavedCategory.review) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => PostDetailScreen(reviewId: item.contentId),
//         ),
//       ).then((_) => _fetchFullSavedItems());
//     } else if (item.category == SavedCategory.place) {
//       // TODO: Điều hướng đến màn hình chi tiết Địa điểm (PlaceDetailScreen)
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Chuyển đến chi tiết Địa điểm (PlaceDetailScreen)'),
//         ),
//       );
//     }
//   }

//   void _showItemActionsSheet(SavedItem item) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text('Mở hành động cho: ${item.title}')));
//   }

//   // =========================================================================
//   // 2. UI
//   // =========================================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Các sản phẩm đã lưu',
//           style: GoogleFonts.montserrat(
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // --- THANH LỌC (FILTERS) ---
//           _buildFilterChips(),

//           // --- DANH SÁCH MỤC ĐÃ LƯU ---
//           Expanded(
//             child: FutureBuilder<List<SavedItem>>(
//               future: _fullItemsFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Center(
//                     child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
//                   );
//                 }

//                 // Lấy data an toàn từ snapshot
//                 final allItems = snapshot.data ?? [];
//                 // Lọc dữ liệu
//                 final items = _getFilteredItems(allItems);

//                 if (items.isEmpty) {
//                   return Center(
//                     child: Text(
//                       'Không có mục đã lưu nào trong danh mục này.',
//                       style: GoogleFonts.montserrat(color: Colors.grey),
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   padding: const EdgeInsets.only(top: 8, bottom: 8),
//                   itemCount: items.length,
//                   itemBuilder: (context, index) {
//                     final item = items[index];
//                     return _buildSavedItemCard(item);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Widget: Thanh lọc ngang
//   Widget _buildFilterChips() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12.0),
//       child: SizedBox(
//         height: 40,
//         child: ListView.builder(
//           scrollDirection: Axis.horizontal,
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           itemCount: _categories.length,
//           itemBuilder: (context, index) {
//             final category = _categories[index];
//             final isSelected = category == _selectedCategory;

//             return Padding(
//               padding: const EdgeInsets.only(right: 8.0),
//               child: ActionChip(
//                 label: Text(
//                   categoryToVietnamese(category), // Sử dụng hàm đã định nghĩa
//                   style: GoogleFonts.montserrat(
//                     fontWeight: FontWeight.w600,
//                     color: isSelected ? Colors.white : Colors.black87,
//                     fontSize: 14,
//                   ),
//                 ),
//                 backgroundColor: isSelected
//                     ? Colors.orange.shade600
//                     : Colors.grey.shade200,
//                 onPressed: () {
//                   setState(() {
//                     _selectedCategory = category;
//                   });
//                 },
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                   side: BorderSide(
//                     color: isSelected
//                         ? Colors.orange.shade600!
//                         : Colors.grey.shade300,
//                   ),
//                 ),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   // Widget: Thẻ hiển thị một mục đã lưu (Tái sử dụng code từ SavedScreen)
//   Widget _buildSavedItemCard(SavedItem item) {
//     bool isReview = item.category == SavedCategory.review;

//     return InkWell(
//       onTap: () => _navigateToContentDetail(item),
//       onLongPress: () => _showItemActionsSheet(item),
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade200),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               spreadRadius: 1,
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // --- ẢNH ITEM ---
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Stack(
//                     children: [
//                       Image.network(
//                         item.imageUrl,
//                         width: 80,
//                         height: 80,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) => Container(
//                           width: 80,
//                           height: 80,
//                           color: Colors.grey[300],
//                           child: const Center(child: Icon(Icons.broken_image)),
//                         ),
//                       ),
//                       // --- CHIP Category ---
//                       Positioned(
//                         top: 4,
//                         left: 4,
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: isReview
//                                 ? Colors.lightBlue.shade700
//                                 : Colors.orange.shade600,
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: Text(
//                             categoryToVietnamese(item.category),
//                             style: GoogleFonts.montserrat(
//                               color: Colors.white,
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 12),

//                 // --- THÔNG TIN & TIÊU ĐỀ ---
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               item.title,
//                               style: GoogleFonts.montserrat(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           // Menu 3 chấm
//                           IconButton(
//                             onPressed: () => _showItemActionsSheet(item),
//                             icon: const Icon(
//                               Icons.more_vert,
//                               color: Colors.grey,
//                             ),
//                             padding: EdgeInsets.zero,
//                             constraints: const BoxConstraints(),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),

//                       // Rating/Author
//                       if (item.category == SavedCategory.review)
//                         Row(
//                           children: [
//                             const Icon(
//                               Icons.person_pin,
//                               size: 16,
//                               color: Colors.black54,
//                             ),
//                             const SizedBox(width: 4),
//                             // 🆕 SỬ DỤNG authorOrRating (Tên tác giả đã được fetch)
//                             Expanded(
//                               // 🆕 Thêm Expanded để tránh overflow
//                               child: Text(
//                                 item.authorOrRating,
//                                 style: GoogleFonts.montserrat(
//                                   fontSize: 12,
//                                   color: Colors.black,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                                 maxLines: 1, // 🆕 Giới hạn 1 dòng
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ],
//                         )
//                       else
//                         Text(
//                           item.authorOrRating, // Rating/Category
//                           style: GoogleFonts.montserrat(
//                             fontSize: 12,
//                             color: Colors.grey.shade700,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),

//                       const SizedBox(height: 4),

//                       // Location
//                       if (item.category == SavedCategory.place)
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.location_on,
//                               size: 14,
//                               color: Colors.red.shade400,
//                             ),
//                             const SizedBox(width: 4),
//                             Expanded(
//                               child: Text(
//                                 item.location,
//                                 style: GoogleFonts.montserrat(
//                                   fontSize: 12,
//                                   color: Colors.grey.shade600,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ],
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
