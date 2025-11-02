// File: screens/world_map/helper/map_helper.dart

import 'package:flutter_map/flutter_map.dart'; // Import để dùng kiểu Marker
import 'package:latlong2/latlong.dart'; // Import để dùng kiểu LatLng
import 'package:geolocator/geolocator.dart'; // Import để dùng hàm tính khoảng cách

/// Kiểm tra xem một cú nhấn (tap) có ở gần marker đã có hay không.
// Kiểu dữ liệu: Hàm trả về bool (true/false)
bool isTapNearExistingMarker(
  LatLng tapLatLng, // Tọa độ nơi người dùng nhấn
  List<Marker> placeMarkers, { // Danh sách các marker hiện có
  double thresholdDistance = 30, // Ngưỡng khoảng cách (mặc định 30 mét)
}) {
  // Lặp qua từng marker
  for (var marker in placeMarkers) {
    // Sử dụng Geolocator để tính khoảng cách (tính toán đường cong Trái Đất)
    double distance = Geolocator.distanceBetween(
      tapLatLng.latitude, // Tọa độ 1
      tapLatLng.longitude,
      marker.point.latitude, // Tọa độ 2 (của marker)
      marker.point.longitude,
    );
    // Nếu khoảng cách nhỏ hơn ngưỡng
    if (distance < thresholdDistance) return true; // Trả về true ngay lập tức
  }
  return false; // Nếu lặp hết mà không có marker nào gần, trả về false
}
