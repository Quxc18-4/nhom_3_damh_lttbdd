// File: screens/admin_only/service/admin_service.dart

import 'dart:io'; // Import 'dart:io' để sử dụng lớp 'File' (cho việc upload)
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore, thư viện database chính
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth để xử lý đăng xuất
import 'package:firebase_storage/firebase_storage.dart'; // Import Storage để upload file (ảnh)
import 'package:image_picker/image_picker.dart'; // Import image_picker để lấy ảnh từ máy

// Định nghĩa lớp dịch vụ AdminService
class AdminService {
  // `final`: Các biến này là "bất biến". Chúng được khởi tạo 1 lần
  // khi AdminService được tạo ra và không bao giờ thay đổi.
  // `_` (gạch dưới): Biến là `private`, chỉ dùng được bên trong file này.

  // Instance (thể hiện) của Firestore, dùng để đọc/ghi database
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Instance của Auth, dùng để đăng xuất
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Instance của Storage, dùng để upload/download file
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // Instance của ImagePicker, dùng để gọi camera/gallery
  final ImagePicker _picker = ImagePicker();

  // === PHẦN CHUNG ===

  /// Hàm đăng xuất
  // `Future<void>`: Hàm này là bất đồng bộ (async) và không trả về giá trị gì
  Future<void> signOut() async {
    await _auth.signOut(); // Gọi lệnh đăng xuất của Firebase
  }

  // === PHẦN DUYỆT ĐỊA ĐIỂM (TAB 1) ===

  /// Lấy stream các địa điểm đang chờ duyệt
  // **Giải thích `Stream<QuerySnapshot>` (Rất quan trọng):**
  // - `Future`: Giống như bạn đặt hàng 1 lần và chờ nhận (ví dụ: `.get()`).
  // - `Stream`: Giống như bạn đăng ký nhận tạp chí hàng tháng.
  //   Nó là một "dòng chảy" dữ liệu.
  // Bằng cách dùng `.snapshots()`, chúng ta tạo ra một `Stream`.
  // Bất cứ khi nào dữ liệu trên Firestore (khớp với query) thay đổi
  // (ví dụ: admin khác duyệt 1 địa điểm), `Stream` này sẽ tự động
  // "nhả" ra (emit) một `QuerySnapshot` mới, và UI
  // (được bọc trong `StreamBuilder`) sẽ tự động cập nhật.
  Stream<QuerySnapshot> getPendingPlacesStream() {
    return _firestore
        .collection('placeSubmissions') // 1. Lấy collection "yêu cầu"
        .where(
          'status',
          isEqualTo: 'pending',
        ) // 2. Lọc ra những cái có 'status' là 'pending'
        .orderBy(
          'submittedAt',
          descending: true,
        ) // 3. Sắp xếp, cái mới nhất lên đầu
        .snapshots(); // 4. Trả về 1 Stream (dòng chảy)
  }

  /// Duyệt một địa điểm
  Future<void> approvePlace(
    DocumentSnapshot
    submission, // Nhận vào *toàn bộ* tài liệu (document) của submission
    String adminUserId, // ID của admin đang duyệt
  ) async {
    final String submissionId = submission.id; // Lấy ID của tài liệu submission
    // Lấy data bên trong document, ép kiểu về Map
    final Map<String, dynamic> data = submission.data() as Map<String, dynamic>;
    // Lấy object `placeData` lồng bên trong
    final Map<String, dynamic>? placeData =
        data['placeData'] as Map<String, dynamic>?;

    if (placeData == null) {
      throw Exception('Lỗi: Dữ liệu địa điểm bị thiếu.');
    }

    // **Giải thích `WriteBatch` (Rất quan trọng):**
    // Chúng ta cần thực hiện nhiều thao tác:
    // 1. Cập nhật `placeSubmissions` (status = 'approved').
    // 2. Tạo mới tài liệu trong `places`.
    // 3. (Tùy chọn) Cập nhật `count` trong `categories`.
    // Nếu làm riêng lẻ (`await` từng cái), lỡ như cái 1 thành công
    // mà cái 2 thất bại (ví dụ: mất mạng) -> Dữ liệu sẽ bị "nửa vời"
    // (treo, không nhất quán).
    // `WriteBatch` (Giao dịch hàng loạt) cho phép gom tất cả các
    // lệnh ghi (set, update) vào 1 "lô". Cuối cùng ta gọi `batch.commit()`.
    // 100% các lệnh sẽ cùng thành công, hoặc 100% sẽ cùng thất bại (rollback).
    // Đây gọi là **tính nguyên tử (Atomicity)**.
    WriteBatch batch = _firestore.batch();

    // 1. Cập nhật status trong placeSubmissions
    final submissionRef = _firestore
        .collection('placeSubmissions')
        .doc(submissionId);
    batch.update(submissionRef, {
      'status': 'approved',
    }); // Thêm lệnh (chưa chạy)

    // 2. Tạo document mới trong places
    // Copy dữ liệu từ `placeData` (trong submission)
    // để chuẩn bị ghi vào collection `places`
    final Map<String, dynamic> finalPlaceData = Map<String, dynamic>.from(
      placeData,
    );
    // Bổ sung các thông tin duyệt
    finalPlaceData['approvedBy'] = adminUserId;
    finalPlaceData['createdAt'] =
        FieldValue.serverTimestamp(); // Giờ của server
    finalPlaceData['ratingAverage'] = 0.0; // Khởi tạo rating
    finalPlaceData['reviewCount'] = 0; // Khởi tạo count

    // `.doc()`: Tự động tạo ID mới cho địa điểm
    final newPlaceRef = _firestore.collection('places').doc();
    batch.set(newPlaceRef, finalPlaceData); // Thêm lệnh (chưa chạy)

    // 3. Cập nhật count cho category (nếu có)
    // Code này xử lý cả 2 trường hợp: 'categories' là 1 String
    // hoặc là 1 List<String>
    final categoriesData = placeData['categories'];
    List<String> categoryList = [];
    if (categoriesData is String && categoriesData.isNotEmpty) {
      categoryList = [categoriesData];
    } else if (categoriesData is List) {
      categoryList = categoriesData.map((e) => e.toString()).toList();
    }

    for (final categoryName in categoryList) {
      if (categoryName.isNotEmpty) {
        // Tìm document category BẰNG TÊN
        final categoryQuery = await _firestore
            .collection('categories')
            .where('name', isEqualTo: categoryName)
            .limit(1)
            .get();
        // Nếu tìm thấy
        if (categoryQuery.docs.isNotEmpty) {
          final categoryRef = categoryQuery.docs.first.reference;
          // `FieldValue.increment(1)`: Lệnh nguyên tử của server
          // để cộng 1 vào 'count', tránh race condition.
          batch.update(categoryRef, {'count': FieldValue.increment(1)});
        }
      }
    }

    // **Thực thi tất cả các lệnh đã gom:**
    await batch.commit();
  }

  /// Từ chối một địa điểm
  Future<void> rejectPlace(String submissionId, String adminUserId) async {
    // Tác vụ này đơn giản, chỉ cần 1 lệnh update
    final submissionRef = _firestore
        .collection('placeSubmissions')
        .doc(submissionId);
    await submissionRef.update({
      'status': 'rejected',
      'rejectedBy': adminUserId,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  // === PHẦN QUẢN LÝ BANNER (TAB 2) ===

  /// Lấy stream của tất cả banner
  Stream<QuerySnapshot> getBannersStream() {
    return _firestore
        .collection('banners')
        .orderBy('startDate', descending: true) // Sắp xếp theo ngày bắt đầu
        .snapshots(); // Trả về 1 Stream (live update)
  }

  /// Chọn ảnh từ nguồn
  // `ImageSource` là 1 enum, có thể là `ImageSource.camera`
  // hoặc `ImageSource.gallery`.
  Future<File?> pickImage(ImageSource source) async {
    try {
      // 1. Gọi `image_picker`
      final XFile? pickedFile = await _picker.pickImage(source: source);

      // 2. `XFile` là kiểu dữ liệu "trừu tượng" của picker.
      // Chúng ta cần `File` (từ `dart:io`) để upload.
      if (pickedFile != null) {
        return File(pickedFile.path); // Chuyển đổi XFile -> File
      }
      return null; // Người dùng hủy
    } catch (e) {
      print('Lỗi khi chọn ảnh: $e');
      throw Exception('Lỗi khi chọn ảnh: $e');
    }
  }

  /// Tải ảnh lên Storage
  // `Future<String>`: Hàm `async` trả về URL (dạng String) của ảnh
  Future<String> uploadImage(File imageFile) async {
    // 1. Tạo 1 tên file duy nhất.
    // Dùng `DateTime.now().millisecondsSinceEpoch` (số mili-giây
    // từ 1970) để đảm bảo tên file không bao giờ trùng.
    final String fileName =
        'banners/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

    // 2. Tạo tham chiếu (reference) đến vị trí trên Storage
    final storageRef = _storage.ref().child(fileName);

    // 3. Bắt đầu upload
    final uploadTask = storageRef.putFile(imageFile);

    // 4. `await` cho đến khi upload xong
    final snapshot = await uploadTask.whenComplete(() {});

    // 5. Lấy URL công khai (public URL) của file vừa upload
    return await snapshot.ref.getDownloadURL();
  }

  /// Tạo banner mới
  Future<void> createBanner({
    required String title,
    required String content,
    required int durationDays, // Số ngày hiển thị (7)
    required String imageUrl,
    required String adminUserId,
  }) async {
    // 1. Tính toán ngày bắt đầu và kết thúc
    final now = DateTime.now();
    final startDate = now;
    final endDate = now.add(Duration(days: durationDays));

    // 2. Ghi vào collection 'banners'
    // Dùng `.add()` để Firestore tự tạo document ID
    await _firestore.collection('banners').add({
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'startDate': startDate, // Firestore tự chuyển DateTime -> Timestamp
      'endDate': endDate,
      'createdBy': adminUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Xóa banner
  Future<void> deleteBanner(String bannerId) async {
    // Gọi lệnh `.delete()`
    await _firestore.collection('banners').doc(bannerId).delete();
  }
}
