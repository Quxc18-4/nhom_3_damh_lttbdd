// File: screens/world_map/worldMapScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:math';

// Imports các màn hình điều hướng
import 'package:nhom_3_damh_lttbdd/screens/add_places/addPlaceRequest.dart';
import 'package:nhom_3_damh_lttbdd/screens/add_checkins/checkinScreen.dart';

// Imports các file đã refactor
import 'package:nhom_3_damh_lttbdd/model/category_model.dart';
// import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';
import 'service/world_map_service.dart';
import 'helper/map_helper.dart';
import 'widget/location_details_modal.dart';
import 'widget/map_components.dart';
// (Không cần import photo_grid.dart vì nó được gọi bởi location_details_modal.dart)

class WorldMapScreen extends StatefulWidget {
  final String userId;
  const WorldMapScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  // === Service ===
  final WorldMapService _service = WorldMapService();

  // === State: Map & Vị trí ===
  final MapController _mapController = MapController();
  bool _isLoadingLocation = true;
  LatLng _currentCenter = const LatLng(21.0285, 105.8542); // Mặc định Hà Nội
  LatLng? _longPressedLatLng;

  // === State: Tìm kiếm & Danh mục ===
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<CategoryModel> _allCategories = [];
  bool _isLoadingCategories = true;
  bool _isCategoryBarVisible = false;
  CategoryModel? _selectedCategory;
  List<DocumentSnapshot> _searchResults = [];

  // === State: Places & Markers ===
  List<DocumentSnapshot> _fetchedPlaces = [];
  List<Marker> _placeMarkers = [];
  bool _isLoadingPlaces = true;

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
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {
        // Cập nhật UI khi focus thay đổi (để ẩn/hiện list)
      });
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // === LOGIC TẢI DỮ LIỆU (ĐÃ GỌI SERVICE) ===
  Future<void> _initializeMapData() async {
    // Chạy song song
    await Future.wait([
      _determinePosition(),
      _fetchPlacesFromFirestore(),
      _fetchCategories(),
    ]);
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await _service.fetchCategories();
      if (mounted) {
        setState(() {
          _allCategories = categories;
        });
      }
    } catch (e) {
      _showSnackBar('Không thể tải danh sách danh mục: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  Future<void> _determinePosition() async {
    try {
      final position = await _service.determinePosition();
      if (mounted) {
        setState(() {
          _currentCenter = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Không thể lấy vị trí: $e. Dùng vị trí mặc định.',
          isError: true,
        );
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _fetchPlacesFromFirestore() async {
    if (!mounted) return;
    setState(() => _isLoadingPlaces = true);
    try {
      _fetchedPlaces = await _service.fetchPlaces();
      if (mounted) {
        setState(() {
          _isLoadingPlaces = false;
          _updatePlaceMarkers(); // Tạo marker
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi tải danh sách địa điểm: $e', isError: true);
        setState(() => _isLoadingPlaces = false);
      }
    }
  }

  // === LOGIC TẠO MARKER (Giữ nguyên) ===
  void _updatePlaceMarkers() {
    List<Marker> markers = [];
    final List<DocumentSnapshot> placesToBuild = _selectedCategory == null
        ? _fetchedPlaces
        : _fetchedPlaces.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final categoryIds = data['categories'] as List<dynamic>? ?? [];
            return categoryIds.contains(_selectedCategory!.id);
          }).toList();

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

  // === LOGIC XỬ LÝ SỰ KIỆN (Giữ nguyên) ===

  void _centerMapOnLatLng(LatLng targetCenter) {
    _mapController.move(targetCenter, _mapController.camera.zoom);
  }

  void _savePrivateLocation(LatLng position) {
    print('UserID ${widget.userId} đang lưu vị trí cá nhân: $position');
    // TODO: Triển khai logic lưu lên Firestore
    _showSnackBar('Đã lưu vị trí cá nhân!');
  }

  void _handlePlaceMarkerTap(DocumentSnapshot placeDoc) {
    final data = placeDoc.data() as Map<String, dynamic>;
    final coordinates = data['location']?['coordinates'] as GeoPoint?;
    if (coordinates != null) {
      final latLng = LatLng(coordinates.latitude, coordinates.longitude);
      if (_longPressedLatLng != null) {
        setState(() {
          _longPressedLatLng = null;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapOnLatLng(latLng);
      });
      _showLocationDetailsBottomSheet(latLng, existingPlace: placeDoc);
    }
  }

  // === LOGIC TÌM KIẾM (Giữ nguyên) ===
  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
      });
    } else {
      _performSearch(_searchController.text);
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final String lowerCaseQuery = query.toLowerCase();
    final results = _fetchedPlaces.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name'] as String? ?? '';
      return name.toLowerCase().contains(lowerCaseQuery);
    }).toList();
    setState(() {
      _searchResults = results.take(5).toList();
    });
  }

  void _onSearchResultTap(DocumentSnapshot placeDoc) {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchResults = [];
    });
    _handlePlaceMarkerTap(placeDoc);
  }

  // === HÀM BUILD GIAO DIỆN CHÍNH ===
  @override
  Widget build(BuildContext context) {
    bool showOverallLoading = _isLoadingLocation || _isLoadingPlaces;

    return Scaffold(
      body: Stack(
        children: [
          // --- Lớp 1: Bản đồ hoặc Loading ---
          showOverallLoading
              ? const LoadingIndicator() // <-- WIDGET MỚI
              : _buildMapLayer(),
          // --- Lớp 2: Overlay Mờ (Khi có Marker đỏ) ---
          if (_longPressedLatLng != null)
            MapBlurOverlay(
              // <-- WIDGET MỚI
              onTap: () {
                setState(() {
                  _longPressedLatLng = null;
                });
              },
            ),

          // --- LỚP 3: UI TÌM KIẾM VÀ DANH MỤC (Giữ nguyên) ---
          _buildSearchAndFilterUI(),

          // --- LỚP 4: DANH SÁCH KẾT QUẢ TÌM KIẾM (Giữ nguyên) ---
          _buildSearchResultsList(),
        ],
      ),
    );
  }

  // === CÁC HÀM BUILD UI (Giữ lại trong State) ===
  // (Vì các hàm này phụ thuộc nhiều vào State và Controller)

  Widget _buildMapLayer() {
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
        onLongPress: (tapPosition, latLng) {
          // SỬ DỤNG HELPER MỚI
          bool nearExisting = isTapNearExistingMarker(latLng, _placeMarkers);
          if (!nearExisting) {
            if (_longPressedLatLng != latLng && _longPressedLatLng != null) {
              setState(() {
                _longPressedLatLng = null;
              });
            }
            setState(() {
              _longPressedLatLng = latLng;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _centerMapOnLatLng(latLng);
            });
            _showLocationDetailsBottomSheet(latLng, existingPlace: null);
          } else {
            print("Nhấn giữ gần marker đã có, bỏ qua.");
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.nhom_3_damh_lttbdd',
          maxZoom: 19.0,
        ),
        PolygonLayer(polygons: _countryPolygons),
        MarkerLayer(
          markers: [
            ..._placeMarkers,
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

  Widget _buildSearchAndFilterUI() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 15,
      right: 15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hàng 1: Thanh tìm kiếm
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
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    setState(() {
                      _isCategoryBarVisible = !_isCategoryBarVisible;
                    });
                  },
                  color: Colors.grey[700],
                ),
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
          // Hàng 2: Thanh danh mục
          _buildCategoryBar(),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isCategoryBarVisible ? 50 : 0,
      margin: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Nút "Tất cả"
              Padding(
                padding: const EdgeInsets.only(right: 8.0, left: 2.0),
                child: ActionChip(
                  label: const Text('Tất cả'),
                  backgroundColor: _selectedCategory == null
                      ? Colors.orange.shade200
                      : Colors.white,
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _updatePlaceMarkers();
                    });
                  },
                  shape: StadiumBorder(
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              // Render 10 danh mục
              ..._allCategories.take(10).map((category) {
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
                        _selectedCategory = category;
                        _updatePlaceMarkers();
                      });
                    },
                    shape: StadiumBorder(
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                );
              }),
              // Nút "+"
              if (_allCategories.length > 10)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: const Icon(Icons.add, size: 18),
                    backgroundColor: Colors.white,
                    onPressed: _showAllCategoriesBottomSheet,
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

  Widget _buildSearchResultsList() {
    if (!_searchFocusNode.hasFocus || _searchResults.isEmpty) {
      return const SizedBox.shrink();
    }
    final double searchBarHeight =
        60 + (MediaQuery.of(context).padding.top + 10);
    return Positioned(
      top: searchBarHeight,
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
                leading: Icon(Icons.location_pin, color: Colors.grey[600]),
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

  // === CÁC HÀM HIỂN THỊ MODAL (ĐÃ DỌN DẸP) ===

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
            // (Bạn có thể tách phần này ra widget/all_categories_modal.dart nếu muốn)
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
                              _updatePlaceMarkers();
                            });
                            Navigator.pop(context);
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
  void _showLocationDetailsBottomSheet(
    LatLng position, {
    DocumentSnapshot? existingPlace,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // --- GỌI WIDGET MỚI ---
        return LocationDetailsModal(
          position: position,
          existingPlace: existingPlace,
          userId: widget.userId,
          getStreetAndCity: _service.getStreetAndCity, // Truyền hàm service
          // --- Định nghĩa Callbacks ---
          onSaveLocation: () {
            Navigator.pop(context);
            _savePrivateLocation(position);
            setState(() {
              _longPressedLatLng = null;
            });
          },
          onAddPlace: () {
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
          onWriteReview: (String placeId) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckinScreen(
                  currentUserId: widget.userId,
                  initialPlaceId: placeId,
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Callback khi đóng sheet
      if (_longPressedLatLng != null && mounted) {
        setState(() {
          _longPressedLatLng = null;
        });
      }
    });
  }

  // === CÁC HÀM HELPER CÒN LẠI ===
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

  // (Các hàm _buildImage, _buildPhotoGrid, ... đã được chuyển đi)
}
