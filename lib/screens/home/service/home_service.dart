// File: screens/home/service/home_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Cập nhật các đường dẫn import này cho đúng
import 'package:nhom_3_damh_lttbdd/services/local_plan_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/journey_map/service/journey_map_service.dart';
import 'package:nhom_3_damh_lttbdd/model/activity.dart';
import 'package:nhom_3_damh_lttbdd/model/banner.dart';

class HomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalPlanService _localPlanService = LocalPlanService();
  final JourneyMapService _mapService = JourneyMapService();

  /// Tải thông tin nickname của người dùng
  Future<String> fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          return userDoc.data()?['name'] ?? 'Mydei';
        }
      }
    } catch (e) {
      print("Lỗi fetchUserData: $e");
    }
    return 'Mydei'; // Trả về tên mặc định nếu lỗi
  }

  /// Tải ngày bắt đầu của lịch trình từ local
  Future<DateTime> fetchTripStartDate() async {
    final savedDate = await _localPlanService.loadStartDate();
    return savedDate ?? DateTime.now();
  }

  /// Tải 3 ngày đầu tiên của lịch trình từ local
  Future<List<List<Activity>>> fetchActivityPreviews() async {
    final allDays = await _localPlanService.loadAllDays();
    List<List<Activity>> tempActivities = List.generate(3, (index) => []);
    if (allDays.isNotEmpty) {
      for (int i = 0; i < 3; i++) {
        if (i < allDays.length) {
          tempActivities[i] = allDays[i].activities;
        }
      }
    }
    return tempActivities;
  }

  /// Tải các banner đang hoạt động từ Firestore
  Future<List<BannerModel>> fetchActiveBanners() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('banners')
          .where('endDate', isGreaterThan: now)
          .orderBy('endDate', descending: false)
          .limit(5)
          .get();
      return snapshot.docs
          .map((doc) => BannerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Lỗi khi tải banners: $e");
      return [];
    }
  }

  /// Tải danh sách tỉnh đã check-in từ JourneyMapService
  Future<Set<String>> fetchVisitedProvinces(String userId) async {
    try {
      return await _mapService.loadHighlightedProvinces(userId);
    } catch (e) {
      print("Lỗi tải dữ liệu bản đồ (Home): $e");
      return {};
    }
  }

  /// Lấy Stream thông báo chưa đọc
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationStream(
    String userId,
  ) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots();
  }
}
