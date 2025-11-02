// File: screens/checkin/service/checkin_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';

class CheckinService {
  final _firestore = FirebaseFirestore.instance;
  final _cloudinaryService = CloudinaryService();
  final _picker = ImagePicker();

  /// Tải chi tiết một địa điểm từ Firestore bằng ID
  Future<DocumentSnapshot> fetchPlaceDetails(String placeId) async {
    try {
      final placeDoc = await _firestore.collection('places').doc(placeId).get();
      if (!placeDoc.exists) {
        throw Exception('Không tìm thấy thông tin địa điểm ($placeId).');
      }
      return placeDoc;
    } catch (e) {
      debugPrint("Lỗi tải chi tiết địa điểm: $e");
      rethrow;
    }
  }

  /// Tải tất cả địa điểm cho Mini Map Picker
  Future<List<DocumentSnapshot>> fetchAllPlaces() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('places').get();
      return snapshot.docs;
    } catch (e) {
      debugPrint("Lỗi tải places cho map picker: $e");
      rethrow;
    }
  }

  /// Tải 1 ảnh lên Cloudinary
  Future<String?> uploadLocalFile(XFile imageFile) async {
    File file = File(imageFile.path);
    try {
      return await _cloudinaryService.uploadImageToCloudinary(file);
    } catch (e) {
      debugPrint("Lỗi tải ảnh '${imageFile.name}' lên Cloudinary: $e");
      rethrow;
    }
  }

  /// Gửi bài review (logic chính)
  Future<void> submitReview({
    required String userId,
    required DocumentSnapshot selectedPlaceDoc,
    required String title,
    required String comment,
    required List<String> hashtags,
    required List<XFile> selectedImages,
  }) async {
    try {
      // 1. Tải ảnh
      List<String> finalImageUrls = [];
      if (selectedImages.isNotEmpty) {
        List<Future<String?>> uploadFutures = selectedImages
            .map(uploadLocalFile)
            .toList();
        List<String?> results = await Future.wait(uploadFutures);
        finalImageUrls = results.whereType<String>().toList();

        if (finalImageUrls.isEmpty) {
          throw Exception(
            'Không thể tải lên bất kỳ ảnh nào. Vui lòng thử lại.',
          );
        }
      }

      final placeData = selectedPlaceDoc.data() as Map<String, dynamic>? ?? {};
      final List<dynamic> categoryIds =
          placeData['categories'] as List<dynamic>? ?? [];

      // 2. Chuẩn bị dữ liệu Firestore
      final reviewsCollection = _firestore.collection('reviews');
      final newDoc = reviewsCollection.doc();

      final reviewData = {
        'userId': userId,
        'placeId': selectedPlaceDoc.id,
        'rating': 5, // Tạm thời
        'comment': comment,
        'title': title,
        'imageUrls': finalImageUrls,
        'hashtags': hashtags,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'commentCount': 0,
        'categoryIds': categoryIds,
      };

      // 3. Ghi vào Firestore
      await newDoc.set(reviewData);

      // 4. Cập nhật reviewCount trong 'places'
      await _firestore.collection('places').doc(selectedPlaceDoc.id).update({
        'reviewCount': FieldValue.increment(1),
      });

      // 5. Cập nhật tỉnh thành (fire-and-forget)
      updateVisitedProvinceOnCheckin(userId);
    } catch (e) {
      debugPrint("Lỗi khi gửi review: $e");
      rethrow;
    }
  }

  /// Cập nhật tỉnh thành đã ghé thăm (lấy từ GPS)
  Future<void> updateVisitedProvinceOnCheckin(String userId) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("VisitedProvince: Dịch vụ vị trí đã tắt.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint("VisitedProvince: Quyền vị trí bị từ chối.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        debugPrint("VisitedProvince: Không thể geocode vị trí hiện tại.");
        return;
      }

      String rawCityName = placemarks.first.administrativeArea ?? '';
      String? provinceId = getMergedProvinceIdFromGeolocator(rawCityName);

      if (provinceId == null) {
        debugPrint(
          "VisitedProvince: Không thể map '$rawCityName' sang ID chuẩn.",
        );
        return;
      }

      await _firestore.collection('users').doc(userId).update({
        'visitedProverbs': FieldValue.arrayUnion([provinceId]),
      });

      debugPrint("VisitedProvince: Đã cập nhật thành công: $provinceId");
    } catch (e) {
      debugPrint("VisitedProvince: Lỗi không xác định: $e");
    }
  }

  // === LOGIC IMAGE PICKER ===
  Future<List<XFile>> pickImagesFromGallery(int currentCount, int max) async {
    int availableSlots = max - currentCount;
    if (availableSlots <= 0) return [];

    final List<XFile> images = await _picker.pickMultiImage();
    int countToAdd = images.length < availableSlots
        ? images.length
        : availableSlots;
    return images.sublist(0, countToAdd);
  }

  Future<XFile?> pickImageFromCamera(int currentCount, int max) async {
    if (currentCount >= max) return null;
    return await _picker.pickImage(source: ImageSource.camera);
  }
}
