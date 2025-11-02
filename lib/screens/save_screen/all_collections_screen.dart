import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/model/saved_models.dart'; // Dùng model Album để ánh xạ dữ liệu Firestore

/// -------------------------
/// MÀN HÌNH: HIỂN THỊ TẤT CẢ CÁC BỘ SƯU TẬP (ALBUMS)
/// -------------------------
class AllCollectionsScreen extends StatefulWidget {
  const AllCollectionsScreen({Key? key}) : super(key: key);

  @override
  State<AllCollectionsScreen> createState() => _AllCollectionsScreenState();
}

class _AllCollectionsScreenState extends State<AllCollectionsScreen> {
  // Khởi tạo Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ==============================
  /// HÀM TẠO MỚI MỘT BỘ SƯU TẬP (ALBUM)
  /// ==============================
  Future<void> _createNewCollection(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    // Hiển thị hộp thoại nhập thông tin album mới
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo Bộ sưu tập mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tên bộ sưu tập'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
          ],
        ),
        actions: [
          // Nút hủy
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          // Nút tạo
          ElevatedButton(
            onPressed: () async {
              // Kiểm tra tên trống thì không lưu
              if (titleController.text.trim().isEmpty) return;

              // Thêm dữ liệu vào Firestore collection "albums"
              await _firestore.collection('albums').add({
                'title': titleController.text.trim(), // Tên album
                'description': descriptionController.text.trim(), // Mô tả
                'photos': [], // Danh sách ảnh (để trống ban đầu)
                'reviewCount': 0, // Số lượng bài viết
                'coverImageUrl': '', // Ảnh bìa (tạm trống)
                'createdAt': FieldValue.serverTimestamp(), // Thời điểm tạo
              });

              // Đóng hộp thoại sau khi tạo
              Navigator.pop(context);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  /// ==============================
  /// HÀM XÂY DỰNG GIAO DIỆN CHÍNH
  /// ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả Bộ sưu tập'),
        backgroundColor: Colors.green,
      ),

      // Lắng nghe realtime dữ liệu từ Firestore (collection: albums)
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('albums')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Trạng thái đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Lấy dữ liệu
          final docs = snapshot.data?.docs ?? [];

          // Map dữ liệu Firestore → model Album (được định nghĩa trong saved_models.dart)
          final collections = docs.map((doc) => Album.fromDoc(doc)).toList();

          // Hiển thị dạng lưới (2 cột)
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cột
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9, // Tỷ lệ khung
            ),
            // +1 là để thêm ô “Tạo mới”
            itemCount: collections.length + 1,
            itemBuilder: (context, index) {
              // Ô đầu tiên là nút tạo album mới
              if (index == 0) {
                return GestureDetector(
                  onTap: () => _createNewCollection(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.green, size: 40),
                    ),
                  ),
                );
              }

              // Lấy dữ liệu album
              final album = collections[index - 1];

              // Ô hiển thị album
              return GestureDetector(
                onTap: () {
                  // Tạm thời chỉ hiển thị thông báo (sau có thể chuyển sang màn hình chi tiết album)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mở album: ${album.title}')),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    // Hiển thị ảnh bìa album (nếu có)
                    image: DecorationImage(
                      image: album.coverImageUrl.isNotEmpty
                          ? NetworkImage(album.coverImageUrl)
                          : const AssetImage('assets/images/default_cover.jpg')
                                as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(8),

                  // Khung chứa tiêu đề và số lượng bài viết
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black45, // Nền mờ đen để dễ đọc chữ
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên album
                        Text(
                          album.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Hiển thị số bài viết nếu có
                        if (album.reviewCount > 0)
                          Text(
                            '${album.reviewCount} bài viết',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
