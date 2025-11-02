// File: screens/home/service/home_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Cập nhật các đường dẫn import này cho đúng
import 'package:nhom_3_damh_lttbdd/services/local_plan_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/journey_map/service/journey_map_service.dart';
import 'package:nhom_3_damh_lttbdd/model/activity.dart';
import 'package:nhom_3_damh_lttbdd/model/banner.dart';

// Service xử lý toàn bộ dữ liệu cho màn hình Home
class HomeService {
  // Khởi tạo các service cần dùng
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalPlanService _localPlanService = LocalPlanService();
  final JourneyMapService _mapService = JourneyMapService();

  /// Tải thông tin nickname của người dùng hiện tại từ Firestore
  /// Trả về tên người dùng, nếu lỗi thì trả về 'Mydei'
  Future<String> fetchUserData() async {
    try {
      final user = _auth.currentUser; // Lấy user đang đăng nhập
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(); // Lấy document user
        if (userDoc.exists) {
          return userDoc.data()?['name'] ?? 'Mydei'; // Trả về tên, nếu null thì dùng mặc định
        }
      }
    } catch (e) {
      print("Lỗi fetchUserData: $e"); // In lỗi ra console
    }
    return 'Mydei'; // Trả về tên mặc định nếu không lấy được
  }

  /// Tải ngày bắt đầu của lịch trình từ Local Storage (SharedPreferences)
  /// Nếu chưa có → trả về ngày hiện tại
  Future<DateTime> fetchTripStartDate() async {
    final savedDate = await _localPlanService.loadStartDate(); // Gọi service local
    return savedDate ?? DateTime.now(); // Nếu null → dùng hôm nay
  }

  /// Tải 3 ngày đầu tiên của lịch trình (dùng để preview)
  /// Trả về List có 3 phần tử, mỗi phần tử là List<Activity> của 1 ngày
  Future<List<List<Activity>>> fetchActivityPreviews() async {
    final allDays = await _localPlanService.loadAllDays(); // Lấy toàn bộ ngày đã lưu
    List<List<Activity>> tempActivities = List.generate(3, (index) => []); // Tạo 3 ngày rỗng
    if (allDays.isNotEmpty) {
      for (int i = 0; i < 3; i++) {
        if (i < allDays.length) {
          tempActivities[i] = allDays[i].activities; // Gán hoạt động nếu có
        }
      }
    }
    return tempActivities; // Trả về 3 ngày (có thể rỗng)
  }

  /// Tải các banner đang hoạt động từ Firestore
  /// Điều kiện: endDate > now → còn hiệu lực
  /// Lấy tối đa 5 banner, sắp xếp theo endDate (sớm nhất trước)
  Future<List<BannerModel>> fetchActiveBanners() async {
    try {
      final now = DateTime.now(); // Thời điểm hiện tại
      final snapshot = await _firestore
          .collection('banners')
          .where('endDate', isGreaterThan: now) // Chỉ lấy banner còn hạn
          .orderBy('endDate', descending: false) // Sắp xếp tăng dần
          .limit(5) // Giới hạn 5
          .get();
      return snapshot.docs
          .map((doc) => BannerModel.fromFirestore(doc)) // Chuyển Firestore → Model
          .toList();
    } catch (e) {
      print("Lỗi khi tải banners: $e");
      return []; // Trả về rỗng nếu lỗi
    }
  }

  /// Tải danh sách tỉnh đã check-in từ JourneyMapService
  /// Dùng để tô màu tỉnh trên bản đồ ở Home
  Future<Set<String>> fetchVisitedProvinces(String userId) async {
    try {
      return await _mapService.loadHighlightedProvinces(userId); // Gọi service bản đồ
    } catch (e) {
      print("Lỗi tải dữ liệu bản đồ (Home): $e");
      return {}; // Trả về rỗng nếu lỗi
    }
  }

  /// Lấy Stream thông báo chưa đọc của người dùng
  /// Dùng để hiển thị badge số thông báo trên icon
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationStream(
    String userId,
  ) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId) // Chỉ của user này
        .where('isRead', isEqualTo: false) // Chưa đọc
        .snapshots(); // Stream realtime
  }
}