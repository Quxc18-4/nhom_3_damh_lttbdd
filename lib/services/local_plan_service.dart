import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/travel_day.dart';

class LocalPlanService {
  static const String _travelPlanKey = 'travelPlanActivities'; // Khóa cho danh sách TravelDay
  static const String _startDateKey = 'startDate'; // Khóa mới cho ngày bắt đầu

  // Lưu toàn bộ danh sách TravelDay vào local storage
  Future<void> saveAllDays(List<TravelDay> allDays) async {
    final prefs = await SharedPreferences.getInstance();
    // Chuyển List<TravelDay> thành List<Map> -> List<String> (JSON encoded)
    final jsonList = allDays.map((day) => jsonEncode(day.toJson())).toList();
    await prefs.setStringList(_travelPlanKey, jsonList);
  }

  // Tải toàn bộ danh sách TravelDay từ local storage
  Future<List<TravelDay>> loadAllDays() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_travelPlanKey);

    if (jsonList == null) {
      return []; // Trả về danh sách rỗng nếu chưa có dữ liệu
    }

    // Chuyển List<String> (JSON encoded) thành List<TravelDay>
    return jsonList.map((jsonString) {
      final jsonMap = jsonDecode(jsonString);
      return TravelDay.fromJson(jsonMap as Map<String, dynamic>);
    }).toList();
  }

  // Lưu ngày bắt đầu vào local storage
  Future<void> saveStartDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startDateKey, date.toIso8601String()); // Lưu dưới dạng ISO 8601
  }

  // Tải ngày bắt đầu từ local storage
  Future<DateTime?> loadStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_startDateKey);
    return dateString != null ? DateTime.parse(dateString) : null; // Trả về null nếu không có
  }
}