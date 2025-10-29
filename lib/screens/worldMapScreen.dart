import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Cần cho BackdropFilter
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
// !!! QUAN TRỌNG: Đảm bảo đường dẫn này đúng tới file AddPlaceScreen của bạn
import 'package:nhom_3_damh_lttbdd/screens/addPlaceRequest.dart'; // <<< SỬA ĐƯỜNG DẪN NẾU CẦN
import 'package:nhom_3_damh_lttbdd/screens/checkinScreen.dart'; // <<< THÊM DÒNG NÀY (Sửa nếu cần)
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // Cần cho hàm tính toán _findNearbyPlace (nếu dùng lại) và cos

class WorldMapScreen extends StatefulWidget {
  final String userId;
  const WorldMapScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  // === State ===
  final MapController _mapController = MapController();
  bool _isLoadingLocation = true;
  LatLng _currentCenter = const LatLng(21.0285, 105.8542); // Mặc định Hà Nội
  LatLng? _longPressedLatLng; // Vị trí marker ĐỎ tạm thời (khi nhấn giữ)

  // === State mới cho Places ===
  List<DocumentSnapshot> _fetchedPlaces = []; // Lưu documents từ Firestore
  List<Marker> _placeMarkers = []; // Lưu các marker ĐEN (địa điểm đã có)
  bool _isLoadingPlaces = true; // Loading cho places

  // === Dữ liệu giới hạn bản đồ ===
  final LatLngBounds _vietnamBounds = LatLngBounds(
    const LatLng(8.18, 102.14),
    const LatLng(23.39, 109.46),
  );

  // === Polygon mẫu (Giữ nguyên) ===
  final List<Polygon> _countryPolygons = [
    Polygon(
      points: [
        LatLng(16.1, 108.1),
        LatLng(16.1, 108.2),
        LatLng(16.0, 108.2),
        LatLng(16.0, 108.1),
      ],
      color: Colors.blue.withOpacity(0.3),
      borderColor: Colors.blue,
      borderStrokeWidth: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  // === Gộp các lệnh gọi bất đồng bộ ban đầu ===
  Future<void> _initializeMapData() async {
    // Chạy song song
    await Future.wait([_determinePosition(), _fetchPlacesFromFirestore()]);
    // Không cần setState loading chung ở đây vì mỗi hàm tự quản lý state riêng
  }

  // === Logic lấy vị trí (Giữ nguyên từ file của bạn) ===
  Future<void> _determinePosition() async {
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
      if (mounted) {
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print("Lỗi khi lấy vị trí: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí: $e. Dùng vị trí mặc định.'),
          ),
        );
        setState(() {
          _isLoadingLocation = false;
        }); // Vẫn tắt loading dù lỗi
      }
    }
  }

  // === Tải Places từ Firestore và Tạo Markers (Giữ nguyên từ file của bạn) ===
  Future<void> _fetchPlacesFromFirestore() async {
    if (!mounted) return;
    setState(() => _isLoadingPlaces = true);
    try {
      QuerySnapshot placesSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .get();
      _fetchedPlaces = placesSnapshot.docs;
      List<Marker> markers = [];
      for (var placeDoc in _fetchedPlaces) {
        final data = placeDoc.data() as Map<String, dynamic>;
        final coordinates = data['location']?['coordinates'] as GeoPoint?;
        // final placeName = data['name'] as String?; // Lấy tên nếu cần tooltip

        if (coordinates != null) {
          markers.add(
            Marker(
              point: LatLng(coordinates.latitude, coordinates.longitude),
              width: 35,
              height: 35,
              child: GestureDetector(
                // Bọc để bắt onTap
                onTap: () => _handlePlaceMarkerTap(
                  placeDoc,
                ), // Gọi hàm xử lý tap marker đen
                child: Tooltip(
                  // Thêm tooltip
                  message: data['name'] ?? 'Địa điểm',
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20.0,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
      if (mounted)
        setState(() {
          _placeMarkers = markers;
          _isLoadingPlaces = false;
        });
    } catch (e) {
      print("Lỗi tải địa điểm từ Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách địa điểm: $e')),
        );
        setState(() => _isLoadingPlaces = false);
      }
    }
  }

  // === Logic căn giữa map (Giữ nguyên) ===
  void _centerMapOnLatLng(LatLng targetCenter) {
    _mapController.move(targetCenter, _mapController.camera.zoom);
  }

  // === Logic Lưu địa điểm cá nhân (Giữ nguyên) ===
  void _savePrivateLocation(LatLng position) {
    print('UserID ${widget.userId} đang lưu vị trí cá nhân: $position');
    // TODO: Triển khai logic lưu lên Firestore
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu vị trí cá nhân!')));
  }

  // === Xử lý khi bấm vào Marker ĐEN (Đã thêm) ===
  void _handlePlaceMarkerTap(DocumentSnapshot placeDoc) {
    final data = placeDoc.data() as Map<String, dynamic>;
    final coordinates = data['location']?['coordinates'] as GeoPoint?;
    if (coordinates != null) {
      final latLng = LatLng(coordinates.latitude, coordinates.longitude);
      if (_longPressedLatLng != null) {
        setState(() {
          _longPressedLatLng = null;
        });
      } // Ẩn marker đỏ nếu có
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapOnLatLng(latLng);
      });
      // Gọi hàm Bottom Sheet ĐA NĂNG, truyền dữ liệu placeDoc
      _showLocationDetailsBottomSheet(latLng, existingPlace: placeDoc);
    }
  }

  // === Hàm Helper: Kiểm tra nhấn gần marker đen (Đã thêm) ===
  bool _isTapNearExistingMarker(LatLng tapLatLng) {
    const double thresholdDistance = 30; // Giảm khoảng cách xuống 30m
    for (var marker in _placeMarkers) {
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

  // --- HÀM HELPER ĐỂ VẼ 1 ẢNH (TỪ exploreScreen) ---
  Widget _buildImage(
    String imageUrl, {
    required double height,
    required double width,
    Widget? overlay,
    bool isTaller = false, // Thêm isTaller để xử lý StackFit
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8), // Có thể giảm bo góc nếu muốn
      child: Stack(
        // StackFit.expand chỉ hoạt động tốt khi widget cha có kích thước cố định
        // Nếu không, dùng StackFit.loose để tránh lỗi layout
        fit: isTaller ? StackFit.expand : StackFit.loose,
        children: [
          Image.network(
            imageUrl,
            height: height,
            width: width,
            fit: BoxFit.cover, // Luôn cover
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                height: height,
                width: width, // Đảm bảo kích thước
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2, // Mỏng hơn
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                height: height,
                width: width, // Đảm bảo kích thước
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.red, size: 30),
                ),
              );
            },
          ),
          // Overlay (dùng cho ảnh cuối cùng khi có nhiều hơn 4 ảnh)
          if (overlay != null) overlay,
        ],
      ),
    );
  }

  // --- HÀM HELPER ĐỂ VẼ GRID ẢNH (TỪ exploreScreen) ---
  Widget _buildPhotoGrid(List<dynamic> imageUrls) {
    // Chuyển đổi List<dynamic> thành List<String> một cách an toàn
    final images = imageUrls.whereType<String>().toList();
    final int count = images.length;

    if (count == 0)
      return const SizedBox.shrink(); // Không vẽ gì nếu không có ảnh

    const double totalHeight = 180; // Chiều cao cố định cho khu vực ảnh

    // Trường hợp 1 ảnh
    if (count == 1) {
      return SizedBox(
        height: totalHeight,
        width: double.infinity,
        child: _buildImage(
          images[0],
          height: totalHeight,
          width: double.infinity,
          isTaller: true, // Cho phép StackFit.expand
        ),
      );
    }

    // Trường hợp 2 ảnh
    if (count == 2) {
      return SizedBox(
        height: totalHeight,
        child: Row(
          children: [
            Expanded(
              child: _buildImage(
                images[0],
                height: totalHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
            const SizedBox(width: 4), // Khoảng cách nhỏ
            Expanded(
              child: _buildImage(
                images[1],
                height: totalHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
          ],
        ),
      );
    }

    // Trường hợp 3 ảnh (1 lớn, 2 nhỏ)
    if (count == 3) {
      return SizedBox(
        height: totalHeight,
        child: Row(
          children: [
            Expanded(
              // Ảnh lớn bên trái
              flex: 2, // Chiếm 2/3
              child: _buildImage(
                images[0],
                height: totalHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              // Cột 2 ảnh nhỏ bên phải
              flex: 1, // Chiếm 1/3
              child: Column(
                children: [
                  Expanded(
                    child: _buildImage(
                      images[1],
                      height: double.infinity,
                      width: double.infinity,
                      isTaller: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _buildImage(
                      images[2],
                      height: double.infinity,
                      width: double.infinity,
                      isTaller: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Trường hợp 4 ảnh trở lên (Grid 2x2, ảnh cuối có overlay +số)
    final int remainingCount = count - 4; // Số ảnh còn lại sau 4 ảnh đầu

    return SizedBox(
      height: totalHeight,
      child: Column(
        children: [
          // Hàng trên (ảnh 1, ảnh 2)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImage(
                    images[0],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildImage(
                    images[1],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Hàng dưới (ảnh 3, ảnh 4 + overlay)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImage(
                    images[2],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildImage(
                    // Ảnh thứ 4
                    images[3],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                    // Overlay chỉ hiển thị nếu còn ảnh (remainingCount > 0)
                    overlay: remainingCount > 0
                        ? Container(
                            // Lớp phủ màu đen mờ
                            color: Colors.black54,
                            child: Center(
                              // Căn giữa số ảnh còn lại
                              child: Text(
                                '+$remainingCount', // Hiển thị "+số"
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28, // Cỡ chữ to hơn
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : null, // Không có overlay nếu chỉ có 4 ảnh
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === Hàm Build chính (Đã cập nhật loading) ===
  @override
  Widget build(BuildContext context) {
    // Hiển thị loading chính nếu một trong hai chưa xong
    bool showOverallLoading = _isLoadingLocation || _isLoadingPlaces;

    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ thế giới (OSM)')),
      body: Stack(
        // Stack chính cho các lớp
        children: [
          // --- Lớp 1: Bản đồ hoặc Loading ---
          showOverallLoading
              ? _buildLoadingIndicator()
              : _buildMapLayer(), // Đã tách riêng lớp bản đồ
          // --- Lớp 2: Overlay Mờ (Khi có Marker đỏ) ---
          if (_longPressedLatLng != null) _buildBlurOverlay(),
        ],
      ),
    );
  }

  // --- Widget Helper ---

  Widget _buildLoadingIndicator() {
    return const Center(/* ... Giữ nguyên ... */);
  }

  // === XÂY DỰNG LỚP BẢN ĐỒ (Đã cập nhật hoàn chỉnh) ===
  Widget _buildMapLayer() {
    // KHÔNG dùng GestureDetector bao ngoài nữa
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentCenter,
        initialZoom: 18.0,
        keepAlive: true,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        cameraConstraint: CameraConstraint.contain(bounds: _vietnamBounds),
        // --- Logic khi nhấn giữ (Đã cập nhật) ---
        onLongPress: (tapPosition, latLng) {
          bool nearExisting = _isTapNearExistingMarker(latLng);
          if (!nearExisting) {
            // Chỉ xử lý nếu nhấn vào vùng trống
            // Ẩn marker cũ nếu có
            if (_longPressedLatLng != latLng && _longPressedLatLng != null) {
              setState(() {
                _longPressedLatLng = null;
              });
            }
            // Hiện marker đỏ mới
            setState(() {
              _longPressedLatLng = latLng;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _centerMapOnLatLng(latLng);
            });
            // Gọi hàm Bottom Sheet ĐA NĂNG, truyền NULL
            _showLocationDetailsBottomSheet(latLng, existingPlace: null);
          } else {
            print("Nhấn giữ gần marker đã có, bỏ qua.");
          }
        },
        // KHÔNG CÓ onTap ở đây nữa
      ),
      children: [
        // Lớp nền bản đồ OSM
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.nhom_3_damh_lttbdd',
          maxZoom: 19.0,
        ),
        // Lớp kẻ khung
        PolygonLayer(polygons: _countryPolygons),

        // === LỚP MARKER (HIỂN THỊ CẢ ĐEN VÀ ĐỎ) ===
        MarkerLayer(
          markers: [
            // 1. Marker đen (địa điểm đã có)
            ..._placeMarkers,
            // 2. Marker đỏ (khi nhấn giữ điểm mới)
            if (_longPressedLatLng != null)
              Marker(
                point: _longPressedLatLng!,
                width: 80,
                height: 80,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40.0,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // === XÂY DỰNG LỚP OVERLAY MỜ (Giữ nguyên) ===
  Widget _buildBlurOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _longPressedLatLng = null;
          });
        }, // Bấm mờ -> ẩn marker đỏ
        behavior: HitTestBehavior.opaque,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withOpacity(0.1)),
        ),
      ),
    );
  }

  // === HÀM HIỂN THỊ BOTTOM SHEET (ĐA MỤC ĐÍCH - ĐÃ SỬA TÊN GỌI VÀ NÂNG CẤP) ===
  void _showLocationDetailsBottomSheet(
    LatLng position, {
    DocumentSnapshot? existingPlace,
  }) {
    // --- Hàm Helper: Lấy tên đường + thành phố (cho địa điểm mới) ---
    Future<String> _getStreetAndCity(LatLng pos) async {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final Placemark p = placemarks.first;
          String street = p.thoroughfare ?? '';
          String city =
              p.administrativeArea
                  ?.replaceFirst('Thành phố ', '')
                  .replaceFirst('Tỉnh ', '') ??
              '';
          if (street.isNotEmpty && city.isNotEmpty) return '$street, $city';
          if (city.isNotEmpty) return city;
        }
      } catch (e) {
        print("Lỗi geocoding cho bottom sheet title: $e");
      }
      return 'Vị trí chưa được khám phá';
    }

    // --- Hàm Helper: Vẽ nút Icon ---
    Widget _buildIconSheetButton({
      required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
    }) {
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50), // Bo tròn
          child: Container(
            padding: const EdgeInsets.all(10), // Padding nhỏ hơn
            decoration: BoxDecoration(
              color: color.withOpacity(0.15), // Nền nhẹ
              shape: BoxShape.circle, // Hình tròn
            ),
            child: Icon(icon, color: color, size: 24), // Icon nhỏ hơn
          ),
        ),
      );
    }
    // -------------------------------------------------------------------------------------

    // Xác định trạng thái và lấy dữ liệu
    bool isNewPlace = existingPlace == null;
    Map<String, dynamic>? placeData = !isNewPlace
        ? existingPlace!.data() as Map<String, dynamic>
        : null;
    String? placeName = !isNewPlace ? placeData!['name'] as String? : null;
    List<dynamic> images = !isNewPlace ? (placeData!['images'] ?? []) : [];
    String? placeId = !isNewPlace ? existingPlace!.id : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // --- Bố cục 3 dòng bạn mô tả ---
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // === DÒNG 1: TÊN + NÚT ICON (CODE ĐẦY ĐỦ) ===
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Căn giữa theo chiều dọc
                children: [
                  // --- Cột 1: Tên địa điểm ---
                  Expanded(
                    // Chiếm khoảng 70-75%
                    flex: 3,
                    child: FutureBuilder<String>(
                      future: isNewPlace
                          ? _getStreetAndCity(position)
                          : Future.value(placeName ?? 'Địa điểm'),
                      builder: (context, titleSnapshot) {
                        return Text(
                          // Chỉ còn Text, không cần Column vì tọa độ bỏ đi
                          titleSnapshot.data ??
                              (isNewPlace
                                  ? 'Vị trí chưa khám phá'
                                  : 'Đang tải tên...'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1, // Chỉ 1 dòng
                          overflow: TextOverflow.ellipsis, // Hiển thị ...
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16), // Khoảng cách giữa 2 cột
                  // --- Cột 2: Các nút Icon ---
                  Row(
                    mainAxisSize: MainAxisSize.min, // Chiếm khoảng 25-30%
                    children: [
                      // Nút Thêm mới (Chỉ hiện khi là điểm mới)
                      if (isNewPlace)
                        _buildIconSheetButton(
                          icon: Icons.add_location_alt_outlined,
                          label: 'Thêm mới',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPlaceScreen(
                                  initialLatLng: position,
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          },
                        ),
                      // Khoảng cách (có điều kiện)
                      if (isNewPlace) const SizedBox(width: 8),

                      // Nút Lưu cá nhân (Luôn hiện)
                      _buildIconSheetButton(
                        icon: Icons.bookmark_add_outlined,
                        label: 'Lưu cá nhân',
                        color: Colors.teal,
                        onTap: () {
                          Navigator.pop(context);
                          _savePrivateLocation(position);
                          setState(() {
                            _longPressedLatLng = null;
                          });
                        },
                      ),

                      // Nút Đăng Review (Chỉ hiện khi là điểm cũ)
                      if (!isNewPlace && placeId != null) ...[
                        const SizedBox(width: 8), // Khoảng cách
                        _buildIconSheetButton(
                          icon: Icons.rate_review_outlined,
                          label: 'Viết Review',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pop(
                              context,
                            ); // Đóng bottom sheet hiện tại

                            // === THÊM NAVIGATOR.PUSH ===
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckinScreen(
                                  currentUserId:
                                      widget.userId, // Truyền userId hiện tại
                                  initialPlaceId:
                                      placeId, // <<< Truyền placeId đã chọn
                                ),
                              ),
                            );
                            // ===========================

                            // Không cần setState ở đây nữa vì bottom sheet đã đóng
                            // setState(() { _longPressedLatLng = null; });
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              // ===========================================
              const SizedBox(height: 24),

              // === DÒNG 2: ẢNH ===
              Text(
                'Ảnh',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildImageSection(
                images,
              ), // Gọi hàm xây dựng phần ảnh (Giữ nguyên)
              const SizedBox(height: 24),

              // === DÒNG 3: NÚT ĐĂNG BÀI REVIEW (Dạng viên thuốc) ===
              // Chỉ hiện khi là địa điểm đã có
              if (!isNewPlace && placeId != null)
                SizedBox(
                  // Cho nút rộng hết cỡ
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Đóng bottom sheet hiện tại

                      // === THÊM NAVIGATOR.PUSH ===
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckinScreen(
                            currentUserId: widget.userId, // Truyền userId
                            initialPlaceId: placeId, // <<< Truyền placeId
                          ),
                        ),
                      );
                      // ===========================

                      // Không cần setState ở đây
                      // setState(() { _longPressedLatLng = null; });
                    },
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Đăng bài review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // Màu cam vàng
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(), // Hình viên thuốc
                    ),
                  ),
                ),

              // ======================================================

              // === DÒNG 4: CHỨC NĂNG KHÁC (TODO - Giữ nguyên comment) ===
              // Center(child: Text('(Các chức năng khác)', style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 10), // Khoảng trống dưới cùng
            ],
          ),
        );
      },
    ).whenComplete(() {
      // Callback khi đóng sheet (Giữ nguyên)
      if (_longPressedLatLng != null && mounted) {
        setState(() {
          _longPressedLatLng = null;
        });
      }
    });
  }

  // === HÀM HELPER: XÂY DỰNG PHẦN HIỂN THỊ ẢNH (Giữ nguyên) ===
  Widget _buildImageSection(List<dynamic> imageUrls) {
    // Chuyển đổi an toàn sang List<String>
    final images = imageUrls.whereType<String>().toList();

    if (images.isEmpty) {
      // Placeholder khi không có ảnh (Giữ nguyên)
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Hãy là người đầu tiên khám phá ra vị trí này!',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      // === GỌI HÀM VẼ GRID MỚI ===
      return _buildPhotoGrid(images);
      // ===========================
    }
  }
} // End of _WorldMapScreenState
