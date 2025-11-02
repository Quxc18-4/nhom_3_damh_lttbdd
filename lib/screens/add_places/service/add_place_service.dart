// File: screens/add_places/service/add_place_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';
import 'package:nhom_3_damh_lttbdd/model/category_model.dart';
import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart';

/// Kết quả trả về từ hàm fetchAddressDetails
class FetchedAddress {
  final String street;
  final String ward;
  final String? city;
  final String? rawCity; // Tên thành phố gốc chưa chuẩn hóa

  FetchedAddress({
    required this.street,
    required this.ward,
    this.city,
    this.rawCity,
  });
}

class AddPlaceService {
  final _firestore = FirebaseFirestore.instance;
  final _cloudinaryService = CloudinaryService();

  /// Tải danh sách tất cả Category
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories;
    } catch (e) {
      debugPrint("Lỗi fetch categories: $e");
      rethrow;
    }
  }

  /// Lấy chi tiết địa chỉ từ tọa độ LatLng
  Future<FetchedAddress> fetchAddressDetails(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        String street = place.thoroughfare ?? 'Không xác định';
        String ward = place.subAdministrativeArea ?? 'Không xác định';
        String rawPlacemarkCity = place.administrativeArea ?? '';

        String? mergedProvinceId = getMergedProvinceIdFromGeolocator(
          rawPlacemarkCity,
        );
        String? selectedCity;
        if (mergedProvinceId != null) {
          selectedCity = formatProvinceIdToName(mergedProvinceId);
        } else {
          debugPrint(
            "Không thể khớp '$rawPlacemarkCity' với bất kỳ ID tỉnh/thành nào.",
          );
        }
        return FetchedAddress(
          street: street,
          ward: ward,
          city: selectedCity,
          rawCity: rawPlacemarkCity,
        );
      } else {
        throw Exception('Không thể tìm thấy thông tin địa chỉ cho tọa độ này.');
      }
    } catch (e) {
      debugPrint("Lỗi geocoding: $e");
      rethrow;
    }
  }

  /// Tải 1 file ảnh lên Cloudinary
  Future<String?> _uploadLocalFile(XFile imageFile) async {
    File file = File(imageFile.path);
    try {
      String? uploadedUrl = await _cloudinaryService.uploadImageToCloudinary(
        file,
      );
      return uploadedUrl;
    } catch (e) {
      debugPrint("Lỗi tải ảnh '${imageFile.name}' lên Cloudinary: $e");
      return null; // Trả về null nếu lỗi
    }
  }

  /// Gửi toàn bộ form đăng ký địa điểm
  Future<void> submitPlaceRequest({
    required String userId,
    required LatLng latLng,
    required String name,
    required String notes,
    required String street,
    required String ward,
    required String city,
    required List<CategoryModel> selectedCategories,
    required List<XFile> selectedImages,
  }) async {
    try {
      // --- BƯỚC 1: UPLOAD ẢNH ---
      List<String> uploadedImageUrls = [];
      if (selectedImages.isNotEmpty) {
        List<Future<String?>> uploadFutures = [];
        for (XFile imageFile in selectedImages) {
          uploadFutures.add(_uploadLocalFile(imageFile));
        }
        List<String?> results = await Future.wait(uploadFutures);
        uploadedImageUrls = results
            .whereType<String>()
            .toList(); // Lọc bỏ các URL null (lỗi)

        if (uploadedImageUrls.isEmpty && selectedImages.isNotEmpty) {
          throw Exception('Không thể tải lên bất kỳ ảnh nào.');
        }
      }

      // --- BƯỚC 2: CHUẨN BỊ DỮ LIỆU FIRESTORE ---
      final String fullAddress = '$street, $ward, $city';
      final List<String> categoryIds = selectedCategories
          .map((cat) => cat.id)
          .toList();

      final Map<String, dynamic> submissionData = {
        'submittedBy': userId,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'placeData': {
          'name': name,
          'description': notes,
          'location': {
            'coordinates': GeoPoint(latLng.latitude, latLng.longitude),
            'fullAddress': fullAddress,
            'street': street,
            'ward': ward,
            'city': city,
          },
          'categories': categoryIds,
          'images': uploadedImageUrls,
          'ratingAverage': 0,
          'reviewCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': userId,
        },
        'initialReviewData': {},
      };

      // --- BƯỚC 3: GỬI LÊN FIRESTORE ---
      await _firestore.collection('placeSubmissions').add(submissionData);
    } catch (e) {
      debugPrint("Lỗi khi gửi submission: $e");
      rethrow; // Ném lỗi ra để UI xử lý
    }
  }
}
