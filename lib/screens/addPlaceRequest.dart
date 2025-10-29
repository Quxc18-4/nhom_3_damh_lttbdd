import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io'; // Cần cho File
import 'package:image_picker/image_picker.dart'; // Cần cho chọn ảnh

// Import file constants
// !!! QUAN TRỌNG: Đảm bảo đường dẫn này đúng !!!
import 'journey_map_constants.dart'; // <<< Sửa đường dẫn nếu cần

// ⚡️ IMPORT CLOUDINARY SERVICE
// !!! QUAN TRỌNG: Đảm bảo đường dẫn này đúng tới file service của bạn !!!
import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart'; // <<< Sửa đường dẫn nếu cần

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
  bool _isLoadingAddress = true;
  bool _isSubmitting = false;

  // Controllers
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _wardController = TextEditingController(); // Giữ lại theo yêu cầu trước
  final _notesController = TextEditingController();
  String? _selectedCity;

  // === State mới cho Ảnh ===
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = []; // Lưu đối tượng XFile để dễ upload
  final CloudinaryService _cloudinaryService =
      CloudinaryService(); // Khởi tạo service
  final int _maxImages = 5; // Giới hạn số lượng ảnh
  // ==========================

  @override
  void initState() {
    super.initState();
    _fetchAddressDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Hàm tiện ích
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

  // === HÀM LẤY ĐỊA CHỈ (Đầy đủ) ===
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
        _wardController.text =
            place.subAdministrativeArea ?? ''; // Quận/Huyện gán vào Phường/Xã

        // Logic khớp tên Tỉnh/Thành phố (Dùng kProvinceDisplayNames)
        String fetchedCity = place.administrativeArea ?? '';
        fetchedCity = fetchedCity
            .replaceFirst('Thành phố ', '')
            .replaceFirst('Tỉnh ', '');

        String? matchedDisplayName;
        for (var displayName in kProvinceDisplayNames.values) {
          String normalizedDisplayName = displayName
              .replaceFirst('TP. ', '')
              .replaceFirst('TĐ. ', '');
          if (normalizedDisplayName.toLowerCase() ==
              fetchedCity.toLowerCase()) {
            matchedDisplayName = displayName;
            break;
          }
        }
        _selectedCity = matchedDisplayName;
      }
    } catch (e) {
      print("Lỗi geocoding: $e");
      _showSnackBar('Không thể tự động lấy địa chỉ: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  // === LOGIC CHỌN ẢNH (Đầy đủ) ===
  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= _maxImages) {
      _showSnackBar('Chỉ được chọn tối đa $_maxImages ảnh cho địa điểm.');
      if (Navigator.canPop(context)) Navigator.pop(context);
      return;
    }

    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          int availableSlots = _maxImages - _selectedImages.length;
          int countToAdd = images.length < availableSlots
              ? images.length
              : availableSlots;
          setState(() {
            _selectedImages.addAll(images.sublist(0, countToAdd));
          });
          if (images.length > countToAdd) {
            _showSnackBar(
              'Đã đạt giới hạn $_maxImages ảnh. Chỉ thêm được $countToAdd ảnh.',
            );
          }
        }
      } else {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _selectedImages.add(image);
          });
        }
      }
    } catch (e) {
      print("Lỗi chọn ảnh: $e");
      _showSnackBar("Không thể chọn ảnh: $e", isError: true);
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Đóng dialog chọn nguồn
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.black87,
                ),
                onPressed: () => _pickImage(ImageSource.gallery),
                label: const Text(
                  'Chọn từ thư viện',
                  style: TextStyle(color: Colors.black87),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.black87,
                ),
                onPressed: () => _pickImage(ImageSource.camera),
                label: const Text(
                  'Chụp ảnh mới',
                  style: TextStyle(color: Colors.black87),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // =======================================================

  // === LOGIC UPLOAD ẢNH LÊN CLOUDINARY (Đầy đủ) ===
  Future<String?> _uploadLocalFile(XFile imageFile) async {
    File file = File(imageFile.path);
    try {
      String? uploadedUrl = await _cloudinaryService.uploadImageToCloudinary(
        file,
      );
      return uploadedUrl;
    } catch (e) {
      print("Lỗi tải ảnh '${imageFile.name}' lên Cloudinary: $e");
      _showSnackBar("Lỗi tải ảnh '${imageFile.name}'.", isError: true);
      return null;
    }
  }
  // ==============================================================

  // === HÀM GỬI FORM LÊN FIREBASE (Đã cập nhật hoàn chỉnh) ===
  Future<void> _submitForm() async {
    // Validate form trước
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar('Vui lòng kiểm tra lại các trường thông tin bắt buộc.');
      return;
    }
    // Tránh double submit
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    _showSnackBar('Đang xử lý...'); // Thông báo bắt đầu

    List<String> uploadedImageUrls = [];

    try {
      // --- BƯỚC 1: UPLOAD ẢNH ---
      if (_selectedImages.isNotEmpty) {
        List<Future<String?>> uploadFutures = [];
        for (XFile imageFile in _selectedImages) {
          uploadFutures.add(_uploadLocalFile(imageFile));
        }
        // Tải đồng thời nhiều ảnh
        List<String?> results = await Future.wait(uploadFutures);
        uploadedImageUrls = results
            .whereType<String>()
            .toList(); // Lọc bỏ các URL null (lỗi)

        // Kiểm tra xem có ảnh nào tải thành công không
        if (uploadedImageUrls.isEmpty && _selectedImages.isNotEmpty) {
          throw Exception('Không thể tải lên bất kỳ ảnh nào.');
        }
      }
      // ----------------------------

      // --- BƯỚC 2: CHUẨN BỊ DỮ LIỆU FIRESTORE ---
      final String fullAddress =
          '${_streetController.text}, ${_wardController.text}, $_selectedCity';
      final Map<String, dynamic> submissionData = {
        'submittedBy': widget.userId,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'placeData': {
          'name': _nameController.text.trim(),
          'description': _notesController.text.trim(),
          'location': {
            'coordinates': GeoPoint(
              widget.initialLatLng.latitude,
              widget.initialLatLng.longitude,
            ),
            'fullAddress': fullAddress,
            'street': _streetController.text.trim(),
            'ward': _wardController.text.trim(), // Đã thêm lại ward
            'city': _selectedCity,
          },
          'categories': [],
          'images': uploadedImageUrls, // Thêm URL ảnh đã upload
          'ratingAverage': 0,
          'reviewCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': widget.userId,
        },
        'initialReviewData': {},
      };
      // ------------------------------------------

      // --- BƯỚC 3: GỬI LÊN FIRESTORE ---
      await FirebaseFirestore.instance
          .collection('placeSubmissions')
          .add(submissionData);

      if (mounted) {
        _showSnackBar('Đã gửi yêu cầu chờ duyệt!');
        Navigator.of(context).pop(); // Quay lại
      }
      // ---------------------------------
    } catch (e) {
      print("Lỗi khi gửi submission: $e");
      if (mounted) _showSnackBar('Gửi yêu cầu thất bại: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // === GIAO DIỆN (Đã cập nhật hoàn chỉnh phần Ảnh) ===
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

                    // --- Tên địa điểm ---
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

                    // --- Tỉnh/ Thành phố (KHÓA) ---
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(
                        labelText: 'Tỉnh/ Thành phố *',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items:
                          kProvinceDisplayNames.values
                              .map(
                                (String d) => DropdownMenuItem<String>(
                                  value: d,
                                  child: Text(d),
                                ),
                              )
                              .toList()
                            ..sort((a, b) => a.value!.compareTo(b.value!)),
                      onChanged: null,
                      validator: (v) => v == null
                          ? 'Không thể xác định Tỉnh/Thành phố'
                          : null,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 16),

                    // --- Phường/Xã (Tạm - KHÓA) ---
                    TextFormField(
                      controller: _wardController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Phường/Xã (Tạm)',
                        border: const OutlineInputBorder(),
                        hintText: 'Tự động điền (dữ liệu Quận/Huyện)',
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Đường (KHÓA) ---
                    TextFormField(
                      controller: _streetController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Đường *',
                        border: const OutlineInputBorder(),
                        hintText: 'Tự động điền từ bản đồ',
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Không thể xác định tên đường'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // --- Ghi chú ---
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

                    // === PHẦN HÌNH ẢNH (ĐÃ CẬP NHẬT) ===
                    Text(
                      'Hình ảnh (${_selectedImages.length}/$_maxImages)', // Hiển thị số lượng
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildImageSelectionArea(), // Gọi widget hiển thị ảnh/nút thêm
                    // ===================================
                    const SizedBox(height: 24),

                    // --- Nút Gửi ---
                    ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : _submitForm, // Disable khi đang gửi
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

  // === WIDGET MỚI: HIỂN THỊ VÙNG CHỌN ẢNH (Đầy đủ) ===
  Widget _buildImageSelectionArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        // Tự động xuống dòng khi không đủ chỗ
        spacing: 8.0, // Khoảng cách ngang giữa các ảnh
        runSpacing: 8.0, // Khoảng cách dọc giữa các hàng ảnh
        children: [
          // Hiển thị các ảnh đã chọn dưới dạng thumbnail
          ..._selectedImages
              .map((imageFile) => _buildImageThumbnail(imageFile))
              .toList(),

          // Nút "Thêm ảnh" (hình vuông)
          // Chỉ hiển thị khi số ảnh đã chọn chưa đạt giới hạn
          if (_selectedImages.length < _maxImages)
            InkWell(
              // Dùng InkWell để có hiệu ứng ripple
              onTap: _showImageSourceDialog, // Mở dialog chọn nguồn ảnh
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80, // Kích thước ô vuông
                decoration: BoxDecoration(
                  color: Colors.grey.shade100, // Nền xám nhạt
                  borderRadius: BorderRadius.circular(8),
                  // Viền nét đứt (hoặc liền tùy ý)
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  // Căn giữa icon và text
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.grey.shade600,
                      size: 30,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thêm ảnh',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // === WIDGET MỚI: HIỂN THỊ THUMBNAIL ẢNH ĐÃ CHỌN (Đầy đủ) ===
  Widget _buildImageThumbnail(XFile imageFile) {
    return Stack(
      // Dùng Stack để đặt nút xóa lên trên ảnh
      clipBehavior: Clip.none, // Cho phép nút xóa tràn ra ngoài nhẹ
      children: [
        // Ảnh thumbnail
        ClipRRect(
          // Bo góc ảnh
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            // Hiển thị ảnh từ file local
            File(imageFile.path),
            width: 80,
            height: 80, // Kích thước ô vuông
            fit: BoxFit.cover, // Zoom và cắt ảnh cho vừa ô
            // Xử lý lỗi nếu file ảnh không hợp lệ
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.error_outline, color: Colors.red, size: 30),
              ),
            ),
          ),
        ),
        // Nút xóa ảnh (dấu 'x' nhỏ ở góc)
        Positioned(
          right: -4,
          top: -4, // Đặt lệch ra góc trên bên phải
          child: InkWell(
            // Dùng InkWell để vùng bấm lớn hơn icon
            onTap: () {
              setState(() {
                // Xóa ảnh khỏi danh sách dựa trên đường dẫn
                _selectedImages.removeWhere(
                  (file) => file.path == imageFile.path,
                );
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7), // Nền đen mờ
                shape: BoxShape.circle, // Hình tròn
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Colors.white,
              ), // Icon 'x' màu trắng
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
} // End of _AddPlaceScreenState
