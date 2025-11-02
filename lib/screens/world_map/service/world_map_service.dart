// File: screens/world_map/service/world_map_service.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore để truy vấn CSDL
import 'package:geolocator/geolocator.dart'; // Import Geolocator để lấy vị trí GPS
import 'package:latlong2/latlong.dart'; // Import để dùng kiểu LatLng
import 'package:nhom_3_damh_lttbdd/model/category_model.dart'; // Import model Category
import 'package:geocoding/geocoding.dart'; // Import Geocoding để chuyển tọa độ -> địa chỉ
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // Import logic chuẩn hóa tên tỉnh/thành

/// Lớp WorldMapService chứa tất cả logic nghiệp vụ:
/// - Giao tiếp với Firebase (CSDL)
/// - Giao tiếp với API hệ thống (GPS)
/// - Giao tiếp với API bên ngoài (Geocoding)
/// Mục đích: Tách biệt logic ra khỏi UI (WorldMapScreen).
class WorldMapService {
  // Kiểu dữ liệu: FirebaseFirestore (final: khởi tạo 1 lần)
  // Mục đích: Cung cấp đối tượng instance để truy cập Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy danh sách Categories từ Firestore
  // Kiểu dữ liệu: Trả về 1 Future chứa List<CategoryModel>
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      // Gửi yêu cầu bất đồng bộ: lấy tất cả document trong collection 'categories'.
      final snapshot = await _firestore.collection('categories').get();
      // `snapshot.docs` là 1 List<QueryDocumentSnapshot>
      final categories = snapshot.docs
          .map(
            (doc) => CategoryModel.fromFirestore(doc),
          ) // Biến đổi mỗi doc -> CategoryModel
          .toList(); // Chuyển kết quả map (Iterable) -> List
      // Sắp xếp danh sách theo tên (alphabet)
      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories; // Trả về danh sách đã sắp xếp
    } catch (e) {
      // Xử lý lỗi
      print("Lỗi fetch categories: $e");
      rethrow; // Ném lỗi lại để `WorldMapScreen` có thể bắt và hiển thị
    }
  }

  /// Lấy vị trí hiện tại của người dùng
  // Kiểu dữ liệu: Trả về 1 Future chứa LatLng
  Future<LatLng> determinePosition() async {
    bool serviceEnabled; // Biến kiểm tra GPS có bật không
    LocationPermission permission; // Biến kiểm tra quyền truy cập
    try {
      // Kiểm tra xem dịch vụ vị trí (GPS) có đang bật trên thiết bị không.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Dịch vụ vị trí đã bị tắt.');

      // Kiểm tra quyền truy cập vị trí của ứng dụng.
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Nếu bị từ chối, yêu cầu lại quyền
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Nếu vẫn bị từ chối
          throw Exception('Quyền truy cập vị trí bị từ chối.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // Nếu bị từ chối vĩnh viễn (phải vào cài đặt app)
        throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn.');
      }

      // Nếu đã có quyền, lấy vị trí hiện tại.
      Position position = await Geolocator.getCurrentPosition();
      // Trả về dưới dạng LatLng
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Xử lý lỗi
      print("Lỗi khi lấy vị trí: $e");
      rethrow; // Ném lỗi lại cho UI xử lý
    }
  }

  /// Lấy tất cả địa điểm (Places) từ Firestore
  // Kiểu dữ liệu: Trả về 1 Future chứa List<DocumentSnapshot>
  // Ghi chú: Trả về DocumentSnapshot (dữ liệu thô) thay vì Model
  // để UI (WorldMapScreen) tự xử lý (ví dụ: lấy ID, cast data).
  Future<List<DocumentSnapshot>> fetchPlaces() async {
    try {
      // Gửi yêu cầu bất đồng bộ: lấy tất cả doc trong collection 'places'.
      QuerySnapshot placesSnapshot = await _firestore
          .collection('places')
          .get();
      return placesSnapshot.docs; // Trả về danh sách các document
    } catch (e) {
      // Xử lý lỗi
      print("Lỗi tải địa điểm từ Firestore: $e");
      rethrow; // Ném lỗi lại
    }
  }

  /// Lấy Tên đường + Tên tỉnh/thành đã chuẩn hóa từ LatLng (Reverse Geocoding)
  // Kiểu dữ liệu: Hàm nhận LatLng, trả về Future<String>
  Future<String> getStreetAndCity(LatLng pos) async {
    try {
      // Gọi API Geocoding để lấy danh sách địa chỉ (placemark) từ tọa độ.
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      // Nếu có kết quả
      if (placemarks.isNotEmpty) {
        // Lấy kết quả đầu tiên (thường là chính xác nhất)
        final Placemark p = placemarks.first;
        // Lấy tên đường (thoroughfare), nếu null thì dùng 'Không xác định'
        String street = p.thoroughfare ?? 'Không xác định';

        // Logic chuẩn hóa thành phố
        // `administrativeArea` thường là Tên Tỉnh/Thành phố (ví dụ: "Hồ Chí Minh")
        String rawCityName = p.administrativeArea ?? '';
        // Gọi hàm helper (từ cityExchange.dart) để chuẩn hóa tên
        String? mergedId = getMergedProvinceIdFromGeolocator(rawCityName);
        String city = "Không xác định"; // Mặc định

        if (mergedId != null) {
          // Nếu chuẩn hóa được, gọi hàm helper khác để định dạng lại tên
          city = formatProvinceIdToName(
            mergedId,
          ); // (ví dụ: "ho-chi-minh" -> "TP. Hồ Chí Minh")
        }
        // ===================================

        // Ghép chuỗi kết quả
        if (street != 'Không xác định' && city != 'Không xác định') {
          return '$street, $city'; // "Đường ABC, TP. Hồ Chí Minh"
        }
        if (city != 'Không xác định') return city; // "TP. Hồ Chí Minh"
        if (street != 'Không xác định') return street; // "Đường ABC"
      }
    } catch (e) {
      // Xử lý lỗi (ví dụ: không có kết nối mạng, tọa độ ngoài biển)
      print("Lỗi geocoding cho bottom sheet title: $e");
    }
    // Nếu mọi thứ thất bại
    return 'Vị trí chưa được khám phá';
  }
}
