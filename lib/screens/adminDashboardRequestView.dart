import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class AdminDashBoardRequestView extends StatefulWidget {
  final String userId; // Giữ lại userId nếu cần cho logging hoặc action khác
  const AdminDashBoardRequestView({Key? key, required this.userId})
    : super(key: key);

  @override
  State<AdminDashBoardRequestView> createState() =>
      _AdminDashBoardRequestViewState();
}

class _AdminDashBoardRequestViewState extends State<AdminDashBoardRequestView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState(); // Luôn gọi hàm này đầu tiên

    // Tự động chạy hàm seed khi Admin vào trang.
    // Vì hàm seedCategories() của bạn đã có logic kiểm tra (query.docs.isEmpty),
    // nên nó sẽ tự động bỏ qua nếu dữ liệu đã tồn tại.
    // Nó sẽ chỉ thêm dữ liệu vào lần đầu tiên trang này được tải.
    //seedCategories();
  }

  // --- Hàm Duyệt ---
  Future<void> _approveSubmission(DocumentSnapshot submission) async {
    final String submissionId = submission.id;
    // Lấy dữ liệu placeData một cách an toàn
    final Map<String, dynamic> data = submission.data() as Map<String, dynamic>;
    final Map<String, dynamic>? placeData =
        data['placeData'] as Map<String, dynamic>?;

    if (placeData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Dữ liệu địa điểm bị thiếu.')),
        );
      }
      return;
    }

    final List<dynamic> categoryIds =
        placeData['categories'] as List<dynamic>? ?? [];

    // Hiển thị loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      WriteBatch batch = _firestore.batch();

      // 1. Cập nhật status trong placeSubmissions
      final submissionRef = _firestore
          .collection('placeSubmissions')
          .doc(submissionId);
      batch.update(submissionRef, {'status': 'approved'});

      // 2. Tạo document mới trong places
      // Chuẩn bị dữ liệu cho collection 'places', bỏ các trường không cần thiết
      final Map<String, dynamic> finalPlaceData = Map<String, dynamic>.from(
        placeData,
      );
      // Bạn có thể thêm/bỏ/sửa đổi các trường ở đây nếu cần
      // Ví dụ: thêm trường 'approvedBy', 'approvedAt'
      // finalPlaceData['approvedBy'] = widget.userId;
      // finalPlaceData['approvedAt'] = FieldValue.serverTimestamp();

      final newPlaceRef = _firestore
          .collection('places')
          .doc(); // Firestore tự tạo ID
      batch.set(newPlaceRef, finalPlaceData);

      for (final categoryId in categoryIds) {
        if (categoryId is String) {
          // Đảm bảo ID là String
          final catRef = _firestore.collection('categories').doc(categoryId);

          // Thêm lệnh update count vào batch
          batch.update(catRef, {'count': FieldValue.increment(1)});
        }
      }

      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop(); // Ẩn loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt yêu cầu thành công!')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Ẩn loading
      print('Lỗi khi duyệt submission $submissionId: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi duyệt yêu cầu: $e')));
      }
    }
  }

  // Future<void> seedCategories() async {
  //   final firestore = FirebaseFirestore.instance;
  //   final categoriesCol = firestore.collection('categories');
  //   print('Bắt đầu quá trình tạo dữ liệu (seed) categories...');

  //   // 1. Danh sách các danh mục bạn muốn thêm
  //   final categoriesToSeed = [
  //     'Ẩm thực',
  //     'Du lịch',
  //     'Check-in',
  //     'Văn hóa',
  //     'Giải trí',
  //     'Cà phê',
  //     'Mua sắm',
  //     'Di tích lịch sử',
  //     'Thiên nhiên',
  //     'View đẹp',
  //     'Mì cay',
  //     'Hải sản',
  //     'Đặc sản vùng miền',
  //     'Quán ăn vặt',
  //     'Nhà hàng sang trọng',
  //     'Quán cà phê sách',
  //     'Quán bar',
  //     'Công viên',
  //     'Bãi biển',
  //     'Núi non',
  //   ];

  //   // 2. Dùng Batch Write để thêm tất cả 1 lúc
  //   final batch = firestore.batch();
  //   int addedCount = 0;

  //   for (final name in categoriesToSeed) {
  //     // 3. Kiểm tra xem tên này đã tồn tại chưa (để tránh chạy nhầm 2 lần)
  //     final query = await categoriesCol
  //         .where('name', isEqualTo: name)
  //         .limit(1)
  //         .get();

  //     if (query.docs.isEmpty) {
  //       // 4. Nếu chưa có, thêm vào batch
  //       final docRef = categoriesCol.doc(); // Tự sinh DocumentID
  //       batch.set(docRef, {
  //         'name': name,
  //         'count': 0, // Khởi tạo count = 0
  //       });
  //       print('  [Thêm vào batch]: $name');
  //       addedCount++;
  //     } else {
  //       print('  [Bỏ qua, đã tồn tại]: $name');
  //     }
  //   }

  //   // 5. Commit batch nếu có gì đó để thêm
  //   if (addedCount > 0) {
  //     await batch.commit();
  //     print('✅ Hoàn tất! Đã thêm $addedCount danh mục mới.');
  //   } else {
  //     print('ℹ️ Không có danh mục nào mới để thêm (tất cả đã tồn tại).');
  //   }
  // }

  // --- Hàm Từ chối ---
  Future<void> _rejectSubmission(String submissionId) async {
    // Hiển thị loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }
    try {
      final submissionRef = _firestore
          .collection('placeSubmissions')
          .doc(submissionId);
      await submissionRef.update({
        'status': 'rejected',
        // Optional: Add a rejection reason field if needed
        // 'rejectionReason': '...',
      });
      if (mounted) Navigator.of(context).pop(); // Ẩn loading
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã từ chối yêu cầu.')));
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Ẩn loading
      print('Lỗi khi từ chối submission $submissionId: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi từ chối yêu cầu: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Duyệt Địa Điểm'),
        // Optional: Add logout button or other admin actions
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lắng nghe các submission có status là 'pending'
        stream: _firestore
            .collection('placeSubmissions')
            .where('status', isEqualTo: 'pending')
            .orderBy(
              'submittedAt',
              descending: true,
            ) // Sắp xếp mới nhất lên đầu
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Không có yêu cầu nào chờ duyệt.'));
          }

          // Hiển thị danh sách các yêu cầu
          final submissions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index];
              // Lấy dữ liệu an toàn hơn với kiểm tra null
              final data = submission.data() as Map<String, dynamic>? ?? {};
              final placeData =
                  data['placeData'] as Map<String, dynamic>? ?? {};
              final location =
                  placeData['location'] as Map<String, dynamic>? ?? {};
              final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();
              final submittedBy = data['submittedBy'] as String?;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 2,
                child: Padding(
                  // Thêm Padding để nội dung không sát viền Card
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placeData['name']?.isNotEmpty == true
                            ? placeData['name']
                            : 'Chưa có tên',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(location['fullAddress'] ?? 'Chưa có địa chỉ'),
                      const SizedBox(height: 4),
                      if (submittedAt != null)
                        Text(
                          'Gửi lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(submittedAt)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      if (submittedBy != null)
                        Text(
                          'Người gửi ID: $submittedBy',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      // TODO: Hiển thị thêm mô tả, ảnh thumbnail...
                      // if (placeData['description']?.isNotEmpty == true) ...[
                      //   const SizedBox(height: 4),
                      //   Text('Mô tả: ${placeData['description']}', maxLines: 2, overflow: TextOverflow.ellipsis),
                      // ],

                      // Hàng chứa nút Duyệt/Từ chối
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 20,
                            ),
                            label: const Text(
                              'Duyệt',
                              style: TextStyle(color: Colors.green),
                            ),
                            onPressed: () => _approveSubmission(submission),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: Colors.red,
                              size: 20,
                            ),
                            label: const Text(
                              'Từ chối',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () => _rejectSubmission(submission.id),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          // TODO: Thêm nút Edit nếu muốn
                        ],
                      ),
                    ],
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
