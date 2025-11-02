// File: screens/add_places/add_place_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import dù không dùng, có thể dư
import 'package:latlong2/latlong.dart'; // Import để nhận `LatLng`
import 'package:image_picker/image_picker.dart'; // Import để dùng `ImageSource` và `XFile`

// Import file constants
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';

// Import Model
import 'package:nhom_3_damh_lttbdd/model/category_model.dart';

// Import Service và Widget đã tách
import 'service/add_place_service.dart';
import 'widget/add_place_widgets.dart';

// `StatefulWidget`: Cần dùng `Stateful` vì màn hình này có rất
// nhiều trạng thái (state) cần quản lý và thay đổi:
// - Dữ liệu đang tải (loading)
// - Dữ liệu đã nhập (controllers)
// - Dữ liệu đã chọn (categories, images)
// - Trạng thái đang gửi (submitting)
class AddPlaceScreen extends StatefulWidget {
  // `final`: Thuộc tính của Widget luôn là `final`.

  // `LatLng`: Màn hình này *phải* được truyền vào một tọa độ
  // chính xác (từ màn hình bản đồ trước đó).
  final LatLng initialLatLng;

  // `String`: Cần biết ai là người gửi yêu cầu.
  final String userId;

  const AddPlaceScreen({
    Key? key,
    required this.initialLatLng, // `required` vì không thể null
    required this.userId, // `required`
  }) : super(key: key);

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

// Lớp `_` (private) chứa State
class _AddPlaceScreenState extends State<AddPlaceScreen> {
  // `GlobalKey<FormState>`: Một "chìa khóa" đặc biệt
  // để tương tác với `Form` widget.
  // Nó cho phép chúng ta gọi `_formKey.currentState?.validate()`
  // để kiểm tra tất cả `TextFormField` bên trong.
  final _formKey = GlobalKey<FormState>();

  // Khởi tạo Service
  final _service = AddPlaceService();

  // === KHAI BÁO BIẾN TRẠNG THÁI ===

  // `bool`: Dùng 3 cờ `bool` riêng biệt để quản lý UI.
  // Chúng ta không thể gộp chung thành 1 biến `_isLoading` vì
  // 2 cái đầu (`_isLoadingAddress`, `_isLoadingCategories`) dùng
  // để hiển thị spinner toàn màn hình, trong khi `_isSubmitting`
  // chỉ dùng để hiển thị spinner trên nút "Gửi".
  bool _isLoadingAddress = true;
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;

  // State: Danh mục
  // `List<CategoryModel>`:
  // `_allCategories`: Lưu danh sách *gốc* (master list) tải từ
  // service về.
  List<CategoryModel> _allCategories = [];
  // `_selectedCategories`: Lưu danh sách các mục người dùng
  // *đã chọn* (để hiển thị Chip và gửi đi).
  List<CategoryModel> _selectedCategories = [];

  // `final int`: Hằng số cấu hình.
  final int _maxCategories = 3;

  // Controllers
  // `TextEditingController`: Dùng để "điều khiển" `TextFormField`.
  // Nó cho phép chúng ta *đọc* giá trị (`_nameController.text`) và
  // *gán* giá trị (ví dụ: `_streetController.text = ...`).
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _wardController = TextEditingController();
  final _notesController = TextEditingController();

  // `String?` (nullable): Trạng thái của Tỉnh/Thành phố.
  // **Tại sao không dùng Controller?**
  // Vì `DropdownButtonFormField` quản lý giá trị của nó
  // thông qua thuộc tính `value`, không phải `controller`.
  // Nó `nullable` vì lúc đầu có thể `geocoding` không tìm thấy.
  String? _selectedCity;

  // State: Ảnh
  final ImagePicker _picker = ImagePicker(); // Instance để gọi picker

  // `List<XFile>`: Danh sách các ảnh người dùng đã chọn.
  // `XFile` là kiểu trả về của `image_picker`.
  List<XFile> _selectedImages = [];
  final int _maxImages = 5;

  @override
  // `initState`: Được gọi 1 lần duy nhất khi State được tạo.
  void initState() {
    super.initState();
    _initializeData(); // Gọi hàm tải dữ liệu ban đầu
  }

  // Gộp 2 hàm fetch ban đầu
  Future<void> _initializeData() async {
    // **Tối ưu hóa:** Dùng `Future.wait`
    // Thay vì `await _fetchAddressDetails()` rồi `await _fetchCategories()`
    // (chạy tuần tự, mất 1s + 1s = 2s),
    // `Future.wait` sẽ chạy cả hai *cùng một lúc* (song song).
    // Tổng thời gian chờ chỉ là 1s (bằng thời gian của hàm
    // chạy lâu nhất).
    await Future.wait([_fetchAddressDetails(), _fetchCategories()]);
  }

  @override
  // `dispose`: Được gọi khi State bị hủy (thoát màn hình).
  void dispose() {
    // **Rất quan trọng:** Phải `dispose()` các controller
    // để tránh rò rỉ bộ nhớ (memory leak).
    _nameController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Hàm tiện ích (đã giải thích ở file trước)
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

  // **Luồng hoạt động của `_fetchCategories`:**
  Future<void> _fetchCategories() async {
    // 1. Set cờ loading (không gọi `setState` vì `_initializeData`
    //    đã set `_isLoadingCategories = true` và `Future.wait`
    //    sẽ xử lý `finally` sau)
    // -> Ở đây code của bạn set `_isLoadingCategories = true` trong hàm này
    //    và `_isLoadingAddress = true` trong hàm kia.
    //    Điều này là hợp lý.
    setState(() => _isLoadingCategories = true);
    try {
      // 2. Gọi service
      final categories = await _service.fetchCategories();

      // 3. (Quan trọng) Kiểm tra `mounted`
      // Vì đây là hàm `async`, có thể người dùng đã
      // thoát khỏi màn hình *trước khi* service trả về.
      // Nếu gọi `setState` lúc đó, app sẽ crash.
      if (mounted) {
        // 4. Cập nhật State
        setState(() {
          _allCategories = categories; // Lưu master list
        });
      }
    } catch (e) {
      _showSnackBar('Không thể tải danh sách danh mục: $e', isError: true);
    } finally {
      // 5. Luôn luôn (dù thành công hay lỗi)
      if (mounted) {
        // Tắt cờ loading
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  // **Luồng hoạt động của `_fetchAddressDetails`:**
  Future<void> _fetchAddressDetails() async {
    // 1. Bật cờ loading
    setState(() => _isLoadingAddress = true);
    try {
      // 2. Gọi service
      final address = await _service.fetchAddressDetails(widget.initialLatLng);

      // 3. Kiểm tra `mounted`
      if (mounted) {
        // 4. Cập nhật State
        // **Đây là lúc dữ liệu được "đổ" vào UI:**
        // Gán giá trị trả về từ service vào các
        // `TextEditingController` và biến state `_selectedCity`.
        setState(() {
          _streetController.text = address.street;
          _wardController.text = address.ward;
          _selectedCity = address.city;

          // Nếu service không thể chuẩn hóa Tỉnh/Thành
          if (address.city == null) {
            _showSnackBar(
              'Không thể tự động xác định Tỉnh/Thành phố hợp lệ (${address.rawCity}).',
              isError: true,
            );
          }
        });
      }
    } catch (e) {
      // 5. Xử lý nếu `geocoding` thất bại
      if (mounted) {
        // Gán giá trị rỗng/null để người dùng biết
        _streetController.text = 'Không xác định';
        _wardController.text = 'Không xác định';
        _selectedCity = null;
        _showSnackBar('Không thể tự động lấy địa chỉ: $e', isError: true);
      }
    } finally {
      // 6. Luôn tắt cờ loading
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  // === LOGIC QUẢN LÝ DANH MỤC (Giữ nguyên) ===
  // Các hàm này (`_showCategoryDialog`, `_addCategory`, `_removeCategory`)
  // là logic *nội bộ* của UI. Chúng chỉ thao tác với các
  // biến state (`_selectedCategories`, `_allCategories`) và
  // gọi `setState()`. Chúng không cần nằm trong Service.
  void _showCategoryDialog() {
    // Lọc ra danh sách
    final availableCategories = _allCategories
        .where((cat) => !_selectedCategories.contains(cat))
        .toList();

    if (availableCategories.isEmpty) {
      _showSnackBar('Bạn đã chọn tất cả danh mục có sẵn.');
      return;
    }

    // Hiển thị 1 `AlertDialog`
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn danh mục'),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              // Hiển thị list
              itemCount: availableCategories.length,
              shrinkWrap: true, // Chỉ cao vừa đủ nội dung
              itemBuilder: (context, index) {
                final category = availableCategories[index];
                return ListTile(
                  title: Text(category.name),
                  onTap: () {
                    Navigator.of(context).pop(); // Đóng dialog
                    _addCategory(category); // Gọi hàm thêm
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
      // `setState`: Báo cho Flutter biết state đã thay đổi
      // và `build()` lại UI (cụ thể là `CategoryChipsArea`).
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
  // Tương tự, đây là logic UI, nằm trong State là đúng.
  Future<void> _pickImage(ImageSource source) async {
    // Kiểm tra giới hạn
    if (_selectedImages.length >= _maxImages) {
      _showSnackBar('Chỉ được chọn tối đa $_maxImages ảnh cho địa điểm.');
      if (Navigator.canPop(context)) Navigator.pop(context);
      return;
    }

    try {
      if (source == ImageSource.gallery) {
        // 1. Gọi `pickMultiImage`
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          // 2. Tính toán số lượng còn lại có thể thêm
          int availableSlots = _maxImages - _selectedImages.length;
          int countToAdd = images.length < availableSlots
              ? images.length
              : availableSlots;
          // 3. Cập nhật state
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
        // (source == ImageSource.camera)
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

  // Hiển thị BottomSheet chọn Camera/Gallery
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
                onPressed: () =>
                    _pickImage(ImageSource.gallery), // Gọi hàm trên
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
                onPressed: () => _pickImage(ImageSource.camera), // Gọi hàm trên
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
  // **Luồng hoạt động của `_submitForm`:**
  Future<void> _submitForm() async {
    // 1. **Validation (Phần 1):**
    // Gọi `validate()` trên `FormState` thông qua `_formKey`.
    // Thao tác này sẽ kích hoạt `validator` của *tất cả*
    // `TextFormField` và `DropdownButtonFormField` bên trong `Form`.
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar('Vui lòng kiểm tra lại các trường thông tin bắt buộc.');
      return; // Dừng lại nếu form không hợp lệ
    }

    // 2. **Validation (Phần 2):**
    // Kiểm tra logic tùy chỉnh (custom logic) mà `Form`
    // không thể tự kiểm tra (ví dụ: phải chọn ít nhất 1 category).
    if (_selectedCategories.isEmpty) {
      _showSnackBar('Vui lòng chọn ít nhất một danh mục.', isError: true);
      return; // Dừng lại
    }

    // 3. Ngăn chặn spam click
    if (_isSubmitting) return;

    // 4. Bật cờ `_isSubmitting` và `setState`.
    // -> UI sẽ build lại, `ElevatedButton` sẽ
    //    hiển thị `CircularProgressIndicator`.
    setState(() => _isSubmitting = true);
    _showSnackBar('Đang xử lý...');

    try {
      // 5. **GỌI SERVICE:**
      // Gom tất cả dữ liệu từ state và controllers
      // (`.text.trim()`, `_selectedCategories`...) và
      // "ném" chúng cho `AddPlaceService`.
      // `State` không quan tâm `Service` upload ảnh
      // hay ghi Firestore thế nào. Nó chỉ cần biết "gửi đi".
      await _service.submitPlaceRequest(
        userId: widget.userId,
        latLng: widget.initialLatLng,
        name: _nameController.text.trim(),
        notes: _notesController.text.trim(),
        street: _streetController.text.trim(),
        ward: _wardController.text.trim(),
        city: _selectedCity!, // Dùng `!` (null assertion) vì
        // `_formKey.validate()` đã
        // kiểm tra `_selectedCity != null`
        selectedCategories: _selectedCategories,
        selectedImages: _selectedImages,
      );

      // 6. Xử lý khi thành công
      if (mounted) {
        _showSnackBar('Đã gửi yêu cầu chờ duyệt!');
        Navigator.of(context).pop(); // Đóng màn hình
      }
    } catch (e) {
      // 7. Xử lý khi Service ném lỗi (`rethrow`)
      if (mounted) _showSnackBar('Gửi yêu cầu thất bại: $e', isError: true);
    } finally {
      // 8. Luôn luôn tắt cờ submitting (dù thành công hay lỗi)
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // === GIAO DIỆN (ĐÃ GỌI WIDGET MỚI) ===
  @override
  Widget build(BuildContext context) {
    // Biến `bool` cục bộ: Nếu 1 trong 2 (hoặc cả 2) đang tải -> `true`
    bool isLoading = _isLoadingAddress || _isLoadingCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký địa điểm mới')),
      // **Logic hiển thị chính:**
      // Nếu `isLoading` -> Hiển thị spinner toàn màn hình
      // Ngược lại -> Hiển thị `SingleChildScrollView` chứa `Form`
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                // Bọc tất cả bằng `Form`
                key: _formKey, // Gắn `key`
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Kéo dãn
                  children: [
                    Text(
                      'Thông tin địa điểm',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Tên địa điểm
                    TextFormField(
                      controller: _nameController, // Gắn controller
                      decoration: const InputDecoration(
                        labelText: 'Tên địa điểm *', // Dấu * cho biết bắt buộc
                        border: OutlineInputBorder(),
                        hintText: 'Nhập tên địa điểm',
                      ),
                      // `validator`: Được gọi bởi `_formKey.validate()`
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Vui lòng nhập tên địa điểm' // Trả về `String` (lỗi)
                          : null, // Trả về `null` (hợp lệ)
                    ),
                    const SizedBox(height: 16),

                    // Tỉnh/ Thành phố (KHÓA)
                    DropdownButtonFormField<String>(
                      value: _selectedCity, // Giá trị được bind với state
                      decoration: InputDecoration(
                        labelText: 'Tỉnh/ Thành phố *',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100], // Màu xám (bị khóa)
                      ),
                      // `items`: Danh sách các lựa chọn
                      items:
                          kProvinceDisplayNames
                              .values // Lấy list tên hiển thị
                              .map(
                                (String d) => DropdownMenuItem<String>(
                                  value: d,
                                  child: Text(d),
                                ),
                              )
                              .toList() // Chuyển thành `List<DropdownMenuItem>`
                            ..sort(
                              (a, b) => a.value!.compareTo(b.value!),
                            ), // Sắp xếp
                      // `onChanged: null`: Đây là cách VÔ HIỆU HÓA
                      // (disable) `DropdownButton`. Người dùng
                      // không thể bấm chọn, chỉ có thể xem.
                      onChanged: null,

                      validator: (v) => v == null
                          ? 'Không thể xác định Tỉnh/Thành phố'
                          : null,
                      isExpanded: true, // Cho text chiếm hết chiều ngang
                    ),
                    const SizedBox(height: 16),

                    // Phường/Xã (KHÓA)
                    TextFormField(
                      controller: _wardController,
                      readOnly: true, // Khóa, không cho sửa
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
                      readOnly: true, // Khóa
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
                    // Gọi widget con (từ file `add_place_widgets.dart`)
                    CategoryChipsArea(
                      // **Truyền Dữ liệu (State) xuống:**
                      selectedCategories: _selectedCategories,
                      maxCategories: _maxCategories,

                      // **Truyền Hàm (Callback) xuống:**
                      // Khi `CategoryChipsArea` gọi `onAdd` (bấm nút "Thêm")...
                      onAdd:
                          _showCategoryDialog, // ...nó sẽ thực thi hàm `_showCategoryDialog` (của State này).
                      // Khi `CategoryChipsArea` gọi `onRemove(category)`...
                      onRemove:
                          _removeCategory, // ...nó sẽ thực thi hàm `_removeCategory` (của State này).
                    ),
                    const SizedBox(height: 16),

                    // === PHẦN HÌNH ẢNH (DÙNG WIDGET MỚI) ===
                    Text(
                      'Hình ảnh (${_selectedImages.length}/$_maxImages)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    // Tương tự, gọi widget con
                    ImageSelectionArea(
                      // Truyền state
                      selectedImages: _selectedImages,
                      maxImages: _maxImages,

                      // Truyền callback
                      onAdd: _showImageSourceDialog,
                      onRemove: (file) {
                        // Logic xóa được định nghĩa ngay tại đây
                        // (vì nó ngắn gọn) và gọi `setState`.
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
                      // `onPressed` sẽ là `null` nếu `_isSubmitting` là `true`.
                      // `onPressed: null` sẽ tự động vô hiệu hóa nút.
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      // **Logic thay đổi `child` của nút:**
                      // Nếu `_isSubmitting` là `true` -> Hiển thị spinner
                      // Ngược lại -> Hiển thị Text
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
