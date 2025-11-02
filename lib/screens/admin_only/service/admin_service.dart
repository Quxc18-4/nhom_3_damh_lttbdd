// File: screens/admin_only/service/admin_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // === PHẦN CHUNG ===

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // === PHẦN DUYỆT ĐỊA ĐIỂM (TAB 1) ===

  /// Lấy stream các địa điểm đang chờ duyệt
  Stream<QuerySnapshot> getPendingPlacesStream() {
    return _firestore
        .collection('placeSubmissions')
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  /// Duyệt một địa điểm
  Future<void> approvePlace(
    DocumentSnapshot submission,
    String adminUserId,
  ) async {
    final String submissionId = submission.id;
    final Map<String, dynamic> data = submission.data() as Map<String, dynamic>;
    final Map<String, dynamic>? placeData =
        data['placeData'] as Map<String, dynamic>?;

    if (placeData == null) {
      throw Exception('Lỗi: Dữ liệu địa điểm bị thiếu.');
    }

    WriteBatch batch = _firestore.batch();

    // 1. Cập nhật status trong placeSubmissions
    final submissionRef = _firestore
        .collection('placeSubmissions')
        .doc(submissionId);
    batch.update(submissionRef, {'status': 'approved'});

    // 2. Tạo document mới trong places
    final Map<String, dynamic> finalPlaceData = Map<String, dynamic>.from(
      placeData,
    );
    finalPlaceData['approvedBy'] = adminUserId;
    finalPlaceData['createdAt'] = FieldValue.serverTimestamp();
    finalPlaceData['ratingAverage'] = 0.0;
    finalPlaceData['reviewCount'] = 0;

    final newPlaceRef = _firestore.collection('places').doc();
    batch.set(newPlaceRef, finalPlaceData);

    // 3. Cập nhật count cho category (nếu có)
    final categoriesData = placeData['categories'];
    List<String> categoryList = [];
    if (categoriesData is String && categoriesData.isNotEmpty) {
      categoryList = [categoriesData];
    } else if (categoriesData is List) {
      categoryList = categoriesData.map((e) => e.toString()).toList();
    }

    for (final categoryName in categoryList) {
      if (categoryName.isNotEmpty) {
        final categoryQuery = await _firestore
            .collection('categories')
            .where('name', isEqualTo: categoryName)
            .limit(1)
            .get();
        if (categoryQuery.docs.isNotEmpty) {
          final categoryRef = categoryQuery.docs.first.reference;
          batch.update(categoryRef, {'count': FieldValue.increment(1)});
        }
      }
    }

    await batch.commit();
  }

  /// Từ chối một địa điểm
  Future<void> rejectPlace(String submissionId, String adminUserId) async {
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
        .orderBy('startDate', descending: true)
        .snapshots();
  }

  /// Chọn ảnh từ nguồn
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Lỗi khi chọn ảnh: $e');
      throw Exception('Lỗi khi chọn ảnh: $e');
    }
  }

  /// Tải ảnh lên Storage
  Future<String> uploadImage(File imageFile) async {
    final String fileName =
        'banners/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
    final storageRef = _storage.ref().child(fileName);
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  /// Tạo banner mới
  Future<void> createBanner({
    required String title,
    required String content,
    required int durationDays,
    required String imageUrl,
    required String adminUserId,
  }) async {
    final now = DateTime.now();
    final startDate = now;
    final endDate = now.add(Duration(days: durationDays));

    await _firestore.collection('banners').add({
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'startDate': startDate,
      'endDate': endDate,
      'createdBy': adminUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Xóa banner
  Future<void> deleteBanner(String bannerId) async {
    await _firestore.collection('banners').doc(bannerId).delete();
  }
}
