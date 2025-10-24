import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http; // Bạn đã cài, để đây nếu cần

class WorldMapScreen extends StatefulWidget {
  final String userId;

  const WorldMapScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  // Danh sách các "khung" (Polygons) bạn muốn vẽ
  // Tương lai, bạn sẽ tải GeoJSON và parse ra danh sách này
  // Biến state mới để quản lý việc tải vị trí
  bool _isLoadingLocation = true;
  // Tọa độ mặc định (Hà Nội) phòng trường hợp không lấy được vị trí
  LatLng _currentCenter = const LatLng(21.0285, 105.8542);

  // === DỮ LIỆU ĐỂ GIỚI HẠN BẢN ĐỒ VIỆT NAM ===
  final LatLngBounds _vietnamBounds = LatLngBounds(
    const LatLng(8.18, 102.14), // Góc Tây Nam (Cà Mau)
    const LatLng(23.39, 109.46), // Góc Đông Bắc (Hà Giang/Biển)
  );

  final List<Polygon> _countryPolygons = [
    // Đây là một hình vuông mẫu gần Đà Nẵng để test
    Polygon(
      points: [
        LatLng(16.1, 108.1), // góc 1
        LatLng(16.1, 108.2), // góc 2
        LatLng(16.0, 108.2), // góc 3
        LatLng(16.0, 108.1), // góc 4
      ],
      color: Colors.blue.withOpacity(0.3), // Màu nền của khung
      borderColor: Colors.blue, // Màu viền của khung
      borderStrokeWidth: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // === HÀM MỚI: LẤY VỊ TRÍ HIỆN TẠI ===
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Kiểm tra dịch vụ vị trí có bật không
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Dịch vụ vị trí đã bị tắt.');
      }

      // Kiểm tra quyền
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

      // Lấy vị trí
      Position position = await Geolocator.getCurrentPosition();

      // Cập nhật state với vị trí mới
      if (mounted) {
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      // Nếu có lỗi, dùng vị trí mặc định và tắt loading
      print("Lỗi khi lấy vị trí: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí: $e. Dùng vị trí mặc định.'),
          ),
        );
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ thế giới (OSM)'),
        actions: [
          // Nút này có thể dùng userId của bạn
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Lưu địa điểm',
            onPressed: () {
              // TODO: Xử lý sự kiện tạo Place/Review
              print('UserID: ${widget.userId} đang muốn tạo địa điểm...');
              // Ví dụ: hiện dialog, navigator...
            },
          ),
        ],
      ),
      // === SỬ DỤNG BIẾN LOADING ĐỂ HIỂN THỊ BẢN ĐỒ ===
      body: _isLoadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang lấy vị trí của bạn...'),
                ],
              ),
            )
          : FlutterMap(
              options: MapOptions(
                // 1. Dùng vị trí vừa lấy được
                initialCenter: _currentCenter,
                // 2. Zoom "kiểu Google"
                initialZoom: 18.0, // Zoom sát hơn (thay vì 9.0)
                keepAlive: true,

                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.all &
                      ~InteractiveFlag.rotate, // Khóa xoay
                ),

                // 3. Giới hạn bản đồ trong khu vực Việt Nam
                cameraConstraint: CameraConstraint.contain(
                  bounds: _vietnamBounds, // Dùng biến bounds của VN
                  //padding: const EdgeInsets.all(50.0), // Thêm 1 chút đệm
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.nhom_3_damh_lttbdd',
                ),
                PolygonLayer(polygons: _countryPolygons),
              ],
            ),
    );
  }
}
