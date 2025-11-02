// File: screens/world_map/service/world_map_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:nhom_3_damh_lttbdd/model/category_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';

class WorldMapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy danh sách Categories từ Firestore
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories;
    } catch (e) {
      print("Lỗi fetch categories: $e");
      rethrow;
    }
  }

  /// Lấy vị trí hiện tại của người dùng
  Future<LatLng> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Dịch vụ vị trí đã bị tắt.');
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Quyền truy cập vị trí bị từ chối.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn.');
      }
      Position position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print("Lỗi khi lấy vị trí: $e");
      rethrow;
    }
  }

  /// Lấy tất cả địa điểm (Places) từ Firestore
  Future<List<DocumentSnapshot>> fetchPlaces() async {
    try {
      QuerySnapshot placesSnapshot = await _firestore
          .collection('places')
          .get();
      return placesSnapshot.docs;
    } catch (e) {
      print("Lỗi tải địa điểm từ Firestore: $e");
      rethrow;
    }
  }

  /// Lấy Tên đường + Tên tỉnh/thành đã chuẩn hóa từ LatLng
  Future<String> getStreetAndCity(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        String street = p.thoroughfare ?? 'Không xác định';

        // Logic chuẩn hóa thành phố
        String rawCityName = p.administrativeArea ?? '';
        String? mergedId = getMergedProvinceIdFromGeolocator(rawCityName);
        String city = "Không xác định";

        if (mergedId != null) {
          city = formatProvinceIdToName(mergedId);
        }
        // ===================================

        if (street != 'Không xác định' && city != 'Không xác định') {
          return '$street, $city';
        }
        if (city != 'Không xác định') return city;
        if (street != 'Không xác định') return street;
      }
    } catch (e) {
      print("Lỗi geocoding cho bottom sheet title: $e");
    }
    return 'Vị trí chưa được khám phá';
  }
}
