// File: addPlaceRequest.dart (Đã refactor theo yêu cầu)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
// Import file constants để lấy danh sách tỉnh thành chuẩn
// !!! QUAN TRỌNG: Đảm bảo đường dẫn này đúng !!!
import 'journey_map_constants.dart'; // <<< Sửa đường dẫn nếu cần

class AddPlaceScreen extends StatefulWidget {
  final LatLng initialLatLng;
  final String userId;

  const AddPlaceScreen({
    Key? key,
    required this.initialLatLng,
    required this.userId,
  }) : super(key: key);

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingAddress = true; // Loading khi lấy địa chỉ
  bool _isSubmitting = false; // Loading khi gửi form

  // Controllers cho form (Đã bỏ ward và district)
  final _nameController = TextEditingController();
  final _streetController = TextEditingController(); // Giữ lại (để hiển thị)
  final _wardController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCity; // Thành phố/Tỉnh chọn từ dropdown (sẽ bị khóa)

  // TODO: Thêm biến state để lưu ảnh đã chọn (XFile?)

  // --- Danh sách Tỉnh/Thành phố đã bị xóa -> Dùng kProvinceDisplayNames từ constants ---

  @override
  void initState() {
    super.initState();
    _fetchAddressDetails(); // Lấy địa chỉ tự động
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    // Đã xóa dispose cho ward và district
    _notesController.dispose();
    super.dispose();
  }

  // === HÀM LẤY ĐỊA CHỈ TỪ TỌA ĐỘ (Đã cập nhật) ===
  Future<void> _fetchAddressDetails() async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.initialLatLng.latitude,
        widget.initialLatLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        _streetController.text = place.thoroughfare ?? ''; // Đường

        // Lấy Quận/Huyện gán vào Phường/Xã
        _wardController.text = place.subAdministrativeArea ?? '';

        // Logic khớp tên Tỉnh/Thành phố (Dùng kProvinceDisplayNames)
        String fetchedCity = place.administrativeArea ?? '';
        fetchedCity = fetchedCity
            .replaceFirst('Thành phố ', '')
            .replaceFirst('Tỉnh ', '');

        String? matchedDisplayName;
        // Lặp qua TÊN HIỂN THỊ trong map constants
        for (var displayName in kProvinceDisplayNames.values) {
          // Chuẩn hóa tên hiển thị để so sánh (bỏ TP., TĐ.)
          String normalizedDisplayName = displayName
              .replaceFirst('TP. ', '')
              .replaceFirst('TĐ. ', '');
          if (normalizedDisplayName.toLowerCase() ==
              fetchedCity.toLowerCase()) {
            matchedDisplayName = displayName; // Lưu lại tên đầy đủ từ map
            break;
          }
        }
        _selectedCity = matchedDisplayName; // Gán tên tìm được
      }
    } catch (e) {
      print("Lỗi geocoding: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tự động lấy địa chỉ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  // === HÀM GỬI FORM LÊN FIREBASE (Đã cập nhật) ===
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() => _isSubmitting = true);

      // TODO: Xử lý upload ảnh

      // Chỉ còn Đường + Tỉnh/TP
      final String fullAddress =
          '${_streetController.text}, ${_wardController.text}, $_selectedCity';

      final Map<String, dynamic> submissionData = {
        'submittedBy': widget.userId,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'placeData': {
          'name': _nameController.text,
          'description': _notesController.text,
          'location': {
            'coordinates': GeoPoint(
              widget.initialLatLng.latitude,
              widget.initialLatLng.longitude,
            ),
            'fullAddress': fullAddress,
            'street': _streetController.text,
            'ward': _wardController.text,
            // Đã xóa 'ward' và 'district'
            'city': _selectedCity, // Dùng tên hiển thị đầy đủ
          },
          'categories': [],
          'images': [], // TODO: Thêm URL ảnh
          'ratingAverage': 0,
          'reviewCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': widget.userId,
        },
        'initialReviewData': {},
      };

      try {
        await FirebaseFirestore.instance
            .collection('placeSubmissions')
            .add(submissionData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã gửi yêu cầu chờ duyệt!')),
          );
          Navigator.of(context).pop(); // Quay lại màn hình bản đồ
        }
      } catch (e) {
        print("Lỗi khi gửi submission: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gửi yêu cầu thất bại: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  // === GIAO DIỆN (Đã cập nhật) ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký địa điểm mới')),
      body: _isLoadingAddress
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Thông tin địa điểm',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Tên địa điểm (Giữ nguyên)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên địa điểm *',
                        border: OutlineInputBorder(),
                        hintText: 'Nhập tên địa điểm',
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Vui lòng nhập tên địa điểm'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // --- Tỉnh/ Thành phố (KHÓA, Dùng Constants) ---
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(
                        labelText: 'Tỉnh/ Thành phố *',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100], // Màu nền khóa
                      ),
                      // Lấy items từ map constants
                      items:
                          kProvinceDisplayNames.values
                              .map(
                                (String displayName) =>
                                    DropdownMenuItem<String>(
                                      value: displayName,
                                      child: Text(displayName),
                                    ),
                              )
                              .toList()
                            ..sort(
                              (a, b) => a.value!.compareTo(b.value!),
                            ), // Sắp xếp
                      onChanged: null, // <-- KHÓA
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn Tỉnh/Thành phố' : null,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          _wardController, // Use the re-added controller
                      readOnly: true, // Keep it locked
                      decoration: InputDecoration(
                        labelText:
                            'Phường/Xã', // Label indicates it might be district
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100], // Locked style
                      ),
                      // No validator needed if readOnly, but keep it if you might unlock later
                      // validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập phường/xã' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- Đường (KHÓA) ---
                    TextFormField(
                      controller: _streetController,
                      readOnly: true, // <-- KHÓA
                      decoration: InputDecoration(
                        labelText: 'Đường *',
                        border: const OutlineInputBorder(),
                        hintText: 'Tự động điền từ bản đồ',
                        filled: true,
                        fillColor: Colors.grey[100], // Màu nền khóa
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Vui lòng nhập tên đường'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Ghi chú (Giữ nguyên)
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (Mô tả ban đầu)',
                        border: OutlineInputBorder(),
                        hintText: 'Thêm ghi chú cá nhân hoặc mô tả...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Hình ảnh (Giữ nguyên)
                    Text(
                      'Hình ảnh',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        print('Chọn ảnh...');
                      },
                      child: Container(/* ... code hiển thị chọn ảnh ... */),
                    ),
                    const SizedBox(height: 24),

                    // Nút Gửi (Giữ nguyên)
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('GỬI YÊU CẦU'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} // End of _AddPlaceScreenState
