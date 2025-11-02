// File: screens/checkin/widget/mini_map_picker.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';

// Import service để tải places
import '../service/checkin_service.dart';

// Đổi tên thành public
class MiniMapPicker extends StatefulWidget {
  final Function(DocumentSnapshot) onPlaceSelected;
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
  final MapController _mapController = MapController();
  final CheckinService _service = CheckinService(); // Khởi tạo service
  List<DocumentSnapshot> _places = [];
  List<Marker> _markers = [];
  bool _isLoading = true;
  String _searchText = '';
  List<DocumentSnapshot> _filteredPlaces = [];
  final TextEditingController _searchController = TextEditingController();

  // Màu sắc (lấy từ file gốc)
  static const Color kBorderColor = Color(0xFFE4C99E);

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Tải danh sách places (đã gọi service)
  Future<void> _fetchPlaces() async {
    setState(() => _isLoading = true);
    try {
      _places = await _service.fetchAllPlaces(); // Gọi service
      _updateMarkers();
      _filterPlaces();
    } catch (e) {
      print("Lỗi tải places cho map picker: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách địa điểm: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Tạo/Cập nhật Markers (giữ nguyên)
  void _updateMarkers() {
    _markers = _places
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final coordinates = data['location']?['coordinates'] as GeoPoint?;
          if (coordinates != null) {
            return Marker(
              point: LatLng(coordinates.latitude, coordinates.longitude),
              width: 35,
              height: 35,
              child: GestureDetector(
                onTap: () => widget.onPlaceSelected(doc),
                child: Tooltip(
                  message: data['name'] ?? 'Địa điểm',
                  child: Container(
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
          return null;
        })
        .whereType<Marker>()
        .toList();
  }

  // Lọc danh sách (giữ nguyên)
  void _filterPlaces() {
    if (_searchText.isEmpty) {
      _filteredPlaces = _places;
    } else {
      _filteredPlaces = _places.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] as String? ?? '';
        final location = data['location'] as Map<String, dynamic>? ?? {};
        final address = location['fullAddress'] as String? ?? '';
        final city = location['city'] as String? ?? '';
        final searchLower = _searchText.toLowerCase();
        return name.toLowerCase().contains(searchLower) ||
            address.toLowerCase().contains(searchLower) ||
            city.toLowerCase().contains(searchLower);
      }).toList();
    }
    if (mounted) setState(() {});
  }

  // Di chuyển bản đồ (giữ nguyên)
  void _moveToPlace(DocumentSnapshot placeDoc) {
    final data = placeDoc.data() as Map<String, dynamic>;
    final coordinates = data['location']?['coordinates'] as GeoPoint?;
    if (coordinates != null) {
      _mapController.move(
        LatLng(coordinates.latitude, coordinates.longitude),
        15.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Thanh kéo và Title
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
            height: MediaQuery.of(context).size.height * 0.35,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(16.0, 108.0),
                      initialZoom: 5.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.nhom_3_damh_lttbdd',
                        maxZoom: 19,
                      ),
                      MarkerLayer(markers: _markers),
                    ],
                  ),
          ),

          // Thanh Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchText = value;
                _filterPlaces();
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên hoặc địa chỉ...',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Colors.grey,
                ),
                isDense: true,
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
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchText = '';
                          _filterPlaces();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Danh sách kết quả
          Expanded(
            child: _isLoading
                ? const SizedBox.shrink()
                : _filteredPlaces.isEmpty
                ? Center(
                    child: Text(
                      _searchText.isEmpty
                          ? 'Kéo bản đồ hoặc tìm kiếm...'
                          : 'Không tìm thấy địa điểm phù hợp.',
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: _filteredPlaces.length,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => widget.onPlaceSelected(placeDoc),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.my_location,
                            size: 20,
                            color: Colors.grey,
                          ),
                          tooltip: 'Xem trên bản đồ',
                          onPressed: () => _moveToPlace(placeDoc),
                        ),
                        dense: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
