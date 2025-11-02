// File: screens/user_setting/account_setting/service/account_setting_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
// Cập nhật đường dẫn này
import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart';

class AccountSettingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// Tải dữ liệu người dùng
  Future<DocumentSnapshot<Map<String, dynamic>>> loadUserData(
    String userId,
  ) async {
    return _firestore.collection('users').doc(userId).get();
  }

  /// Cập nhật Nickname
  Future<void> updateNickname(String userId, String newNickname) async {
    if (newNickname.isEmpty) {
      throw Exception('Nickname không được để trống.');
    }
    await _firestore.collection('users').doc(userId).update({
      'name': newNickname,
    });
  }

  /// Cập nhật thông tin chung
  Future<void> updateGeneralUserData({
    required String userId,
    required String fullName,
    required String bio,
    required String city,
    required String phoneNumber,
    required DateTime? selectedDate,
    required String? selectedGender,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'fullName': fullName.trim(),
      'bio': bio.trim(),
      'city': city.trim(),
      'phoneNumber': phoneNumber.trim(),
      'birthDate': selectedDate != null
          ? Timestamp.fromDate(selectedDate)
          : null,
      'gender': selectedGender ?? '',
    });
  }

  /// Chọn ảnh từ nguồn (gallery/camera)
  Future<File?> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return null;
    return File(image.path);
  }

  /// Tải ảnh lên Cloudinary và cập nhật Firestore
  Future<String> uploadAndUpdateAvatar(
    String userId,
    File newAvatarFile,
  ) async {
    // 1. Tải lên Cloudinary
    final uploadedUrl = await _cloudinaryService.uploadImageToCloudinary(
      newAvatarFile,
    );
    if (uploadedUrl == null) {
      throw Exception('Tải ảnh lên thất bại. Vui lòng thử lại.');
    }

    // 2. Cập nhật Firestore
    await _firestore.collection('users').doc(userId).update({
      'avatarUrl': uploadedUrl,
    });

    return uploadedUrl; // Trả về URL mới
  }

  /// Xóa avatar khỏi Firestore
  Future<void> deleteAvatar(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'avatarUrl': FieldValue.delete(),
    });
  }

  /// Xóa số điện thoại
  Future<void> deletePhoneNumber(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'phoneNumber': FieldValue.delete(),
    });
  }
}
