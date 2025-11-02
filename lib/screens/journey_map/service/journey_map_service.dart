// File: journey_map_service.dart

import 'dart:async'; // Dùng cho Future, Stream (ở đây dùng Future)
import 'package:cloud_firestore/cloud_firestore.dart'; // Kết nối Firestore
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // Hàm chuẩn hóa tên tỉnh
import 'package:collection/collection.dart'; // Dùng .whereNotNull() để lọc null

class JourneyMapService { // Service xử lý dữ liệu cho Journey Map
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Khởi tạo kết nối Firestore

  // === DI CHUYỂN TỪ _loadHighlightData (lines 149-216) ===
  // (Đã xóa các logic về mounted, setState, _originalSvgContent)
  Future<Set<String>> loadHighlightedProvinces(String userId) async { // Tải danh sách tỉnh cần tô màu
    Set<String> provincesToHighlight = {}; // Tập hợp các ID tỉnh cần highlight
    try { // Bắt lỗi toàn bộ hàm
      // 1. Lấy danh sách tỉnh thành người dùng tự chọn (visitedProvinces LÀ DANH SÁCH CÁC ID)
      final userDoc = await _firestore.collection('users').doc(userId).get(); // Lấy document user
      if (userDoc.exists && userDoc.data()!.containsKey('visitedProvinces')) { // Kiểm tra tồn tại trường
        final List<dynamic> visitedIds = userDoc.data()!['visitedProvinces']; // Lấy mảng ID tỉnh
        provincesToHighlight.addAll(visitedIds.map((id) => id.toString())); // Chuyển sang String, thêm vào Set
      }

      // 2. Lấy danh sách tỉnh thành từ các bài review của người dùng
      final reviewsSnapshot = await _firestore // Lấy tất cả review của user
          .collection('reviews')
          .where('userId', isEqualTo: userId) // Chỉ lấy của user này
          .get();

      final placeIds = reviewsSnapshot.docs // Lấy placeId từ mỗi review
          .map((doc) => doc.data()['placeId'] as String?) // Lấy placeId, có thể null
          .whereNotNull() // Loại bỏ các giá trị null
          .toSet() // Chuyển thành Set để loại trùng
          .toList(); // Chuyển lại List để xử lý whereIn

      if (placeIds.isNotEmpty) { // Nếu có placeId
        List<Future<QuerySnapshot<Map<String, dynamic>>>> placeFutures = []; // Danh sách các Future truy vấn
        for (var i = 0; i < placeIds.length; i += 30) { // Chia nhỏ danh sách (Firestore giới hạn 30 phần tử trong whereIn)
          final subList = placeIds.sublist( // Lấy 30 phần tử mỗi lần
            i,
            i + 30 > placeIds.length ? placeIds.length : i + 30, // Đảm bảo không vượt quá độ dài
          );
          placeFutures.add( // Thêm truy vấn vào danh sách
            _firestore
                .collection('places')
                .where(FieldPath.documentId, whereIn: subList) // Lấy places theo ID
                .get(),
          );
        }
        final placeSnapshots = await Future.wait(placeFutures); // Chờ tất cả truy vấn hoàn thành

        for (var placesSnapshot in placeSnapshots) { // Duyệt từng batch kết quả
          for (var placeDoc in placesSnapshot.docs) { // Duyệt từng document place
            final placeData = placeDoc.data(); // Lấy dữ liệu
            final location = placeData['location']; // Lấy trường location
            if (location is Map && location.containsKey('city')) { // Kiểm tra có city không
              final String provinceName =
                  location['city'] ?? ''; // Tên tỉnh từ Firestore (có thể rỗng)
              if (provinceName.isNotEmpty) { // Nếu có tên tỉnh
                // Dùng hàm chuẩn hóa toàn cục
                final String? provinceId = getMergedProvinceIdFromGeolocator( // Chuẩn hóa tên → ID
                  provinceName,
                );

                if (provinceId != null) { // Nếu chuẩn hóa thành công
                  // Sẽ thêm "ho_chi_minh", nhưng Set đã có nên bỏ qua
                  provincesToHighlight.add(provinceId); // Thêm ID tỉnh vào Set
                } else { // Nếu không chuẩn hóa được
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
      return provincesToHighlight; // Trả về Set các ID tỉnh cần highlight
    } catch (e) { // Bắt mọi lỗi
      print("Lỗi tải dữ liệu highlight: $e"); // In lỗi ra console
      rethrow; // Ném lỗi ra để UI xử lý
    }
  }
}