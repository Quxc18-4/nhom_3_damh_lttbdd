// File: screens/admin_only/widget/place_approval_widgets.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import để format ngày giờ

/// Widget hiển thị danh sách các địa điểm chờ duyệt
// `StatelessWidget`: Vì nó không tự quản lý state.
// State của nó (danh sách địa điểm) được quản lý
// bởi `StreamBuilder` bên trong.
class PendingPlacesList extends StatelessWidget {
  // `final`: Các thuộc tính này được truyền từ
  // `AdminDashBoardRequestView` vào.

  // 1. Dữ liệu (Stream)
  final Stream<QuerySnapshot> stream;

  // 2. Các hàm Callback (hàm của cha)
  final Function(DocumentSnapshot) onApprove;
  final Function(String) onReject;

  const PendingPlacesList({
    Key? key,
    required this.stream,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // **Giải thích `StreamBuilder` (Widget quan trọng nhất):**
    // Nó "lắng nghe" `stream` được cung cấp.
    // Hàm `builder` của nó được gọi lại *mỗi khi*:
    // 1. `stream` đang kết nối (ConnectionState.waiting).
    // 2. `stream` ném ra lỗi (snapshot.hasError).
    // 3. `stream` gửi dữ liệu mới (snapshot.hasData).
    return StreamBuilder<QuerySnapshot>(
      stream: stream, // Lắng nghe stream này
      builder: (context, snapshot) {
        // 1. Đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // 2. Có lỗi
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        // 3. Không có dữ liệu (list rỗng)
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Không có địa điểm nào chờ duyệt.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        // 4. Có dữ liệu
        // `snapshot.data!.docs`: Là một `List<DocumentSnapshot>`
        final submissions = snapshot.data!.docs;

        // Hiển thị 1 `ListView`
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final submission = submissions[index];
            // Với mỗi `submission`, tạo 1 `PlaceSubmissionCard`
            return PlaceSubmissionCard(
              submission: submission,
              // **Truyền Callback:**
              // "Khi nút Approve trên Card được bấm (`onApprove`)..."
              onApprove: () => onApprove(
                submission,
              ), // "...hãy gọi hàm `onApprove` (của cha) với `submission` này"
              onReject: () => onReject(submission.id),
            );
          },
        );
      },
    );
  }
}

/// Widget hiển thị thẻ của một địa điểm chờ duyệt
// `StatelessWidget` vì nó không tự quản lý state.
class PlaceSubmissionCard extends StatelessWidget {
  final DocumentSnapshot submission; // Nhận 1 document
  final VoidCallback onApprove; // Nhận 1 hàm (không tham số)
  final VoidCallback onReject; // Nhận 1 hàm (không tham số)

  const PlaceSubmissionCard({
    Key? key,
    required this.submission,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // **Trích xuất dữ liệu (Data Extraction) an toàn:**
    // `as Map<String, dynamic>? ?? {}`:
    // 1. `as Map<String, dynamic>?`: Ép kiểu (cast) dữ liệu
    //    thành Map (có thể `null`).
    // 2. `?? {}`: Nếu nó `null`, hãy dùng 1 Map rỗng (`{}`).
    // Kỹ thuật này giúp code không bao giờ crash
    // ngay cả khi `submission.data()` là `null`.
    final data = submission.data() as Map<String, dynamic>? ?? {};
    final placeData = data['placeData'] as Map<String, dynamic>? ?? {};
    final location = placeData['location'] as Map<String, dynamic>? ?? {};

    // `?? 'Chưa có tên'`: Cung cấp giá trị mặc định
    // nếu trường (field) đó là `null` trong database.
    final name = placeData['name'] ?? 'Chưa có tên';
    final fullAddress = location['fullAddress'] ?? 'Chưa có địa chỉ';
    final description = placeData['description'] ?? '';

    // `(data['submittedAt'] as Timestamp?)?.toDate()`:
    // 1. `as Timestamp?`: Ép kiểu thành `Timestamp` (có thể `null`).
    // 2. `?` (Null-aware operator): Nếu `Timestamp` không `null`,
    //    thì gọi hàm `.toDate()` (để chuyển thành `DateTime`).
    //    Nếu `null`, toàn bộ biểu thức trả về `null`.
    final createdDate = (data['submittedAt'] as Timestamp?)?.toDate();

    // Logic lấy ảnh (xử lý 2 kiểu dữ liệu)
    String? imageUrl;
    final images = placeData['images'];
    if (images is List && images.isNotEmpty) {
      imageUrl = images[0] as String?; // Lấy ảnh đầu tiên nếu là List
    } else if (images is Map && images.isNotEmpty) {
      imageUrl = images.values.first as String?; // Lấy ảnh đầu tiên nếu là Map
    }

    // Giao diện của Card
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị ảnh (nếu có)
          if (imageUrl != null)
            ClipRRect(
              // Cắt bo góc trên
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                // Tải ảnh từ URL
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                // `errorBuilder`: Hiển thị nếu URL ảnh bị lỗi
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 60),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis, // Hiển thị '...' nếu quá dài
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        fullAddress,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                if (createdDate != null)
                  Text(
                    // `intl`: Dùng `DateFormat` để
                    // format `DateTime` thành `String` dễ đọc
                    'Gửi lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(createdDate)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                const Divider(height: 20),
                // Hàng chứa 2 nút
                Row(
                  mainAxisAlignment: MainAxisAlignment.end, // Đẩy về bên phải
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: onReject, // Gọi callback `onReject`
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onApprove, // Gọi callback `onApprove`
                    ),
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
