// File: screens/admin_only/adminDashboardRequestView.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Import các màn hình
import 'package:nhom_3_damh_lttbdd/screens/authentication/login/loginScreen.dart';

// Import Service và Widgets đã tách
import 'service/admin_service.dart'; // Import bộ não (Service)
import 'widget/place_approval_widgets.dart'; // Import UI cho tab 1
import 'widget/banner_management_widgets.dart'; // Import UI cho tab 2

class AdminDashBoardRequestView extends StatefulWidget {
  final String userId; // Nhận ID của admin đang đăng nhập
  const AdminDashBoardRequestView({Key? key, required this.userId})
    : super(key: key);

  @override
  State<AdminDashBoardRequestView> createState() =>
      _AdminDashBoardRequestViewState();
}

// Lớp State, chứa trạng thái và logic
class _AdminDashBoardRequestViewState extends State<AdminDashBoardRequestView> {
  // Service
  final AdminService _service = AdminService(); // Khởi tạo 1 instance service

  // Biến trạng thái
  // `_selectedTab`: Lưu `String` ('pending' hoặc 'banners')
  // để quyết định hiển thị UI nào. Đây là biến trạng thái
  // quan trọng nhất của màn hình này.
  String _selectedTab = 'pending'; // Mặc định là 'pending'

  // Các biến state này chỉ dùng cho dialog "Tạo Banner"
  File? _selectedImageFile; // Lưu file ảnh nếu chọn từ máy
  String? _manualImageUrl; // Lưu URL nếu nhập tay

  // --- HÀM XỬ LÝ LOGIC (CONTROLLERS) ---
  // Các hàm này đóng vai trò "controller" hoặc "view-model".
  // Chúng được gọi bởi UI, sau đó chúng gọi Service.

  /// Luồng hoạt động của hàm `_approvePlace`
  Future<void> _approvePlace(DocumentSnapshot submission) async {
    // 1. Hỏi xác nhận
    final confirmed = await _showConfirmDialog(
      'Duyệt địa điểm',
      'Bạn có chắc chắn muốn duyệt địa điểm này?',
    );
    if (!confirmed) return; // Nếu bấm "Hủy", dừng lại

    // 2. Hiển thị dialog loading (xoay xoay)
    _showLoadingDialog();

    // 3. `try...catch`: Bọc logic gọi service
    try {
      // 4. Gọi service
      await _service.approvePlace(submission, widget.userId);
      Navigator.of(context).pop(); // 5. Tắt loading
      _showSnackBar('Đã duyệt địa điểm thành công!'); // 6. Báo thành công
    } catch (e) {
      Navigator.of(context).pop(); // 5. Tắt loading (dù lỗi)
      print('Lỗi khi duyệt place: $e');
      _showSnackBar('Lỗi khi duyệt địa điểm: $e', isError: true); // 6. Báo lỗi
    }
  }

  /// Luồng hoạt động của `_rejectPlace` (tương tự `_approvePlace`)
  Future<void> _rejectPlace(String submissionId) async {
    final confirmed = await _showConfirmDialog(
      'Từ chối địa điểm',
      'Bạn có chắc chắn muốn từ chối địa điểm này?',
    );
    if (!confirmed) return;

    _showLoadingDialog();
    try {
      await _service.rejectPlace(submissionId, widget.userId);
      Navigator.of(context).pop();
      _showSnackBar('Đã từ chối địa điểm.');
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar('Lỗi khi từ chối địa điểm: $e', isError: true);
    }
  }

  /// Luồng hoạt động của `_deleteBanner` (tương tự)
  Future<void> _deleteBanner(String bannerId, String title) async {
    final confirmed = await _showConfirmDialog(
      'Xóa Banner',
      'Bạn có chắc chắn muốn xóa banner "$title"?',
    );
    if (!confirmed) return;

    _showLoadingDialog();
    try {
      await _service.deleteBanner(bannerId);
      Navigator.of(context).pop();
      _showSnackBar('Đã xóa Banner thành công!');
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar('Lỗi khi xóa Banner: $e', isError: true);
    }
  }

  /// Luồng hoạt động của `_createBanner`
  Future<void> _createBanner(
    String title,
    String content,
    int durationDays,
  ) async {
    _showLoadingDialog();
    String finalImageUrl; // Biến lưu URL cuối cùng

    try {
      // 1. Xử lý ảnh
      if (_selectedImageFile != null) {
        // Nếu người dùng chọn ảnh từ file
        // -> Gọi service upload
        finalImageUrl = await _service.uploadImage(_selectedImageFile!);
      } else if (_manualImageUrl != null) {
        // Nếu người dùng nhập URL
        finalImageUrl = _manualImageUrl!; // Dùng trực tiếp
      } else {
        throw Exception('Không tìm thấy URL ảnh.');
      }

      // 2. Gọi service tạo banner
      await _service.createBanner(
        title: title,
        content: content,
        durationDays: durationDays,
        imageUrl: finalImageUrl,
        adminUserId: widget.userId,
      );

      Navigator.of(context).pop(); // Tắt loading
      _showSnackBar('Đã tạo Banner thành công!');
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar('Lỗi khi tạo Banner: $e', isError: true);
    }

    // 3. Dọn dẹp state (rất quan trọng)
    // Xóa file/url đã chọn để lần sau mở dialog, nó sẽ trống
    setState(() {
      _selectedImageFile = null;
      _manualImageUrl = null;
    });
  }

  // --- HÀM HIỂN THỊ DIALOGS & BOTTOM SHEETS ---

  // Hàm này rất đặc biệt
  Future<void> _pickImage(
    ImageSource source,
    // `Function(VoidCallback)`:
    // Nhận vào một hàm `setState` của *dialog*.
    // **Tại sao?**
    // Khi ta chọn ảnh xong, ta cần cập nhật 2 thứ:
    // 1. Biến state của Màn hình (`_selectedImageFile = ...`).
    // 2. UI của Dialog (ví dụ: đổi text nút 'Chọn nguồn ảnh'
    //    thành 'Đã chọn ảnh').
    // Để cập nhật UI của Dialog, ta phải gọi hàm `setState`
    // của chính cái `StatefulBuilder` (bên dưới) tạo ra nó.
    Function(VoidCallback) setStateInDialog,
  ) async {
    try {
      final File? imageFile = await _service.pickImage(source);
      if (imageFile != null) {
        // Cập nhật state chung (của màn hình)
        _selectedImageFile = imageFile;
        _manualImageUrl = null; // Reset cái kia

        // Cập nhật UI của dialog (bằng cách gọi hàm `setState` của nó)
        setStateInDialog(() {});

        Navigator.of(context).pop(); // Đóng Bottom Sheet (chọn camera/gallery)
      }
    } catch (e) {
      _showSnackBar('Lỗi khi chọn ảnh: $e', isError: true);
    }
  }

  // Hiển thị Bottom Sheet (trượt từ dưới lên)
  void _showImageSourceOptions(Function(VoidCallback) setStateInDialog) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min, // Chỉ cao vừa đủ
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ Thư viện (Gallery)'),
              onTap: () => _pickImage(ImageSource.gallery, setStateInDialog),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh (Camera)'),
              onTap: () => _pickImage(ImageSource.camera, setStateInDialog),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Nhập URL thủ công'),
              onTap: () {
                Navigator.of(context).pop(); // Đóng bottom sheet
                _showManualUrlDialog(setStateInDialog); // Mở dialog nhập URL
              },
            ),
          ],
        );
      },
    );
  }

  // Hiển thị Dialog nhập URL
  Future<void> _showManualUrlDialog(
    Function(VoidCallback) setStateInDialog,
  ) async {
    final urlController = TextEditingController(text: _manualImageUrl);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nhập URL Ảnh'),
            content: TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL Ảnh Banner',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        ) ??
        false; // `?? false`: Nếu người dùng bấm ra ngoài, coi như là 'Hủy'

    if (confirmed) {
      // Cập nhật state chung (của màn hình)
      _manualImageUrl = urlController.text.trim();
      _selectedImageFile = null; // Reset cái kia

      // Cập nhật UI của dialog
      setStateInDialog(() {});
    }
  }

  // Hiển thị Dialog tạo Banner (phức tạp)
  Future<void> _showCreateBannerDialog() async {
    // 1. Reset state
    _selectedImageFile = null;
    _manualImageUrl = null;

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    int durationDays = 7; // Giá trị mặc định

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        // **Giải thích `StatefulBuilder`:**
        // `AlertDialog` là `stateless`. Nếu ta chọn 1 ảnh
        // (thay đổi `_selectedImageFile`) hoặc chọn Dropdown
        // (thay đổi `durationDays`), dialog sẽ không
        // tự cập nhật UI.
        // `StatefulBuilder` tạo ra một "state mini" bên trong
        // dialog, và cung cấp hàm `setStateInDialog`
        // để "build lại" *chỉ nội dung của dialog*.
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Tạo Banner/News Feed Mới'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề Banner',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung Banner (Content)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: Text(
                        // **Logic UI động:**
                        // Thay đổi text của nút dựa trên state
                        _selectedImageFile != null
                            ? 'Đã chọn ảnh'
                            : (_manualImageUrl != null
                                  ? 'URL đã nhập'
                                  : 'Chọn nguồn ảnh'),
                      ),
                      onPressed: () {
                        // Truyền hàm `setStateInDialog`
                        // vào cho các hàm con.
                        _showImageSourceOptions(setStateInDialog);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_manualImageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'URL: $_manualImageUrl',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Thời gian hiển thị (ngày):'),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: durationDays,
                          items: [1, 3, 7, 14, 30]
                              .map(
                                (day) => DropdownMenuItem(
                                  value: day,
                                  child: Text('$day ngày'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              // Gọi `setStateInDialog` để
                              // cập nhật UI của Dropdown
                              setStateInDialog(() => durationDays = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Tạo'),
                  onPressed: () {
                    // Validation
                    if (titleController.text.isEmpty ||
                        (_selectedImageFile == null &&
                            _manualImageUrl == null)) {
                      _showSnackBar(
                        'Vui lòng điền đủ Tiêu đề và chọn/nhập Ảnh.',
                        isError: true,
                      );
                    } else {
                      Navigator.of(
                        context,
                      ).pop(true); // Đóng dialog, trả về `true`
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    // 4. Nếu `showDialog` trả về `true` (bấm "Tạo")
    if (result == true) {
      _createBanner(titleController.text, contentController.text, durationDays);
    }
  }

  // Dialog đăng xuất
  Future<void> _showLogoutDialog() async {
    final confirmed = await _showConfirmDialog(
      'Đăng xuất',
      'Bạn có chắc chắn muốn đăng xuất?',
    );
    if (confirmed) {
      _showLoadingDialog();
      try {
        await _service.signOut();
        if (mounted) {
          Navigator.of(context).pop(); // Tắt loading
          // `pushReplacement`: Thay thế màn hình hiện tại
          // bằng màn hình Login (người dùng không thể "Back"
          // lại trang Admin).
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        _showSnackBar('Lỗi khi đăng xuất: $e', isError: true);
      }
    }
  }

  // --- HÀM HỖ TRỢ CHUNG (DIALOGS) ---
  // Các hàm này được dùng đi dùng lại nhiều lần

  /// Hiển thị dialog xác nhận (Có/Hủy)
  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        ) ??
        false; // Nếu bấm ngoài, coi như `false`
  }

  /// Hiển thị dialog loading
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho bấm ra ngoài để tắt
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  /// Hiển thị SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return; // Rất quan trọng: Kiểm tra xem UI còn tồn tại không
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red
            : Colors.green, // Màu đỏ hoặc xanh
        behavior: SnackBarBehavior.floating, // Kiểu "nổi"
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- WIDGETS BUILD CHÍNH ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Duyệt & Banner'),
        backgroundColor: Colors.teal,
        actions: [
          // Nút bên phải AppBar
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog, // Gọi hàm đăng xuất
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(), // Thanh chọn tab (UI)
          Expanded(child: _buildBodyContent()), // Nội dung chính (UI)
        ],
      ),
      // **Logic Hiển thị `FloatingActionButton`:**
      // Dùng toán tử 3 ngôi (ternary operator)
      // Nếu `_selectedTab` là 'banners' -> Hiển thị nút
      // Ngược lại -> `null` (không hiển thị gì)
      floatingActionButton: _selectedTab == 'banners'
          ? FloatingActionButton.extended(
              onPressed: _showCreateBannerDialog,
              label: const Text('Thêm Banner'),
              icon: const Icon(Icons.add),
              backgroundColor: Colors.teal,
            )
          : null,
    );
  }

  // Hàm private xây dựng UI cho thanh Tab
  Widget _buildFilterTabs() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterButton('Chờ duyệt Địa điểm', 'pending'),
          _buildFilterButton('Quản lý Banner', 'banners'),
        ],
      ),
    );
  }

  // Hàm private xây dựng UI cho 1 nút Tab
  Widget _buildFilterButton(String label, String status) {
    // Kiểm tra xem nút này có đang được chọn không
    final isSelected = _selectedTab == status;

    return Expanded(
      // `Expanded`: Cho 2 nút chia đều
      child: GestureDetector(
        // **Đây là logic chính:**
        // Khi bấm vào...
        onTap: () {
          // ...gọi `setState` để cập nhật `_selectedTab`.
          // Ngay lập tức, `build()` sẽ được gọi lại.
          // `isSelected` của nút này thành `true` (đổi màu)
          // `_buildBodyContent()` sẽ hiển thị nội dung mới.
          setState(() => _selectedTab = status);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // **Logic UI động:**
            // Đổi màu dựa trên `isSelected`
            color: isSelected ? Colors.teal : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.teal : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Hàm private xây dựng Nội dung chính
  Widget _buildBodyContent() {
    // **Logic cốt lõi của màn hình:**
    // Dùng `if` để quyết định render widget nào

    if (_selectedTab == 'pending') {
      // === SỬ DỤNG WIDGET MỚI (Tab 1) ===
      // `PendingPlacesList` là 1 widget "ngu ngốc" (dumb)
      // Nó nhận vào 2 thứ:
      // 1. `stream`: Dữ liệu để nó tự hiển thị
      // 2. `onApprove`, `onReject`: Các hàm *callback*
      //    (hàm của `State` này) để khi người dùng
      //    bấm nút, nó sẽ gọi ngược lại.
      return PendingPlacesList(
        stream: _service.getPendingPlacesStream(),
        onApprove: _approvePlace,
        onReject: _rejectPlace,
      );
    } else {
      // === SỬ DỤNG WIDGET MỚI (Tab 2) ===
      // Tương tự, `BannersList` là 1 widget "ngu ngốc"
      return BannersList(
        stream: _service.getBannersStream(),
        onDelete: _deleteBanner,
      );
    }
  }
}
