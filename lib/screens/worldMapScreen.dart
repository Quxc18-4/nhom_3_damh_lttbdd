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
import 'package:nhom_3_damh_lttbdd/model/category_model.dart'; // <<< Sửa đường dẫn nếu cần
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // <<< Sửa đường dẫn nếu cần

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

  // === CÁC STATE MỚI CHO TÌM KIẾM VÀ DANH MỤC ===
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<CategoryModel> _allCategories = []; // Lưu tất cả danh mục
  bool _isLoadingCategories = true; // Loading cho danh mục
  bool _isCategoryBarVisible = false; // Ẩn/hiện thanh danh mục
  CategoryModel? _selectedCategory; // Danh mục đang được lọc

  List<DocumentSnapshot> _searchResults = []; // Lưu kết quả tìm kiếm

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
    // === THÊM CÁC LISTENER NÀY ===
    // Listener cho thanh tìm kiếm
    _searchController.addListener(_onSearchChanged);
    // Listener để ẩn/hiện danh sách kết quả
    _searchFocusNode.addListener(() {
      setState(() {
        // Cập nhật UI khi focus thay đổi (để ẩn/hiện list)
      });
    });
    // ============================
  }

  // === THÊM HÀM NÀY ===
  @override
  void dispose() {
    _mapController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // === Gộp các lệnh gọi bất đồng bộ ban đầu ===
  Future<void> _initializeMapData() async {
    // Chạy song song
    await Future.wait([
      _determinePosition(),
      _fetchPlacesFromFirestore(),
      _fetchCategories(), // <<< THÊM HÀM TẢI CATEGORY
    ]);
    // Không cần setState loading chung ở đây vì mỗi hàm tự quản lý state riêng
  }

  // === THÊM HÀM MỚI NÀY (Giống addPlaceRequest.dart) ===
  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() => _isLoadingCategories = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();
      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
      categories.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _allCategories = categories;
        });
      }
    } catch (e) {
      print("Lỗi fetch categories: $e");
      _showSnackBar('Không thể tải danh sách danh mục: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
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
  // === SỬA HÀM NÀY ===
  Future<void> _fetchPlacesFromFirestore() async {
    if (!mounted) return;
    setState(() => _isLoadingPlaces = true);
    try {
      QuerySnapshot placesSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .get();
      _fetchedPlaces = placesSnapshot.docs; // <<< CHỈ LƯU DATA

      if (mounted) {
        setState(() {
          _isLoadingPlaces = false;
          _updatePlaceMarkers(); // <<< GỌI HÀM TẠO MARKER
        });
      }
    } catch (e) {
      print("Lỗi tải địa điểm từ Firestore: $e");
      if (mounted) {
        _showSnackBar('Lỗi tải danh sách địa điểm: $e', isError: true);
        setState(() => _isLoadingPlaces = false);
      }
    }
  }

  // === THÊM HÀM MỚI NÀY (Quan trọng) ===
  // Hàm này tạo/cập nhật danh sách marker dựa trên bộ lọc
  void _updatePlaceMarkers() {
    List<Marker> markers = [];

    // Lọc _fetchedPlaces nếu có _selectedCategory
    final List<DocumentSnapshot> placesToBuild = _selectedCategory == null
        ? _fetchedPlaces // Không lọc, hiển thị tất cả
        : _fetchedPlaces.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final categoryIds = data['categories'] as List<dynamic>? ?? [];
            return categoryIds.contains(_selectedCategory!.id);
          }).toList();

    // Tạo marker từ danh sách đã lọc
    for (var placeDoc in placesToBuild) {
      final data = placeDoc.data() as Map<String, dynamic>;
      final coordinates = data['location']?['coordinates'] as GeoPoint?;
      final placeName = data['name'] as String? ?? 'Địa điểm';

      if (coordinates != null) {
        markers.add(
          Marker(
            point: LatLng(coordinates.latitude, coordinates.longitude),
            width: 35,
            height: 35,
            child: GestureDetector(
              onTap: () => _handlePlaceMarkerTap(placeDoc),
              child: Tooltip(
                message: placeName,
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

    if (mounted) {
      setState(() {
        _placeMarkers = markers;
      });
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

  // === THÊM CÁC HÀM MỚI NÀY ===

  // Được gọi mỗi khi nội dung thanh tìm kiếm thay đổi
  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
      });
    } else {
      _performSearch(_searchController.text);
    }
  }

  // Hàm thực hiện tìm kiếm
  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final String lowerCaseQuery = query.toLowerCase();

    // Tìm trên danh sách địa điểm đã tải
    final results = _fetchedPlaces.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name'] as String? ?? '';
      return name.toLowerCase().contains(lowerCaseQuery);
    }).toList();

    setState(() {
      // Giới hạn 5 kết quả
      _searchResults = results.take(5).toList();
    });
  }

  // Hàm xử lý khi bấm vào 1 kết quả tìm kiếm
  void _onSearchResultTap(DocumentSnapshot placeDoc) {
    _searchController.clear(); // Xóa text
    _searchFocusNode.unfocus(); // Bỏ focus
    setState(() {
      _searchResults = [];
    });

    // Dùng lại hàm _handlePlaceMarkerTap để mở bottom sheet
    _handlePlaceMarkerTap(placeDoc);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : null,
        ),
      );
    }
  }

  // === THÊM CÁC HÀM WIDGET MỚI NÀY ===

  // Widget chính cho LỚP 3
  Widget _buildSearchAndFilterUI() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 15,
      right: 15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // === Hàng 1: Thanh tìm kiếm ===
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Nút 3 gạch (Category)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    setState(() {
                      _isCategoryBarVisible = !_isCategoryBarVisible;
                    });
                  },
                  color: Colors.grey[700],
                ),
                // Thanh search
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                // Nút Xóa (nếu đang gõ)
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
              ],
            ),
          ),

          // === Hàng 2: Thanh danh mục (ẩn/hiện) ===
          _buildCategoryBar(),
        ],
      ),
    );
  }

  // Widget cho thanh danh mục (Hàng 2)
  Widget _buildCategoryBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isCategoryBarVisible ? 50 : 0, // << Animates height
      margin: const EdgeInsets.only(top: 8),
      // XÓA BỎ OverflowBox, thay bằng ClipRRect
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25), // Bo góc cho chính thanh cuộn
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Thêm padding dọc để các chip không bị sát viền trên/dưới
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Nút "Tất cả" (để xóa filter)
              Padding(
                // Thêm padding trái để nó không bị dính vào nút 3 gạch
                padding: const EdgeInsets.only(right: 8.0, left: 2.0),
                child: ActionChip(
                  label: const Text('Tất cả'),
                  backgroundColor: _selectedCategory == null
                      ? Colors.orange.shade200
                      : Colors.white,
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _updatePlaceMarkers(); // Cập nhật lại map
                    });
                  },
                  // === THÊM SHAPE ĐỂ BO TRÒN ===
                  shape: StadiumBorder(
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),

              // Render tối đa 10 danh mục
              ..._allCategories.take(10).map((category) {
                final bool isSelected = _selectedCategory?.id == category.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(category.name),
                    // avatar: Icon(Icons.restaurant), // Ví dụ
                    backgroundColor: isSelected
                        ? Colors.orange.shade200
                        : Colors.white,
                    onPressed: () {
                      setState(() {
                        _selectedCategory = category;
                        _updatePlaceMarkers(); // Cập nhật lại map
                      });
                    },
                    // === THÊM SHAPE ĐỂ BO TRÒN ===
                    shape: StadiumBorder(
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                );
              }),

              // Nút "Dấu cộng" nếu có > 10 danh mục
              if (_allCategories.length > 10)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: const Icon(Icons.add, size: 18),
                    backgroundColor: Colors.white,
                    onPressed: _showAllCategoriesBottomSheet,
                    // === THÊM SHAPE ĐỂ BO TRÒN ===
                    shape: StadiumBorder(
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget cho LỚP 4: Danh sách kết quả
  Widget _buildSearchResultsList() {
    // Chỉ hiện khi có focus VÀ có kết quả
    if (!_searchFocusNode.hasFocus || _searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    // Vị trí của thanh tìm kiếm
    final double searchBarHeight =
        60 + (MediaQuery.of(context).padding.top + 10);

    return Positioned(
      top: searchBarHeight, // Ngay dưới thanh tìm kiếm
      left: 20,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final doc = _searchResults[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Không có tên';
              final address =
                  data['location']?['fullAddress'] ?? 'Không có địa chỉ';

              return ListTile(
                // Giống ảnh 2: Icon location
                leading: Icon(Icons.location_pin, color: Colors.grey[600]),
                // Dữ liệu: Tên - Địa chỉ
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  _onSearchResultTap(doc);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // === THÊM HÀM MỚI NÀY (cho nút +) ===
  void _showAllCategoriesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Tất cả danh mục',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _allCategories.length,
                      itemBuilder: (context, index) {
                        final category = _allCategories[index];
                        final bool isSelected =
                            _selectedCategory?.id == category.id;
                        return ListTile(
                          title: Text(category.name),
                          trailing: isSelected
                              ? Icon(Icons.check, color: Colors.orange)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                              _updatePlaceMarkers(); // Cập nhật map
                            });
                            Navigator.pop(context); // Đóng bottom sheet
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
      // Bỏ AppBar cũ
      // appBar: AppBar(title: const Text('Bản đồ thế giới (OSM)')),
      body: Stack(
        // Stack chính cho các lớp
        children: [
          // --- Lớp 1: Bản đồ hoặc Loading ---
          showOverallLoading
              ? _buildLoadingIndicator()
              : _buildMapLayer(), // Đã tách riêng lớp bản đồ
          // --- Lớp 2: Overlay Mờ (Khi có Marker đỏ) ---
          if (_longPressedLatLng != null) _buildBlurOverlay(),

          // --- LỚP 3: UI TÌM KIẾM VÀ DANH MỤC (MỚI) ---
          _buildSearchAndFilterUI(),

          // --- LỚP 4: DANH SÁCH KẾT QUẢ TÌM KIẾM (MỚI) ---
          _buildSearchResultsList(),
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
          String street = p.thoroughfare ?? 'Không xác định';

          // === LOGIC CHUẨN HÓA THÀNH PHỐ MỚI ===
          String rawCityName = p.administrativeArea ?? '';
          String? mergedId = getMergedProvinceIdFromGeolocator(rawCityName);
          String city = "Không xác định"; // Default

          if (mergedId != null) {
            city = formatProvinceIdToName(mergedId);
          }
          // ===================================

          if (street != 'Không xác định' && city != 'Không xác định')
            return '$street, $city';
          if (city != 'Không xác định') return city;
          if (street != 'Không xác định') return street;
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
