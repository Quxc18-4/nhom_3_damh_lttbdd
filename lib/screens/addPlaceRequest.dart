import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io'; // Cần cho File
import 'package:image_picker/image_picker.dart'; // Cần cho chọn ảnh

// Import file constants
// !!! QUAN TRỌNG: Đảm bảo đường dẫn này đúng !!!
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // <<< Sửa đường dẫn nếu cần

// ⚡️ IMPORT CLOUDINARY SERVICE
// !!! QUAN TRỌNG: Đảm bảo đường dẫn này đúng tới file service của bạn !!!
import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart'; // <<< Sửa đường dẫn nếu cần

// ⚡️ IMPORT CATEGORY MODEL (MỚI)
import 'package:nhom_3_damh_lttbdd/model/category_model.dart';

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

  List<CategoryModel> _allCategories = []; // Danh sách tất cả DM
  List<CategoryModel> _selectedCategories = []; // Danh sách DM đã chọn
  bool _isLoadingCategories = true;
  final int _maxCategories = 3; // Giới hạn 3

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
    _fetchCategories();
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

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      // 1. Query từ collection 'categories' thật
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      // 2. Map data sang CategoryModel (sử dụng factory đã tạo)
      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();

      // Sắp xếp theo tên cho dễ nhìn
      categories.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _allCategories = categories;
        });
      }
    } catch (e) {
      print("Lỗi fetch categories: $e");
      // Lỗi này có thể do Security Rules (User chưa được quyền Read)
      _showSnackBar('Không thể tải danh sách danh mục: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  // === LOGIC QUẢN LÝ DANH MỤC (MỚI) === // <<< THÊM MỚI
  void _showCategoryDialog() {
    // Lọc ra những danh mục chưa được chọn
    final availableCategories = _allCategories.where((cat) {
      // Dùng hàm == đã override trong model để so sánh
      return !_selectedCategories.contains(cat);
    }).toList();

    if (availableCategories.isEmpty) {
      _showSnackBar('Bạn đã chọn tất cả danh mục có sẵn.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn danh mục'),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: availableCategories.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final category = availableCategories[index];
                return ListTile(
                  title: Text(category.name),
                  onTap: () {
                    Navigator.of(context).pop(); // Đóng dialog trước
                    _addCategory(category); // Sau đó mới thêm
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  void _addCategory(CategoryModel category) {
    // Kiểm tra giới hạn TỐI ĐA
    if (_selectedCategories.length >= _maxCategories) {
      _showSnackBar('Chỉ được chọn tối đa $_maxCategories danh mục.');
      return; // Không cho thêm
    }
    // Kiểm tra trùng lặp (dù dialog đã lọc, cẩn thận vẫn hơn)
    if (!_selectedCategories.contains(category)) {
      setState(() {
        _selectedCategories.add(category);
      });
    }
  }

  void _removeCategory(CategoryModel category) {
    setState(() {
      // Dùng hàm remove, hàm này sẽ tìm đúng object nhờ == override
      _selectedCategories.remove(category);
    });
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

        // === THAY ĐỔI TẠI ĐÂY ===
        // Nếu không lấy được tên đường, gán "Không xác định"
        _streetController.text = place.thoroughfare ?? 'Không xác định';

        // Nếu không lấy được quận/huyện, gán "Không xác định"
        _wardController.text = place.subAdministrativeArea ?? 'Không xác định';
        // ========================

        // === Logic chuẩn hóa Tỉnh/Thành phố (Giữ nguyên) ===
        String rawPlacemarkCity = place.administrativeArea ?? '';
        String? mergedProvinceId = getMergedProvinceIdFromGeolocator(
          rawPlacemarkCity,
        );

        if (mergedProvinceId != null) {
          _selectedCity = formatProvinceIdToName(mergedProvinceId);
        } else {
          _selectedCity = null; // Vẫn để null để validator báo lỗi
          print(
            "Không thể khớp '$rawPlacemarkCity' với bất kỳ ID tỉnh/thành nào.",
          );
          _showSnackBar(
            'Không thể tự động xác định Tỉnh/Thành phố hợp lệ ($rawPlacemarkCity).',
            isError: true,
          );
        }
        // ========================================================
      } else {
        // === THÊM MỚI: Xử lý trường hợp placemarks rỗng ===
        _streetController.text = 'Không xác định';
        _wardController.text = 'Không xác định';
        _selectedCity = null; // Để validator báo lỗi
        _showSnackBar(
          'Không thể tìm thấy thông tin địa chỉ cho tọa độ này.',
          isError: true,
        );
        // ==============================================
      }
    } catch (e) {
      print("Lỗi geocoding: $e");
      // === THÊM MỚI: Xử lý khi có lỗi exception ===
      _streetController.text = 'Không xác định';
      _wardController.text = 'Không xác định';
      _selectedCity = null;
      // ===========================================
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

    if (_selectedCategories.isEmpty) {
      _showSnackBar('Vui lòng chọn ít nhất một danh mục.', isError: true);
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
      final List<String> categoryIds = _selectedCategories
          .map((cat) => cat.id)
          .toList();
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
          'categories': categoryIds,
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
      body: (_isLoadingAddress || _isLoadingCategories)
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

                    // === PHẦN DANH MỤC (MỚI) === // <<< THÊM MỚI
                    Text(
                      'Danh mục * (${_selectedCategories.length}/$_maxCategories)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryChipsArea(), // Widget hiển thị chip và nút thêm
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

  Widget _buildCategoryChipsArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8.0, // Khoảng cách ngang
        runSpacing: 8.0, // Khoảng cách dọc
        children: [
          // Hiển thị các chip đã chọn
          ..._selectedCategories
              .map((category) => _buildCategoryChip(category))
              .toList(),

          // Nút "Thêm danh mục"
          // Chỉ hiển thị khi CHƯA đạt giới hạn
          if (_selectedCategories.length < _maxCategories)
            InkWell(
              onTap: _showCategoryDialog, // Mở dialog chọn
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20), // Bo tròn
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Thêm',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // === WIDGET MỚI: HIỂN THỊ CHIP DANH MỤC (X bên trái) === // <<< THÊM MỚI
  Widget _buildCategoryChip(CategoryModel category) {
    // Tái sử dụng thiết kế "X bên trái" mà bạn thích
    return Container(
      padding: const EdgeInsets.only(left: 6, right: 10, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nút X (bên trái)
          InkWell(
            onTap: () => _removeCategory(category),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Icon(Icons.close, size: 14, color: Colors.orange.shade800),
            ),
          ),
          const SizedBox(width: 4),
          // Tên danh mục
          Text(
            category.name,
            style: TextStyle(
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
} // End of _AddPlaceScreenState
