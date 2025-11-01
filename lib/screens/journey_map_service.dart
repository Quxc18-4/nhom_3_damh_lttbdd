// File: journey_map_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';
import 'package:collection/collection.dart';

class JourneyMapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // === DI CHUYỂN TỪ _loadHighlightData (lines 149-216) ===
  // (Đã xóa các logic về mounted, setState, _originalSvgContent)
  Future<Set<String>> loadHighlightedProvinces(String userId) async {
    Set<String> provincesToHighlight = {};
    try {
      // 1. Lấy danh sách tỉnh thành người dùng tự chọn (visitedProvinces LÀ DANH SÁCH CÁC ID)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data()!.containsKey('visitedProvinces')) {
        final List<dynamic> visitedIds = userDoc.data()!['visitedProvinces'];
        provincesToHighlight.addAll(visitedIds.map((id) => id.toString()));
      }

      // 2. Lấy danh sách tỉnh thành từ các bài review của người dùng
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      final placeIds = reviewsSnapshot.docs
          .map((doc) => doc.data()['placeId'] as String?)
          .whereNotNull()
          .toSet()
          .toList();

      if (placeIds.isNotEmpty) {
        List<Future<QuerySnapshot<Map<String, dynamic>>>> placeFutures = [];
        for (var i = 0; i < placeIds.length; i += 30) {
          final subList = placeIds.sublist(
            i,
            i + 30 > placeIds.length ? placeIds.length : i + 30,
          );
          placeFutures.add(
            _firestore
                .collection('places')
                .where(FieldPath.documentId, whereIn: subList)
                .get(),
          );
        }
        final placeSnapshots = await Future.wait(placeFutures);

        for (var placesSnapshot in placeSnapshots) {
          for (var placeDoc in placesSnapshot.docs) {
            final placeData = placeDoc.data();
            final location = placeData['location'];
            if (location is Map && location.containsKey('city')) {
              final String provinceName =
                  location['city'] ?? ''; // Tên đầy đủ từ Firestore
              if (provinceName.isNotEmpty) {
                // Dùng hàm chuẩn hóa toàn cục
                final String? provinceId = getMergedProvinceIdFromGeolocator(
                  provinceName,
                );

                if (provinceId != null) {
                  // Sẽ thêm "ho_chi_minh", nhưng Set đã có nên bỏ qua
                  provincesToHighlight.add(provinceId);
                } else {
                  // In ra log nếu không thể chuẩn hóa tên tỉnh từ review
                  print(
                    "Service Warning: Không thể chuẩn hóa tên tỉnh từ review: $provinceName",
                  );
                }
              }
            }
          }
        }
      }
      // Trả về dữ liệu thô, không setState
      return provincesToHighlight;
    } catch (e) {
      print("Lỗi tải dữ liệu highlight: $e");
      rethrow; // Ném lỗi ra để UI xử lý
    }
  }
}
