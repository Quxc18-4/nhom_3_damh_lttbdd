// File: screens/world_map/helper/map_helper.dart

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Kiểm tra xem một cú nhấn (tap) có ở gần marker đã có hay không.
bool isTapNearExistingMarker(
  LatLng tapLatLng,
  List<Marker> placeMarkers, {
  double thresholdDistance = 30, // 30 mét
}) {
  for (var marker in placeMarkers) {
    double distance = Geolocator.distanceBetween(
      tapLatLng.latitude,
      tapLatLng.longitude,
      marker.point.latitude,
      marker.point.longitude,
    );
    if (distance < thresholdDistance) return true;
  }
  return false;
}
