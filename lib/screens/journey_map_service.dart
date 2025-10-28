// File: journey_map_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
                provincesToHighlight.add(
                  _formatProvinceNameToId(provinceName),
                ); // Chuyển sang ID
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

  // === DI CHUYỂN TỪ _formatProvinceNameToId (lines 475-503) ===
  // (Hàm này là nội bộ của Service)
  String _formatProvinceNameToId(String name) {
    String normalized = name.toLowerCase();
    normalized = normalized.replaceFirst(RegExp(r'^(thành phố|tỉnh)\s'), '');
    normalized = normalized.replaceAll(RegExp(r'[àáảãạăắằẳẵặâấầẩẫậ]'), 'a');
    normalized = normalized.replaceAll(RegExp(r'[èéẻẽẹêếềểễệ]'), 'e');
    normalized = normalized.replaceAll(RegExp(r'[ìíỉĩị]'), 'i');
    normalized = normalized.replaceAll(RegExp(r'[òóỏõọôốồổỗộơớờởỡợ]'), 'o');
    normalized = normalized.replaceAll(RegExp(r'[ùúủũụưứừửữự]'), 'u');
    normalized = normalized.replaceAll(RegExp(r'[ỳýỷỹỵ]'), 'y');
    normalized = normalized.replaceAll(RegExp(r'[đ]'), 'd');
    normalized = normalized.replaceAll(RegExp(r'[\s\-\/\(\)]+'), '_');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    normalized = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized;
  }
}
