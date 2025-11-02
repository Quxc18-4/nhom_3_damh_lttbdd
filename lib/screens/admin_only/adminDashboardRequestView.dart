// File: screens/admin_only/adminDashboardRequestView.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Import các màn hình
import 'package:nhom_3_damh_lttbdd/screens/authentication/login/loginScreen.dart';

// Import Service và Widgets đã tách
import 'service/admin_service.dart';
import 'widget/place_approval_widgets.dart';
import 'widget/banner_management_widgets.dart';

class AdminDashBoardRequestView extends StatefulWidget {
  final String userId;
  const AdminDashBoardRequestView({Key? key, required this.userId})
    : super(key: key);

  @override
  State<AdminDashBoardRequestView> createState() =>
      _AdminDashBoardRequestViewState();
}

class _AdminDashBoardRequestViewState extends State<AdminDashBoardRequestView> {
  // Service
  final AdminService _service = AdminService();

  // Biến trạng thái
  String _selectedTab = 'pending'; // 'pending', 'banners'
  File? _selectedImageFile;
  String? _manualImageUrl;

  // --- HÀM XỬ LÝ LOGIC (CONTROLLERS) ---

  Future<void> _approvePlace(DocumentSnapshot submission) async {
    final confirmed = await _showConfirmDialog(
      'Duyệt địa điểm',
      'Bạn có chắc chắn muốn duyệt địa điểm này?',
    );
    if (!confirmed) return;

    _showLoadingDialog();
    try {
      await _service.approvePlace(submission, widget.userId);
      Navigator.of(context).pop(); // Tắt loading
      _showSnackBar('Đã duyệt địa điểm thành công!');
    } catch (e) {
      Navigator.of(context).pop();
      print('Lỗi khi duyệt place: $e');
      _showSnackBar('Lỗi khi duyệt địa điểm: $e', isError: true);
    }
  }

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

  Future<void> _createBanner(
    String title,
    String content,
    int durationDays,
  ) async {
    _showLoadingDialog();
    String finalImageUrl;

    try {
      if (_selectedImageFile != null) {
        finalImageUrl = await _service.uploadImage(_selectedImageFile!);
      } else if (_manualImageUrl != null) {
        finalImageUrl = _manualImageUrl!;
      } else {
        throw Exception('Không tìm thấy URL ảnh.');
      }

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

    setState(() {
      _selectedImageFile = null;
      _manualImageUrl = null;
    });
  }

  // --- HÀM HIỂN THỊ DIALOGS & BOTTOM SHEETS ---

  Future<void> _pickImage(
    ImageSource source,
    Function(VoidCallback) setStateInDialog,
  ) async {
    try {
      final File? imageFile = await _service.pickImage(source);
      if (imageFile != null) {
        // Cập nhật state chung
        _selectedImageFile = imageFile;
        _manualImageUrl = null;

        // Cập nhật UI của dialog
        setStateInDialog(() {});

        Navigator.of(context).pop(); // Đóng Bottom Sheet
      }
    } catch (e) {
      _showSnackBar('Lỗi khi chọn ảnh: $e', isError: true);
    }
  }

  void _showImageSourceOptions(Function(VoidCallback) setStateInDialog) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
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
                Navigator.of(context).pop();
                _showManualUrlDialog(setStateInDialog);
              },
            ),
          ],
        );
      },
    );
  }

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
        false;

    if (confirmed) {
      // Cập nhật state chung
      _manualImageUrl = urlController.text.trim();
      _selectedImageFile = null;

      // Cập nhật UI của dialog
      setStateInDialog(() {});
    }
  }

  Future<void> _showCreateBannerDialog() async {
    _selectedImageFile = null;
    _manualImageUrl = null;

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    int durationDays = 7;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
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
                        _selectedImageFile != null
                            ? 'Đã chọn ảnh'
                            : (_manualImageUrl != null
                                  ? 'URL đã nhập'
                                  : 'Chọn nguồn ảnh'),
                      ),
                      onPressed: () {
                        // Bỏ async/await và gọi hàm với setStateInDialog
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
                    if (titleController.text.isEmpty ||
                        (_selectedImageFile == null &&
                            _manualImageUrl == null)) {
                      _showSnackBar(
                        'Vui lòng điền đủ Tiêu đề và chọn/nhập Ảnh.',
                        isError: true,
                      );
                    } else {
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      _createBanner(titleController.text, contentController.text, durationDays);
    }
  }

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
        false;
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildBodyContent()),
        ],
      ),
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

  Widget _buildFilterButton(String label, String status) {
    final isSelected = _selectedTab == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = status);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
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

  Widget _buildBodyContent() {
    if (_selectedTab == 'pending') {
      // === SỬ DỤNG WIDGET MỚI ===
      return PendingPlacesList(
        stream: _service.getPendingPlacesStream(),
        onApprove: _approvePlace,
        onReject: _rejectPlace,
      );
    } else {
      // === SỬ DỤNG WIDGET MỚI ===
      return BannersList(
        stream: _service.getBannersStream(),
        onDelete: _deleteBanner,
      );
    }
  }
}
