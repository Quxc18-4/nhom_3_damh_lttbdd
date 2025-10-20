import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/travel_day.dart';

class LocalPlanService {
  static const _storageKey = 'travelPlanActivities';

  // Lưu toàn bộ danh sách TravelDay vào local storage
  Future<void> saveAllDays(List<TravelDay> allDays) async {
    final prefs = await SharedPreferences.getInstance();
    // Chuyển List<TravelDay> thành List<Map> -> List<String> (JSON encoded)
    final jsonList = allDays.map((day) => jsonEncode(day.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  // Tải toàn bộ danh sách TravelDay từ local storage
  Future<List<TravelDay>> loadAllDays() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey);

    if (jsonList == null) {
      return []; // Trả về danh sách rỗng nếu chưa có dữ liệu
    }

    // Chuyển List<String> (JSON encoded) thành List<TravelDay>
    return jsonList.map((jsonString) {
      final jsonMap = jsonDecode(jsonString);
      return TravelDay.fromJson(jsonMap as Map<String, dynamic>);
    }).toList();
  }
}