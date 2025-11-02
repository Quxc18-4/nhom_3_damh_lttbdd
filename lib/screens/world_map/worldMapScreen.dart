// File: screens/world_map/worldMapScreen.dart

// --- CÁC IMPORT CẦN THIẾT ---
import 'package:flutter/material.dart'; // Import thư viện Material Design cơ bản của Flutter (Widgets, Themes, etc.)
import 'package:flutter_map/flutter_map.dart'; // Import thư viện chính để hiển thị bản đồ
import 'package:latlong2/latlong.dart'; // Import thư viện để xử lý tọa độ (kiểu dữ liệu LatLng)
import 'package:cloud_firestore/cloud_firestore.dart'; // Import thư viện Firebase Firestore để tương tác với CSDL
// import 'dart:math'; // Import thư viện toán học (đang bị comment, không dùng)

// Imports các màn hình điều hướng (để chuyển trang)
import 'package:nhom_3_damh_lttbdd/screens/add_places/addPlaceRequest.dart'; // Màn hình thêm địa điểm mới
import 'package:nhom_3_damh_lttbdd/screens/add_checkins/checkinScreen.dart'; // Màn hình tạo review/check-in

// Imports các file đã refactor (tách code)
import 'package:nhom_3_damh_lttbdd/model/category_model.dart'; // Model (lớp) định nghĩa cấu trúc dữ liệu Category
// import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // (Đang bị comment, không dùng ở đây, có thể dùng trong service)
import 'service/world_map_service.dart'; // Lớp service xử lý logic nghiệp vụ (gọi API, Firestore)
import 'helper/map_helper.dart'; // Các hàm hỗ trợ tính toán liên quan đến bản đồ
import 'widget/location_details_modal.dart'; // Widget UI cho bottom sheet chi tiết địa điểm
import 'widget/map_components.dart'; // Các widget UI nhỏ dùng chung (Loading, Blur)
// (Không cần import photo_grid.dart vì nó được gọi bởi location_details_modal.dart)

// --- ĐỊNH NGHĨA WIDGET ---

/// WorldMapScreen là một StatefulWidget:
/// Nó là một widget có trạng thái (state) có thể thay đổi theo thời gian
/// (ví dụ: vị trí người dùng, danh sách địa điểm, marker đang chọn).
class WorldMapScreen extends StatefulWidget {
  // Kiểu dữ liệu: String (final: không thể thay đổi sau khi widget được khởi tạo)
  // Mục đích: Lưu trữ ID của người dùng đang đăng nhập.
  // Luồng dữ liệu: Được truyền vào từ widget cha khi điều hướng đến màn hình này.
  final String userId;

  // Constructor (hàm khởi tạo) của widget.
  // Yêu cầu bắt buộc phải có `userId` khi tạo WorldMapScreen.
  const WorldMapScreen({Key? key, required this.userId}) : super(key: key);

  @override
  // Hàm này tạo ra đối tượng State, nơi chứa toàn bộ trạng thái và logic của widget.
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

// Lớp _WorldMapScreenState chứa toàn bộ trạng thái và logic của WorldMapScreen.
class _WorldMapScreenState extends State<WorldMapScreen> {
  // === Service ===
  // Kiểu dữ liệu: WorldMapService (final: chỉ khởi tạo 1 lần)
  // Mục đích: Cung cấp một đối tượng để gọi các hàm logic (fetch data, get location).
  final WorldMapService _service = WorldMapService();

  // === State: Map & Vị trí ===
  // Kiểu dữ liệu: MapController (final: chỉ khởi tạo 1 lần)
  // Mục đích: Điều khiển bản đồ một cách lập trình (ví dụ: di chuyển, zoom).
  final MapController _mapController = MapController();

  // Kiểu dữ liệu: bool (có thể thay đổi)
  // Mục đích: Cờ (flag) để theo dõi trạng thái tải vị trí ban đầu của người dùng.
  // Luồng dữ liệu: `true` khi bắt đầu, `false` khi có kết quả (thành công hoặc lỗi).
  bool _isLoadingLocation = true;

  // Kiểu dữ liệu: LatLng (có thể thay đổi)
  // Mục đích: Lưu trữ vị trí trung tâm hiện tại của bản đồ.
  // Luồng dữ liệu: Mặc định là Hà Nội. Sẽ được cập nhật bằng vị trí GPS của người dùng
  // (nếu thành công) trong `_determinePosition`.
  LatLng _currentCenter = const LatLng(21.0285, 105.8542);

  // Kiểu dữ liệu: LatLng? (nullable - có thể là null)
  // Mục đích: Lưu tọa độ khi người dùng nhấn giữ vào bản đồ (để tạo marker đỏ).
  // Luồng dữ liệu: `null` ban đầu. Được gán giá trị trong `onLongPress` của FlutterMap.
  // Trở về `null` khi bottom sheet bị đóng hoặc bấm ra ngoài.
  LatLng? _longPressedLatLng;

  // === State: Tìm kiếm & Danh mục ===
  // Kiểu dữ liệu: TextEditingController (final: chỉ khởi tạo 1 lần)
  // Mục đích: Quản lý nội dung (text) của thanh tìm kiếm.
  final TextEditingController _searchController = TextEditingController();

  // Kiểu dữ liệu: FocusNode (final: chỉ khởi tạo 1 lần)
  // Mục đích: Quản lý trạng thái focus (đang gõ / không gõ) của thanh tìm kiếm.
  final FocusNode _searchFocusNode = FocusNode();

  // Kiểu dữ liệu: List<CategoryModel> (danh sách các đối tượng Category)
  // Mục đích: Lưu trữ danh sách tất cả danh mục (categories) lấy từ Firestore.
  // Luồng dữ liệu: Rỗng ban đầu. Được điền dữ liệu trong `_fetchCategories`.
  List<CategoryModel> _allCategories = [];

  // Kiểu dữ liệu: bool
  // Mục đích: Cờ (flag) theo dõi trạng thái tải danh mục.
  bool _isLoadingCategories = true;

  // Kiểu dữ liệu: bool
  // Mục đích: Cờ (flag) kiểm soát việc hiển thị hay ẩn thanh danh mục.
  bool _isCategoryBarVisible = false;

  // Kiểu dữ liệu: CategoryModel? (nullable)
  // Mục đích: Lưu trữ danh mục đang được chọn (để lọc marker).
  // Luồng dữ liệu: `null` nghĩa là "Tất cả". Được gán giá trị khi bấm vào ActionChip.
  CategoryModel? _selectedCategory;

  // Kiểu dữ liệu: List<DocumentSnapshot> (danh sách các document thô từ Firestore)
  // Mục đích: Lưu trữ kết quả tìm kiếm địa điểm (chỉ 5 kết quả đầu).
  // Luồng dữ liệu: Được cập nhật trong `_performSearch`.
  List<DocumentSnapshot> _searchResults = [];

  // === State: Places & Markers ===
  // Kiểu dữ liệu: List<DocumentSnapshot>
  // Mục đích: Lưu trữ *tất cả* địa điểm (places) lấy từ Firestore (bộ đệm local).
  // Luồng dữ liệu: Rỗng ban đầu. Được điền dữ liệu trong `_fetchPlacesFromFirestore`.
  List<DocumentSnapshot> _fetchedPlaces = [];

  // Kiểu dữ liệu: List<Marker> (danh sách các widget Marker của flutter_map)
  // Mục đích: Lưu trữ danh sách các marker (icon địa điểm) sẽ được vẽ lên bản đồ.
  // Luồng dữ liệu: Rỗng ban đầu. Được cập nhật (tạo mới) trong `_updatePlaceMarkers`.
  List<Marker> _placeMarkers = [];

  // Kiểu dữ liệu: bool
  // Mục đích: Cờ (flag) theo dõi trạng thái tải danh sách địa điểm.
  bool _isLoadingPlaces = true;

  // === Dữ liệu giới hạn bản đồ ===
  // Kiểu dữ liệu: LatLngBounds (khu vực hình chữ nhật)
  // Mục đích: Giới hạn camera của bản đồ, không cho phép kéo ra ngoài lãnh thổ VN.
  final LatLngBounds _vietnamBounds = LatLngBounds(
    const LatLng(8.18, 102.14), // Góc Tây Nam
    const LatLng(23.39, 109.46), // Góc Đông Bắc
  );

  // === Polygon mẫu (Giữ nguyên) ===
  // Kiểu dữ liệu: List<Polygon> (danh sách các vùng đa giác)
  // Mục đích: Dữ liệu mẫu để vẽ một vùng màu xanh lên bản đồ.
  final List<Polygon> _countryPolygons = [
    Polygon(
      points: [
        LatLng(16.1, 108.1),
        LatLng(16.1, 108.2),
        LatLng(16.0, 108.2),
        LatLng(16.0, 108.1),
      ],
      color: Colors.blue.withOpacity(0.3), // Màu nền
      borderColor: Colors.blue, // Màu viền
      borderStrokeWidth: 2, // Độ dày viền
    ),
  ];

  // === VÒNG ĐỜI WIDGET (LIFECYCLE) ===

  @override
  // Hàm `initState` được gọi 1 lần duy nhất khi widget được tạo.
  void initState() {
    super.initState(); // Luôn gọi `super.initState()` đầu tiên
    _initializeMapData(); // Bắt đầu tải tất cả dữ liệu cần thiết
    _searchController.addListener(_onSearchChanged); // Lắng nghe sự kiện gõ chữ
    _searchFocusNode.addListener(() {
      // Lắng nghe sự kiện focus (bấm vào/bấm ra)
      setState(() {
        // Cập nhật UI (để ẩn/hiện list kết quả tìm kiếm)
        // Gọi setState rỗng để kích hoạt build() lại
      });
    });
  }

  @override
  // Hàm `dispose` được gọi khi widget bị gỡ khỏi cây widget (ví dụ: back).
  void dispose() {
    _mapController.dispose(); // Hủy controller bản đồ để tránh rò rỉ bộ nhớ
    // Hủy listener trước khi hủy controller
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose(); // Hủy controller text
    _searchFocusNode.dispose(); // Hủy focus node
    super.dispose(); // Luôn gọi `super.dispose()` cuối cùng
  }

  // === LOGIC TẢI DỮ LIỆU (ĐÃ GỌI SERVICE) ===

  // Kiểu dữ liệu: Future<void> (hàm bất đồng bộ, không trả về giá trị)
  // Mục đích: Hàm điều phối việc tải dữ liệu ban đầu.
  Future<void> _initializeMapData() async {
    // `Future.wait` cho phép chạy 3 hàm bất đồng bộ song song.
    // Quá trình chỉ hoàn tất khi *cả 3* hàm đều hoàn tất.
    await Future.wait([
      _determinePosition(), // Lấy vị trí GPS
      _fetchPlacesFromFirestore(), // Lấy danh sách địa điểm
      _fetchCategories(), // Lấy danh sách danh mục
    ]);
  }

  // Kiểu dữ liệu: Future<void>
  // Mục đích: Tải danh sách danh mục từ service.
  Future<void> _fetchCategories() async {
    // Kiểm tra xem widget còn tồn tại không (tránh lỗi `setState` khi đã dispose).
    if (!mounted) return;
    // Cập nhật state: Bắt đầu loading
    setState(() => _isLoadingCategories = true);
    try {
      // Gọi hàm từ service (đây là lời gọi bất đồng bộ).
      final categories = await _service.fetchCategories();
      // Nếu widget còn tồn tại sau khi gọi xong...
      if (mounted) {
        // Cập nhật state với dữ liệu mới.
        setState(() {
          _allCategories = categories;
        });
      }
    } catch (e) {
      // Xử lý nếu có lỗi xảy ra trong quá trình fetch.
      _showSnackBar('Không thể tải danh sách danh mục: $e', isError: true);
    } finally {
      // Khối `finally` luôn chạy, dù thành công hay thất bại.
      if (mounted) {
        // Cập nhật state: Kết thúc loading.
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  // Kiểu dữ liệu: Future<void>
  // Mục đích: Lấy vị trí GPS hiện tại của người dùng.
  Future<void> _determinePosition() async {
    try {
      // Gọi hàm từ service (đây là lời gọi bất đồng bộ, có thể mất vài giây).
      final position = await _service.determinePosition();
      // Nếu widget còn tồn tại...
      if (mounted) {
        // Cập nhật state: Gán vị trí mới và tắt cờ loading.
        setState(() {
          _currentCenter = position; // Cập nhật vị trí trung tâm bản đồ
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      // Xử lý nếu có lỗi (ví dụ: người dùng từ chối quyền, tắt GPS).
      if (mounted) {
        _showSnackBar(
          'Không thể lấy vị trí: $e. Dùng vị trí mặc định.',
          isError: true,
        );
        // Cập nhật state: Tắt cờ loading (dù lỗi vẫn phải tắt).
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Kiểu dữ liệu: Future<void>
  // Mục đích: Tải *tất cả* địa điểm từ Firestore.
  Future<void> _fetchPlacesFromFirestore() async {
    if (!mounted) return;
    // Cập nhật state: Bắt đầu loading.
    setState(() => _isLoadingPlaces = true);
    try {
      // Gọi hàm từ service.
      _fetchedPlaces = await _service.fetchPlaces();
      // Nếu widget còn tồn tại...
      if (mounted) {
        // Cập nhật state: Tắt loading và gọi hàm tạo marker.
        setState(() {
          _isLoadingPlaces = false;
          _updatePlaceMarkers(); // Tạo marker dựa trên dữ liệu vừa tải
        });
      }
    } catch (e) {
      // Xử lý lỗi.
      if (mounted) {
        _showSnackBar('Lỗi tải danh sách địa điểm: $e', isError: true);
        setState(() => _isLoadingPlaces = false);
      }
    }
  }

  // === LOGIC TẠO MARKER (Giữ nguyên) ===

  // Kiểu dữ liệu: void (hàm đồng bộ)
  // Mục đích: Tạo/tái tạo danh sách `_placeMarkers` dựa trên state hiện tại.
  void _updatePlaceMarkers() {
    // Khởi tạo 1 list marker rỗng
    List<Marker> markers = [];

    // Xác định nguồn dữ liệu:
    // Nếu không chọn category nào (`_selectedCategory == null`)...
    final List<DocumentSnapshot> placesToBuild = _selectedCategory == null
        ? _fetchedPlaces // Dùng *tất cả* địa điểm đã fetch.
        : _fetchedPlaces.where((doc) {
            // Ngược lại, lọc `_fetchedPlaces`.
            // Lấy dữ liệu từ DocumentSnapshot.
            final data = doc.data() as Map<String, dynamic>;
            // Lấy mảng 'categories' (ID) từ document, an toàn (nếu null thì là mảng rỗng).
            final categoryIds = data['categories'] as List<dynamic>? ?? [];
            // Kiểm tra xem mảng ID này có chứa ID của category đang chọn không.
            return categoryIds.contains(_selectedCategory!.id);
          }).toList(); // Chuyển kết quả lọc (Iterable) về List.

    // Lặp qua danh sách địa điểm (đã được lọc).
    for (var placeDoc in placesToBuild) {
      // Lấy dữ liệu thô (Map).
      final data = placeDoc.data() as Map<String, dynamic>;
      // Lấy trường 'location.coordinates' (kiểu GeoPoint của Firestore).
      final coordinates = data['location']?['coordinates'] as GeoPoint?;
      // Lấy trường 'name', nếu null thì dùng 'Địa điểm'.
      final placeName = data['name'] as String? ?? 'Địa điểm';

      // Chỉ tạo marker nếu tọa độ tồn tại.
      if (coordinates != null) {
        // Thêm một đối tượng Marker vào danh sách.
        markers.add(
          Marker(
            // Chuyển đổi GeoPoint (Firestore) -> LatLng (flutter_map).
            point: LatLng(coordinates.latitude, coordinates.longitude),
            width: 35, // Kích thước marker
            height: 35,
            // `child` là widget sẽ được vẽ
            child: GestureDetector(
              // Xử lý sự kiện khi bấm vào marker.
              onTap: () => _handlePlaceMarkerTap(placeDoc),
              // Tooltip hiện ra khi di chuột/nhấn giữ (trên web/desktop).
              child: Tooltip(
                message: placeName, // Hiển thị tên địa điểm
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7), // Nền đen mờ
                    shape: BoxShape.circle, // Hình tròn
                  ),
                  child: const Icon(
                    Icons.location_on, // Icon mỏ neo
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
    // Sau khi tạo xong list marker mới, kiểm tra widget còn tồn tại không.
    if (mounted) {
      // Cập nhật state: Gán list mới cho `_placeMarkers` để Flutter vẽ lại.
      setState(() {
        _placeMarkers = markers;
      });
    }
  }

  // === LOGIC XỬ LÝ SỰ KIỆN (Giữ nguyên) ===

  // Kiểu dữ liệu: void
  // Mục đích: Di chuyển tâm bản đồ đến 1 tọa độ mới.
  void _centerMapOnLatLng(LatLng targetCenter) {
    // Sử dụng MapController để di chuyển.
    // `_mapController.camera.zoom` giữ nguyên mức zoom hiện tại.
    _mapController.move(targetCenter, _mapController.camera.zoom);
  }

  // Kiểu dữ liệu: void
  // Mục đích: Xử lý logic khi người dùng bấm "Lưu cá nhân".
  void _savePrivateLocation(LatLng position) {
    // In ra log (thay `widget.userId` để truy cập `userId` từ `StatefulWidget`).
    print('UserID ${widget.userId} đang lưu vị trí cá nhân: $position');
    // TODO: Triển khai logic lưu lên Firestore (chưa làm).
    _showSnackBar('Đã lưu vị trí cá nhân!'); // Thông báo cho người dùng.
  }

  // Kiểu dữ liệu: void
  // Tham số: DocumentSnapshot (dữ liệu của địa điểm đã bấm)
  // Mục đích: Xử lý khi bấm vào marker địa điểm *đã có*.
  void _handlePlaceMarkerTap(DocumentSnapshot placeDoc) {
    final data = placeDoc.data() as Map<String, dynamic>;
    final coordinates = data['location']?['coordinates'] as GeoPoint?;
    if (coordinates != null) {
      // Chuyển đổi tọa độ
      final latLng = LatLng(coordinates.latitude, coordinates.longitude);
      // Nếu đang có marker đỏ (nhấn giữ) thì xóa nó đi.
      if (_longPressedLatLng != null) {
        setState(() {
          _longPressedLatLng = null;
        });
      }
      // `WidgetsBinding.instance.addPostFrameCallback`
      // Mục đích: Chạy 1 hàm *sau khi* frame hiện tại đã được vẽ xong.
      // Lý do: Đảm bảo `_showLocationDetailsBottomSheet` được gọi *trước*,
      // sau đó map mới di chuyển (tránh giật/lag).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapOnLatLng(latLng); // Di chuyển map tới marker
      });
      // Hiển thị bottom sheet với dữ liệu của địa điểm đã có.
      _showLocationDetailsBottomSheet(latLng, existingPlace: placeDoc);
    }
  }

  // === LOGIC TÌM KIẾM (Giữ nguyên) ===

  // Kiểu dữ liệu: void
  // Mục đích: Hàm callback được gọi mỗi khi nội dung thanh tìm kiếm thay đổi.
  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      // Nếu ô tìm kiếm rỗng
      setState(() {
        _searchResults = []; // Xóa kết quả
      });
    } else {
      // Nếu có chữ
      _performSearch(_searchController.text); // Thực hiện tìm kiếm
    }
  }

  // Kiểu dữ liệu: void
  // Mục đích: Lọc danh sách `_fetchedPlaces` dựa trên `query`.
  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    // Chuẩn hóa query về chữ thường
    final String lowerCaseQuery = query.toLowerCase();
    // Lọc trên danh sách đã tải về (tìm kiếm local)
    final results = _fetchedPlaces.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name'] as String? ?? '';
      // So sánh tên (đã chuẩn hóa) với query (đã chuẩn hóa)
      return name.toLowerCase().contains(lowerCaseQuery);
    }).toList();
    // Cập nhật state: Chỉ lấy 5 kết quả đầu tiên.
    setState(() {
      _searchResults = results.take(5).toList();
    });
  }

  // Kiểu dữ liệu: void
  // Mục đích: Xử lý khi bấm vào 1 item trong danh sách kết quả tìm kiếm.
  void _onSearchResultTap(DocumentSnapshot placeDoc) {
    _searchController.clear(); // Xóa chữ trong ô tìm kiếm
    _searchFocusNode.unfocus(); // Ẩn bàn phím / mất focus
    setState(() {
      _searchResults = []; // Ẩn danh sách kết quả
    });
    // Gọi hàm xử lý như khi bấm vào marker (tái sử dụng code)
    _handlePlaceMarkerTap(placeDoc);
  }

  // === HÀM BUILD GIAO DIỆN CHÍNH ===
  @override
  // Hàm `build` được gọi lại mỗi khi `setState` được gọi.
  Widget build(BuildContext context) {
    // Biến tạm để quyết định hiển thị loading chung
    bool showOverallLoading = _isLoadingLocation || _isLoadingPlaces;

    // `Scaffold` là cấu trúc cơ bản của 1 màn hình Material Design.
    return Scaffold(
      // `body` là nội dung chính của màn hình.
      body: Stack(
        // `Stack` cho phép các widget con đè lên nhau.
        children: [
          // --- Lớp 1: Bản đồ hoặc Loading ---
          showOverallLoading
              ? const LoadingIndicator() // <-- WIDGET MỚI (từ map_components.dart)
              : _buildMapLayer(), // Hàm helper build bản đồ
          // --- Lớp 2: Overlay Mờ (Khi có Marker đỏ) ---
          if (_longPressedLatLng !=
              null) // Chỉ hiện khi `_longPressedLatLng` có giá trị
            MapBlurOverlay(
              // <-- WIDGET MỚI (từ map_components.dart)
              onTap: () {
                // Khi bấm vào lớp mờ
                setState(() {
                  _longPressedLatLng = null; // Ẩn marker đỏ
                });
              },
            ),

          // --- LỚP 3: UI TÌM KIẾM VÀ DANH MỤC (Giữ nguyên) ---
          _buildSearchAndFilterUI(), // Hàm helper build UI tìm kiếm
          // --- LỚP 4: DANH SÁCH KẾT QUẢ TÌM KIẾM (Giữ nguyên) ---
          _buildSearchResultsList(), // Hàm helper build danh sách kết quả
        ],
      ),
    );
  }

  // === CÁC HÀM BUILD UI (Giữ lại trong State) ===
  // (Vì các hàm này phụ thuộc nhiều vào State và Controller)

  // Kiểu dữ liệu: Widget
  // Mục đích: Trả về widget FlutterMap đã được cấu hình.
  Widget _buildMapLayer() {
    return FlutterMap(
      mapController: _mapController, // Gắn controller
      options: MapOptions(
        initialCenter: _currentCenter, // Vị trí tâm ban đầu
        initialZoom: 18.0, // Mức zoom ban đầu (rất gần)
        keepAlive: true, // Giữ state của bản đồ khi bị che (ví dụ: chuyển tab)
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all, // Cho phép mọi tương tác (kéo, zoom,...)
        ),
        cameraConstraint: CameraConstraint.contain(
          bounds: _vietnamBounds,
        ), // Giới hạn camera
        // Xử lý sự kiện nhấn giữ
        onLongPress: (tapPosition, latLng) {
          // SỬ DỤNG HELPER MỚI (từ map_helper.dart)
          // Kiểm tra xem vị trí nhấn giữ có gần 1 marker đã có không
          bool nearExisting = isTapNearExistingMarker(latLng, _placeMarkers);
          if (!nearExisting) {
            // Nếu nhấn giữ 1 chỗ mới trong khi đang có marker đỏ ở chỗ khác
            if (_longPressedLatLng != latLng && _longPressedLatLng != null) {
              setState(() {
                _longPressedLatLng = null; // Xóa marker đỏ cũ
              });
            }
            // Cập nhật state: Lưu vị trí nhấn giữ mới
            setState(() {
              _longPressedLatLng = latLng;
            });
            // Di chuyển bản đồ *sau khi* state đã cập nhật
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _centerMapOnLatLng(latLng);
            });
            // Hiển thị bottom sheet cho địa điểm *mới* (existingPlace: null)
            _showLocationDetailsBottomSheet(latLng, existingPlace: null);
          } else {
            // Nếu nhấn giữ quá gần marker cũ, bỏ qua
            print("Nhấn giữ gần marker đã có, bỏ qua.");
          }
        },
      ),
      // `children` của FlutterMap là các lớp (layer) của bản đồ
      children: [
        // Lớp 1: Lớp ảnh bản đồ (tile)
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Nguồn dữ liệu OpenStreetMap
          userAgentPackageName:
              'com.example.nhom_3_damh_lttbdd', // Định danh ứng dụng
          maxZoom: 19.0, // Mức zoom tối đa
        ),
        // Lớp 2: Lớp vẽ đa giác (polygon)
        PolygonLayer(polygons: _countryPolygons),
        // Lớp 3: Lớp vẽ marker
        MarkerLayer(
          markers: [
            // Vẽ tất cả các marker địa điểm (màu trắng/đen)
            ..._placeMarkers,
            // Vẽ marker nhấn giữ (màu đỏ) nếu nó tồn tại
            if (_longPressedLatLng != null)
              Marker(
                point: _longPressedLatLng!, // `!` khẳng định không null
                width: 80,
                height: 80,
                alignment:
                    Alignment.topCenter, // Căn chỉnh (đít nhọn ở đúng tọa độ)
                child: const Icon(
                  Icons.location_pin, // Icon mỏ neo (khác)
                  color: Colors.red,
                  size: 40.0,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Kiểu dữ liệu: Widget
  // Mục đích: Trả về UI của thanh tìm kiếm và thanh danh mục.
  Widget _buildSearchAndFilterUI() {
    // `Positioned` đặt widget ở vị trí cố định bên trong `Stack`.
    return Positioned(
      top:
          MediaQuery.of(context).padding.top +
          10, // Cách lề trên của an toàn (tai thỏ) 10px
      left: 15, // Cách lề trái 15px
      right: 15, // Cách lề phải 15px
      child: Column(
        mainAxisSize: MainAxisSize.min, // Cột co lại vừa đủ nội dung
        children: [
          // Hàng 1: Thanh tìm kiếm
          Container(
            decoration: BoxDecoration(
              color: Colors.white, // Nền trắng
              borderRadius: BorderRadius.circular(30), // Bo tròn
              boxShadow: [
                // Đổ bóng
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Nút Menu (để bật/tắt thanh category)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    // Khi bấm
                    setState(() {
                      // Đảo ngược trạng thái hiển thị
                      _isCategoryBarVisible = !_isCategoryBarVisible;
                    });
                  },
                  color: Colors.grey[700],
                ),
                // Ô nhập liệu
                Expanded(
                  child: TextField(
                    controller: _searchController, // Gắn controller
                    focusNode: _searchFocusNode, // Gắn focus node
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm', // Chữ mờ
                      border: InputBorder.none, // Không có viền
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                // Nút 'x' (clear)
                if (_searchController.text.isNotEmpty) // Chỉ hiện khi có chữ
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear(); // Xóa chữ
                    },
                  ),
              ],
            ),
          ),
          // Hàng 2: Thanh danh mục
          _buildCategoryBar(), // Hàm helper build thanh danh mục
        ],
      ),
    );
  }

  // Kiểu dữ liệu: Widget
  // Mục đích: Trả về UI thanh danh mục (có thể ẩn/hiện)
  Widget _buildCategoryBar() {
    // `AnimatedContainer` tự động thay đổi thuộc tính (ví dụ: height)
    // một cách mượt mà.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // Thời gian animation
      curve: Curves.easeInOut, // Kiểu animation
      height: _isCategoryBarVisible ? 50 : 0, // Thay đổi chiều cao
      margin: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        // `ClipRRect` cắt nội dung bên trong (vì `SingleChildScrollView` có thể tràn)
        borderRadius: BorderRadius.circular(25),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Cuộn ngang
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Nút "Tất cả" (luôn có)
              Padding(
                padding: const EdgeInsets.only(right: 8.0, left: 2.0),
                child: ActionChip(
                  label: const Text('Tất cả'),
                  // Đổi màu nền nếu đang được chọn
                  backgroundColor: _selectedCategory == null
                      ? Colors.orange.shade200
                      : Colors.white,
                  onPressed: () {
                    // Khi bấm "Tất cả"
                    setState(() {
                      _selectedCategory = null; // Bỏ chọn
                      _updatePlaceMarkers(); // Cập nhật lại marker
                    });
                  },
                  shape: StadiumBorder(
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              // Render 10 danh mục đầu tiên
              // `...` (spread operator) trải các widget trong list vào `Row`.
              ..._allCategories.take(10).map((category) {
                // `take(10)` chỉ lấy 10 phần tử đầu
                // `map` biến đổi mỗi `CategoryModel` thành 1 `Widget`.
                final bool isSelected = _selectedCategory?.id == category.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(category.name),
                    backgroundColor: isSelected
                        ? Colors.orange.shade200
                        : Colors.white,
                    onPressed: () {
                      setState(() {
                        _selectedCategory = category; // Gán category được chọn
                        _updatePlaceMarkers(); // Cập nhật marker
                      });
                    },
                    shape: StadiumBorder(
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                );
              }),
              // Nút "+" (Xem thêm)
              if (_allCategories.length > 10) // Chỉ hiện khi có > 10
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: const Icon(Icons.add, size: 18),
                    backgroundColor: Colors.white,
                    onPressed: _showAllCategoriesBottomSheet, // Mở modal
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

  // Kiểu dữ liệu: Widget
  // Mục đích: Trả về UI danh sách kết quả tìm kiếm (dropdown)
  Widget _buildSearchResultsList() {
    // Điều kiện hiển thị: Phải đang focus VÀ phải có kết quả
    if (!_searchFocusNode.hasFocus || _searchResults.isEmpty) {
      return const SizedBox.shrink(); // Trả về widget rỗng (không chiếm diện tích)
    }
    // Tính toán vị trí top (ngay dưới thanh tìm kiếm)
    final double searchBarHeight =
        60 + (MediaQuery.of(context).padding.top + 10);
    return Positioned(
      top: searchBarHeight,
      left: 20,
      right: 20,
      child: Material(
        // `Material` cung cấp hiệu ứng đổ bóng (elevation) và bo tròn
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(
            // Giới hạn chiều cao tối đa
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          // `ListView.builder` hiệu quả khi render danh sách
          child: ListView.builder(
            shrinkWrap: true, // Co lại vừa đủ nội dung
            itemCount: _searchResults.length, // Số lượng item
            itemBuilder: (context, index) {
              // Hàm build cho mỗi item
              final doc = _searchResults[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Không có tên';
              final address =
                  data['location']?['fullAddress'] ?? 'Không có địa chỉ';

              // `ListTile` là 1 widget hàng (row) chuẩn
              return ListTile(
                leading: Icon(Icons.location_pin, color: Colors.grey[600]),
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  // Khi bấm vào 1 kết quả
                  _onSearchResultTap(doc);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // === CÁC HÀM HIỂN THỊ MODAL (Đã dọn dẹp) ===

  // Kiểu dữ liệu: void
  // Mục đích: Hiển thị BottomSheet chứa *tất cả* danh mục
  void _showAllCategoriesBottomSheet() {
    showModalBottomSheet(
      context: context, // Ngữ cảnh build
      isScrollControlled: true, // Cho phép modal cao (chiếm > 50% màn hình)
      builder: (context) {
        // `DraggableScrollableSheet` tạo 1 sheet có thể kéo
        return DraggableScrollableSheet(
          expand: false, // Không full màn hình
          initialChildSize: 0.5, // Chiều cao ban đầu (50%)
          maxChildSize: 0.8, // Chiều cao tối đa (80%)
          builder: (context, scrollController) {
            // (Bạn có thể tách phần này ra widget/all_categories_modal.dart nếu muốn)
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Tất cả danh mục',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(), // Đường kẻ ngang
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController, // Gắn controller (để kéo)
                      itemCount: _allCategories.length,
                      itemBuilder: (context, index) {
                        final category = _allCategories[index];
                        final bool isSelected =
                            _selectedCategory?.id == category.id;
                        return ListTile(
                          title: Text(category.name),
                          trailing:
                              isSelected // Hiển thị dấu check
                              ? Icon(Icons.check, color: Colors.orange)
                              : null,
                          onTap: () {
                            // Khi chọn
                            setState(() {
                              _selectedCategory = category;
                              _updatePlaceMarkers();
                            });
                            Navigator.pop(context); // Đóng modal
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

  // === HÀM BOTTOM SHEET CHÍNH (ĐÃ DỌN DẸP) ===

  // Kiểu dữ liệu: void
  // Mục đích: Hiển thị modal chi tiết (cho cả địa điểm mới và cũ)
  void _showLocationDetailsBottomSheet(
    LatLng position, { // Tọa độ (luôn có)
    DocumentSnapshot? existingPlace, // Dữ liệu (chỉ có khi bấm marker cũ)
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép nội dung quyết định chiều cao
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // --- GỌI WIDGET MỚI ---
        // Trả về widget `LocationDetailsModal` đã được refactor
        return LocationDetailsModal(
          // Dữ liệu truyền vào
          position: position,
          existingPlace: existingPlace,
          userId: widget.userId,
          getStreetAndCity: _service.getStreetAndCity, // Truyền *hàm* service
          // --- Định nghĩa Callbacks (hàm xử lý) ---

          // `onSaveLocation` là 1 hàm được truyền vào `LocationDetailsModal`
          // Khi nút "Lưu" (trong modal) được bấm, hàm này sẽ được gọi.
          onSaveLocation: () {
            Navigator.pop(context); // Đóng modal
            _savePrivateLocation(
              position,
            ); // Gọi logic lưu (của WorldMapScreen)
            setState(() {
              _longPressedLatLng = null; // Xóa marker đỏ
            });
          },
          // Khi nút "Thêm" (trong modal) được bấm
          onAddPlace: () {
            Navigator.pop(context); // Đóng modal
            // Điều hướng (push) sang màn hình AddPlaceScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPlaceScreen(
                  initialLatLng: position, // Truyền tọa độ sang
                  userId: widget.userId, // Truyền userId sang
                ),
              ),
            );
          },
          // Khi nút "Review" (trong modal) được bấm
          // (String placeId) là tham số được `LocationDetailsModal` trả về
          onWriteReview: (String placeId) {
            Navigator.pop(context); // Đóng modal
            // Điều hướng sang màn hình CheckinScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckinScreen(
                  currentUserId: widget.userId,
                  initialPlaceId: placeId, // Truyền placeId sang
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // `.whenComplete` được gọi *sau khi* modal đã đóng (bằng mọi cách).
      // Callback khi đóng sheet
      if (_longPressedLatLng != null && mounted) {
        // Nếu marker đỏ vẫn còn (tức là modal bị đóng mà không lưu/thêm)
        setState(() {
          _longPressedLatLng = null; // Xóa marker đỏ
        });
      }
    });
  }

  // === CÁC HÀM HELPER CÒN LẠI ===

  // Kiểu dữ liệu: void
  // Mục đích: Hiển thị 1 SnackBar (thông báo ngắn ở đáy màn hình)
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      // Kiểm tra widget còn tồn tại
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.redAccent
              : null, // Màu đỏ nếu là lỗi
        ),
      );
    }
  }

  // (Các hàm _buildImage, _buildPhotoGrid, ... đã được chuyển đi)
}
// Dòng này Flutter tự thêm, không cần comment
// }