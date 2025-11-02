// File: screens/add_places/add_place_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';

// Import file constants
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';

// Import Model
import 'package:nhom_3_damh_lttbdd/model/category_model.dart';

// Import Service và Widget đã tách
import 'service/add_place_service.dart';
import 'widget/add_place_widgets.dart';

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
  final _service = AddPlaceService(); // Khởi tạo Service

  // State
  bool _isLoadingAddress = true;
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;

  // State: Danh mục
  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _selectedCategories = [];
  final int _maxCategories = 3;

  // Controllers
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _wardController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCity;

  // State: Ảnh
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  final int _maxImages = 5;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Gộp 2 hàm fetch ban đầu
  Future<void> _initializeData() async {
    // Chạy song song
    await Future.wait([_fetchAddressDetails(), _fetchCategories()]);
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

  // === LOGIC TẢI DỮ LIỆU (ĐÃ GỌI SERVICE) ===
  Future<void> _fetchCategories() async {
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

  Future<void> _fetchAddressDetails() async {
    setState(() => _isLoadingAddress = true);
    try {
      final address = await _service.fetchAddressDetails(widget.initialLatLng);
      if (mounted) {
        setState(() {
          _streetController.text = address.street;
          _wardController.text = address.ward;
          _selectedCity = address.city;
          if (address.city == null) {
            _showSnackBar(
              'Không thể tự động xác định Tỉnh/Thành phố hợp lệ (${address.rawCity}).',
              isError: true,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _streetController.text = 'Không xác định';
        _wardController.text = 'Không xác định';
        _selectedCity = null;
        _showSnackBar('Không thể tự động lấy địa chỉ: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  // === LOGIC QUẢN LÝ DANH MỤC (Giữ nguyên) ===
  void _showCategoryDialog() {
    final availableCategories = _allCategories
        .where((cat) => !_selectedCategories.contains(cat))
        .toList();

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
                    Navigator.of(context).pop();
                    _addCategory(category);
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
    if (_selectedCategories.length >= _maxCategories) {
      _showSnackBar('Chỉ được chọn tối đa $_maxCategories danh mục.');
      return;
    }
    if (!_selectedCategories.contains(category)) {
      setState(() {
        _selectedCategories.add(category);
      });
    }
  }

  void _removeCategory(CategoryModel category) {
    setState(() {
      _selectedCategories.remove(category);
    });
  }

  // === LOGIC CHỌN ẢNH (Giữ nguyên) ===
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

  // === HÀM GỬI FORM (ĐÃ GỌI SERVICE) ===
  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar('Vui lòng kiểm tra lại các trường thông tin bắt buộc.');
      return;
    }

    if (_selectedCategories.isEmpty) {
      _showSnackBar('Vui lòng chọn ít nhất một danh mục.', isError: true);
      return;
    }

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    _showSnackBar('Đang xử lý...');

    try {
      // Gọi service để submit
      await _service.submitPlaceRequest(
        userId: widget.userId,
        latLng: widget.initialLatLng,
        name: _nameController.text.trim(),
        notes: _notesController.text.trim(),
        street: _streetController.text.trim(),
        ward: _wardController.text.trim(),
        city: _selectedCity!, // Đã validate không null
        selectedCategories: _selectedCategories,
        selectedImages: _selectedImages,
      );

      if (mounted) {
        _showSnackBar('Đã gửi yêu cầu chờ duyệt!');
        Navigator.of(context).pop(); // Quay lại
      }
    } catch (e) {
      if (mounted) _showSnackBar('Gửi yêu cầu thất bại: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // === GIAO DIỆN (ĐÃ GỌI WIDGET MỚI) ===
  @override
  Widget build(BuildContext context) {
    bool isLoading = _isLoadingAddress || _isLoadingCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký địa điểm mới')),
      body: isLoading
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

                    // Tên địa điểm
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

                    // Tỉnh/ Thành phố (KHÓA)
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

                    // Phường/Xã (KHÓA)
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

                    // Đường (KHÓA)
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

                    // Ghi chú
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

                    // === PHẦN DANH MỤC (DÙNG WIDGET MỚI) ===
                    Text(
                      'Danh mục * (${_selectedCategories.length}/$_maxCategories)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    CategoryChipsArea(
                      selectedCategories: _selectedCategories,
                      maxCategories: _maxCategories,
                      onAdd: _showCategoryDialog,
                      onRemove: _removeCategory,
                    ),
                    const SizedBox(height: 16),

                    // === PHẦN HÌNH ẢNH (DÙNG WIDGET MỚI) ===
                    Text(
                      'Hình ảnh (${_selectedImages.length}/$_maxImages)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ImageSelectionArea(
                      selectedImages: _selectedImages,
                      maxImages: _maxImages,
                      onAdd: _showImageSourceDialog,
                      onRemove: (file) {
                        setState(() {
                          _selectedImages.removeWhere(
                            (f) => f.path == file.path,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Nút Gửi
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
}
