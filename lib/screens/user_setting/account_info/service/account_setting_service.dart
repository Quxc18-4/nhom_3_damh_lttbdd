// File: screens/user_setting/account_setting/service/account_setting_service.dart

import 'dart:io'; // Dùng cho File (ảnh từ thiết bị)
import 'package:cloud_firestore/cloud_firestore.dart'; // Kết nối Firestore
import 'package:image_picker/image_picker.dart'; // Chọn ảnh từ thư viện/camera
// Cập nhật đường dẫn này
import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart'; // Service tải ảnh lên Cloudinary

class AccountSettingService { // Service xử lý cài đặt tài khoản
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Khởi tạo kết nối Firestore
  final ImagePicker _picker = ImagePicker(); // Khởi tạo ImagePicker
  final CloudinaryService _cloudinaryService = CloudinaryService(); // Khởi tạo service Cloudinary

  /// Tải dữ liệu người dùng
  Future<DocumentSnapshot<Map<String, dynamic>>> loadUserData( // Lấy document user từ Firestore
    String userId, // ID người dùng
  ) async {
    return _firestore.collection('users').doc(userId).get(); // Trả về snapshot
  }

  /// Cập nhật Nickname
  Future<void> updateNickname(String userId, String newNickname) async { // Cập nhật tên hiển thị
    if (newNickname.isEmpty) { // Kiểm tra rỗng
      throw Exception('Nickname không được để trống.'); // Ném lỗi nếu rỗng
    }
    await _firestore.collection('users').doc(userId).update({ // Cập nhật trường 'name'
      'name': newNickname,
    });
  }

  /// Cập nhật thông tin chung
  Future<void> updateGeneralUserData({ // Cập nhật nhiều trường cùng lúc
    required String userId, // ID người dùng
    required String fullName, // Họ tên
    required String bio, // Tiểu sử
    required String city, // Thành phố
    required String phoneNumber, // Số điện thoại
    required DateTime? selectedDate, // Ngày sinh (có thể null)
    required String? selectedGender, // Giới tính (có thể null)
  }) async {
    await _firestore.collection('users').doc(userId).update({ // Cập nhật nhiều field
      'fullName': fullName.trim(), // Loại bỏ khoảng trắng thừa
      'bio': bio.trim(),
      'city': city.trim(),
      'phoneNumber': phoneNumber.trim(),
      'birthDate': selectedDate != null // Nếu có ngày sinh
          ? Timestamp.fromDate(selectedDate) // Chuyển DateTime → Timestamp
          : null, // Nếu null thì để null
      'gender': selectedGender ?? '', // Nếu null thì để chuỗi rỗng
    });
  }

  /// Chọn ảnh từ nguồn (gallery/camera)
  Future<File?> pickImage(ImageSource source) async { // Mở thư viện hoặc camera
    final XFile? image = await _picker.pickImage(source: source); // Chọn ảnh
    if (image == null) return null; // Nếu không chọn ảnh
    return File(image.path); // Trả về File từ đường dẫn
  }

  /// Tải ảnh lên Cloudinary và cập nhật Firestore
  Future<String> uploadAndUpdateAvatar( // Tải avatar mới
    String userId, // ID người dùng
    File newAvatarFile, // File ảnh mới
  ) async {
    // 1. Tải lên Cloudinary
    final uploadedUrl = await _cloudinaryService.uploadImageToCloudinary( // Gọi service Cloudinary
      newAvatarFile, // File ảnh
    );
    if (uploadedUrl == null) { // Nếu tải lên thất bại
      throw Exception('Tải ảnh lên thất bại. Vui lòng thử lại.');
    }

    // 2. Cập nhật Firestore
    await _firestore.collection('users').doc(userId).update({ // Cập nhật trường avatarUrl
      'avatarUrl': uploadedUrl,
    });

    return uploadedUrl; // Trả về URL mới để UI cập nhật
  }

  /// Xóa avatar khỏi Firestore
  Future<void> deleteAvatar(String userId) async { // Xóa URL avatar
    await _firestore.collection('users').doc(userId).update({
      'avatarUrl': FieldValue.delete(), // Dùng FieldValue để xóa trường
    });
  }

  /// Xóa số điện thoại
  Future<void> deletePhoneNumber(String userId) async { // Xóa số điện thoại
    await _firestore.collection('users').doc(userId).update({
      'phoneNumber': FieldValue.delete(), // Xóa trường phoneNumber
    });
  }
}