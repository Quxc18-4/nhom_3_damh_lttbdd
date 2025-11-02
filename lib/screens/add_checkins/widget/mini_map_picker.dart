// File: screens/checkin/widget/mini_map_picker.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart'; // Import thư viện bản đồ (không phải Google Maps)
import 'package:latlong2/latlong.dart'; // Import thư viện hỗ trợ kiểu LatLng cho flutter_map
import 'package:geocoding/geocoding.dart'; // Bạn có import nhưng chưa dùng trong file này
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // Bạn có import nhưng chưa dùng trong file này

// Import service để tải places
import '../service/checkin_service.dart'; // Cần service để gọi hàm `fetchAllPlaces`

// Đổi tên thành public
// Đây là `StatefulWidget` vì nó cần quản lý nhiều trạng thái nội bộ:
// - `_isLoading` (đang tải địa điểm)
// - `_places` (danh sách địa điểm gốc)
// - `_filteredPlaces` (danh sách địa điểm sau khi tìm kiếm)
// - `_searchText` (nội dung ô tìm kiếm)
class MiniMapPicker extends StatefulWidget {
  // `Function(DocumentSnapshot)`:
  // Đây là kiểu dữ liệu "hàm" (function type). Nó định nghĩa một hàm
  // nhận vào 1 tham số kiểu `DocumentSnapshot` và không trả về gì (void).
  // Đây là cơ chế `callback` để "bắn" dữ liệu (địa điểm đã chọn)
  // ra cho widget cha (CheckinScreen).
  final Function(DocumentSnapshot) onPlaceSelected;

  // `ScrollController`:
  // Cần nhận `ScrollController` từ `DraggableScrollableSheet`
  // để khi người dùng cuộn (scroll) `ListView` kết quả tìm kiếm,
  // nó cũng đồng thời tương tác (cuộn/mở rộng) cái `DraggableScrollableSheet`.
  final ScrollController scrollController;

  const MiniMapPicker({
    Key? key,
    required this.onPlaceSelected,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<MiniMapPicker> createState() => _MiniMapPickerState();
}

class _MiniMapPickerState extends State<MiniMapPicker> {
  // `MapController`: Dùng để điều khiển bản đồ (ví dụ: di chuyển, phóng to).
  final MapController _mapController = MapController();
  // Service: Để tải dữ liệu.
  final CheckinService _service = CheckinService();

  // `List<DocumentSnapshot>`:
  // `_places`: Lưu danh sách *gốc* (master list) tất cả địa điểm.
  List<DocumentSnapshot> _places = [];

  // `List<Marker>`:
  // `_markers`: Lưu danh sách các widget `Marker` (chấm tròn trên bản đồ)
  // được tạo ra từ `_places`.
  List<Marker> _markers = [];

  // `bool`: Trạng thái loading.
  bool _isLoading = true;

  // `String`: Trạng thái của ô tìm kiếm.
  String _searchText = '';

  // `List<DocumentSnapshot>`:
  // `_filteredPlaces`: Lưu danh sách địa điểm *sau khi lọc* (filter)
  // bằng `_searchText`. `ListView` sẽ hiển thị danh sách này.
  List<DocumentSnapshot> _filteredPlaces = [];

  // Controller cho ô `TextField` tìm kiếm.
  final TextEditingController _searchController = TextEditingController();

  // Màu sắc (lấy từ file gốc)
  static const Color kBorderColor = Color(0xFFE4C99E);

  @override
  void initState() {
    super.initState();
    // Khi widget được tạo, gọi hàm tải địa điểm ngay lập tức.
    _fetchPlaces();
  }

  @override
  void dispose() {
    // Dọn dẹp controller khi widget bị hủy.
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Tải danh sách places (đã gọi service)
  Future<void> _fetchPlaces() async {
    // 1. Set loading = true và build lại UI (hiện vòng quay)
    setState(() => _isLoading = true);
    try {
      // 2. Gọi service
      _places = await _service.fetchAllPlaces(); // Lấy danh sách gốc

      // 3. Xử lý dữ liệu vừa tải về
      _updateMarkers(); // Tạo các Marker cho bản đồ
      _filterPlaces(); // Cập nhật danh sách hiển thị (ban đầu là full list)
    } catch (e) {
      print("Lỗi tải places cho map picker: $e");
      if (mounted) {
        // Hiển thị lỗi (nếu có)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách địa điểm: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      // 4. Luôn set loading = false (dù thành công hay thất bại)
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Tạo/Cập nhật Markers (giữ nguyên)
  void _updateMarkers() {
    // **Luồng hoạt động:**
    _markers = _places
        .map((doc) {
          // 1. Lặp qua từng `DocumentSnapshot` trong `_places`
          final data = doc.data() as Map<String, dynamic>;

          // 2. Lấy dữ liệu tọa độ
          // `GeoPoint`: Kiểu dữ liệu đặc biệt của Firestore để lưu Vĩ độ (Lat) và Kinh độ (Lon).
          final coordinates = data['location']?['coordinates'] as GeoPoint?;

          if (coordinates != null) {
            // 3. Nếu tọa độ tồn tại, tạo một `Marker`
            return Marker(
              // `LatLng`: Kiểu dữ liệu của `latlong2`, chuyển đổi từ `GeoPoint`
              point: LatLng(coordinates.latitude, coordinates.longitude),
              width: 35,
              height: 35,
              child: GestureDetector(
                // **Callback Flow (1):**
                // Khi người dùng bấm vào Marker trên bản đồ...
                onTap: () => widget.onPlaceSelected(
                  doc,
                ), // ...gọi callback `onPlaceSelected`
                child: Tooltip(
                  // Hiển thị tên khi giữ chuột (trên web)
                  message: data['name'] ?? 'Địa điểm',
                  child: Container(
                    // (Đây là code UI để vẽ cái chấm màu xanh)
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.white,
                      size: 20.0,
                    ),
                  ),
                ),
              ),
            );
          }
          return null; // Nếu địa điểm không có tọa độ, trả về null
        })
        .whereType<Marker>() // 4. Lọc bỏ tất cả các giá trị `null`
        .toList(); // 5. Chuyển kết quả thành một `List<Marker>`
  }

  // Lọc danh sách (giữ nguyên)
  void _filterPlaces() {
    // 1. Nếu ô tìm kiếm rỗng
    if (_searchText.isEmpty) {
      // Danh sách lọc = danh sách gốc
      _filteredPlaces = _places;
    } else {
      // 2. Nếu có gõ tìm kiếm
      _filteredPlaces = _places.where((doc) {
        // Dùng hàm `.where` để lọc
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] as String? ?? '';
        final location = data['location'] as Map<String, dynamic>? ?? {};
        final address = location['fullAddress'] as String? ?? '';
        final city = location['city'] as String? ?? '';

        // `toLowerCase()`: Đưa cả nội dung tìm kiếm và dữ liệu về
        // chữ thường để tìm kiếm không phân biệt hoa/thường.
        final searchLower = _searchText.toLowerCase();

        // Trả về `true` nếu bất kỳ trường nào chứa nội dung tìm kiếm
        return name.toLowerCase().contains(searchLower) ||
            address.toLowerCase().contains(searchLower) ||
            city.toLowerCase().contains(searchLower);
      }).toList(); // 3. Chuyển kết quả lọc thành List
    }

    // 4. Gọi `setState` để cập nhật `ListView`
    // (Kiểm tra `mounted` cho chắc chắn, mặc dù ở đây không `await`)
    if (mounted) setState(() {});
  }

  // Di chuyển bản đồ (giữ nguyên)
  void _moveToPlace(DocumentSnapshot placeDoc) {
    final data = placeDoc.data() as Map<String, dynamic>;
    final coordinates = data['location']?['coordinates'] as GeoPoint?;
    if (coordinates != null) {
      // Sử dụng `MapController` để di chuyển tâm bản đồ đến tọa độ
      // của địa điểm, với mức zoom là 15.0.
      _mapController.move(
        LatLng(coordinates.latitude, coordinates.longitude),
        15.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // `Container` với `borderRadius` để tạo hiệu ứng bo góc
    // cho sheet (vì `showModalBottomSheet` đã set `backgroundColor: Colors.transparent`).
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Thanh kéo (Drag Handle)
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 0),
            child: Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              'Chọn địa điểm từ bản đồ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Bản đồ Mini
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                0.35, // Chiều cao cố định (35% màn hình)
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Hiển thị loading
                : FlutterMap(
                    // Widget bản đồ chính
                    mapController: _mapController, // Gắn controller
                    options: MapOptions(
                      initialCenter: const LatLng(16.0, 108.0), // Tâm Việt Nam
                      initialZoom: 5.5,
                      interactionOptions: const InteractionOptions(
                        // Chỉ cho phép zoom (pinch) và kéo (drag)
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      // Lớp 1: Nền bản đồ
                      TileLayer(
                        // Sử dụng OpenStreetMap (miễn phí)
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.nhom_3_damh_lttbdd',
                        maxZoom: 19,
                      ),
                      // Lớp 2: Các Marker (chồng lên trên nền)
                      MarkerLayer(markers: _markers),
                    ],
                  ),
          ),

          // Thanh Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
            child: TextField(
              controller: _searchController,
              // `onChanged`: Được gọi *mỗi khi* người dùng gõ 1 ký tự.
              onChanged: (value) {
                // 1. Cập nhật biến state `_searchText`
                _searchText = value;
                // 2. Gọi hàm lọc lại danh sách
                _filterPlaces();
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên hoặc địa chỉ...',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Colors.grey,
                ),
                isDense: true, // Làm cho `TextField` nhỏ gọn hơn
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: kBorderColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                // Hiển thị nút "X" (clear)
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          // Khi bấm "X":
                          _searchController
                              .clear(); // Xóa text trong controller
                          _searchText = ''; // Xóa text trong state
                          _filterPlaces(); // Lọc lại (sẽ hiển thị full list)
                        },
                      )
                    : null, // Không hiển thị gì nếu ô search rỗng
              ),
            ),
          ),

          // Danh sách kết quả
          Expanded(
            // `Expanded`: Chiếm hết phần không gian còn lại
            // bên trong `Column`.
            child: _isLoading
                ? const SizedBox.shrink() // Nếu đang loading (lúc đầu), không hiển thị gì
                : _filteredPlaces
                      .isEmpty // Nếu loading xong và list rỗng
                ? Center(
                    child: Text(
                      _searchText.isEmpty
                          ? 'Kéo bản đồ hoặc tìm kiếm...' // Rỗng do chưa tìm
                          : 'Không tìm thấy địa điểm phù hợp.', // Rỗng do tìm không có
                    ),
                  )
                : ListView.builder(
                    // Nếu có kết quả
                    // **Quan trọng:** Gắn `scrollController`
                    // (nhận từ `DraggableScrollableSheet`) vào `ListView`.
                    controller: widget.scrollController,
                    itemCount: _filteredPlaces.length, // Số lượng item
                    // `itemBuilder`: Hàm để vẽ từng item
                    itemBuilder: (context, index) {
                      final placeDoc = _filteredPlaces[index];
                      final data = placeDoc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Không tên';
                      final location =
                          data['location'] as Map<String, dynamic>? ?? {};
                      final address =
                          location['fullAddress'] ?? 'Không địa chỉ';

                      return ListTile(
                        leading: const Icon(
                          Icons.location_pin,
                          color: Colors.blueAccent,
                          size: 28,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          address,
                          maxLines: 1, // Chỉ hiển thị 1 dòng
                          overflow: TextOverflow
                              .ellipsis, // Hiển thị "..." nếu quá dài
                          style: const TextStyle(fontSize: 12),
                        ),

                        // **Callback Flow (2):**
                        // Khi người dùng bấm vào một `ListTile`...
                        onTap: () => widget.onPlaceSelected(
                          placeDoc,
                        ), // ...gọi callback `onPlaceSelected`

                        trailing: IconButton(
                          // Nút bên phải
                          icon: const Icon(
                            Icons.my_location,
                            size: 20,
                            color: Colors.grey,
                          ),
                          tooltip: 'Xem trên bản đồ',
                          // Khi bấm nút này, gọi hàm di chuyển bản đồ
                          onPressed: () => _moveToPlace(placeDoc),
                        ),
                        dense: true, // Làm cho `ListTile` nhỏ gọn hơn
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
