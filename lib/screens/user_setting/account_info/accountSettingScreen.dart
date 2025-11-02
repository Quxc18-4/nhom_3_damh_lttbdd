// File: screens/user_setting/account_setting/accountSettingScreen.dart

import 'package:flutter/material.dart'; // Thư viện chính Flutter
import 'package:intl/intl.dart'; // Định dạng ngày tháng
import 'package:cloud_firestore/cloud_firestore.dart'; // Kết nối Firestore
import 'package:image_picker/image_picker.dart'; // Chọn ảnh
import 'dart:io'; // Dùng cho File (ảnh)

// Import Service và Widgets đã tách
import 'service/account_setting_service.dart'; // Service xử lý dữ liệu
import 'widget/account_setting_widgets.dart'; // Các widget con đã tách

class AccountSettingScreen extends StatefulWidget { // Màn hình cài đặt tài khoản
  final String userId; // ID người dùng

  const AccountSettingScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<AccountSettingScreen> createState() => _AccountSettingScreenState(); // Tạo state
}

class _AccountSettingScreenState extends State<AccountSettingScreen> { // State của màn hình
  // --- SERVICE ---
  final AccountSettingService _service = AccountSettingService(); // Khởi tạo service

  // --- CONTROLLERS ---
  final _nicknameController = TextEditingController(); // Controller cho nickname
  final _fullNameController = TextEditingController(); // Controller cho họ tên
  final _bioController = TextEditingController(); // Controller cho tiểu sử
  final _cityController = TextEditingController(); // Controller cho thành phố
  final _phoneController = TextEditingController(); // Controller cho số điện thoại
  final _emailController = TextEditingController(); // Controller cho email

  // --- STATES ---
  DateTime? _selectedDate; // Ngày sinh đã chọn
  String? _selectedGender; // Giới tính đã chọn
  bool _isLoading = true; // Đang tải dữ liệu
  bool _isEditingNickname = false; // Đang chỉnh sửa nickname
  String _currentAvatarUrl = "assets/images/logo.png"; // URL ảnh đại diện hiện tại
  File? _newAvatarFile; // File ảnh mới (chưa tải lên)
  bool _isUploadingAvatar = false; // Đang tải ảnh lên

  @override
  void initState() { // Khởi tạo khi widget được tạo
    super.initState();
    _loadUserData(); // Tải dữ liệu người dùng
  }

  @override
  void dispose() { // Dọn dẹp khi widget bị hủy
    _nicknameController.dispose(); // Giải phóng controller
    _fullNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- HÀM TIỆN ÍCH ---
  void _showSnackBar(String message, {Color color = Colors.black87}) { // Hiển thị thông báo
    if (mounted) { // Kiểm tra widget còn tồn tại
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  void _showLoading(String message) { // Hiển thị dialog loading
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho tắt bằng nút back
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(), // Vòng loading
              const SizedBox(width: 20), // Khoảng cách
              Text(message), // Thông điệp
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoading() { // Ẩn dialog loading
    if (Navigator.of(context).canPop()) { // Kiểm tra có thể pop
      Navigator.of(context).pop();
    }
  }

  // --- LOGIC XỬ LÝ DỮ LIỆU (CONTROLLERS) ---

  Future<void> _loadUserData() async { // Tải dữ liệu người dùng từ Firestore
    setState(() => _isLoading = true); // Bật loading
    try {
      final docSnapshot = await _service.loadUserData(widget.userId); // Gọi service
      if (docSnapshot.exists) { // Nếu document tồn tại
        final data = docSnapshot.data()!; // Lấy dữ liệu
        setState(() {
          _nicknameController.text = data['name'] ?? ''; // Gán nickname
          _fullNameController.text = data['fullName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _cityController.text = data['city'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _selectedGender = data['gender']?.isEmpty ? null : data['gender']; // Giới tính
          if (data['birthDate'] != null) { // Ngày sinh
            _selectedDate = (data['birthDate'] as Timestamp).toDate();
          }
          _currentAvatarUrl = data['avatarUrl'] ?? "assets/images/logo.png"; // Ảnh đại diện
        });
      }
    } catch (e) { // Bắt lỗi
      _showSnackBar("Lỗi tải dữ liệu: $e", color: Colors.red);
    } finally {
      setState(() => _isLoading = false); // Tắt loading
    }
  }

  Future<void> _updateNickname() async { // Cập nhật nickname
    try {
      await _service.updateNickname( // Gọi service
        widget.userId,
        _nicknameController.text.trim(),
      );
      setState(() => _isEditingNickname = false); // Thoát chế độ chỉnh sửa
      _showSnackBar('Cập nhật Nickname thành công!', color: Colors.green);
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst("Exception: ", ""),
        color: Colors.red,
      );
    }
  }

  Future<void> _handleAvatarChange(ImageSource source) async { // Xử lý chọn ảnh
    Navigator.pop(context); // Đóng BottomSheet
    try {
      final File? imageFile = await _service.pickImage(source); // Chọn ảnh
      if (imageFile == null) return; // Nếu không chọn

      setState(() {
        _newAvatarFile = imageFile; // Gán file mới
        _isUploadingAvatar = true; // Bật loading
      });

      final uploadedUrl = await _service.uploadAndUpdateAvatar( // Tải lên và cập nhật
        widget.userId,
        _newAvatarFile!,
      );

      setState(() {
        _currentAvatarUrl = uploadedUrl; // Cập nhật URL
        _newAvatarFile = null; // Xóa file tạm
      });
      _showSnackBar('Cập nhật ảnh đại diện thành công!', color: Colors.green);
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst("Exception: ", ""),
        color: Colors.red,
      );
      _newAvatarFile = null; // Reset nếu lỗi
    } finally {
      setState(() => _isUploadingAvatar = false); // Tắt loading
    }
  }

  Future<void> _deleteAvatar() async { // Xóa ảnh đại diện
    Navigator.pop(context); // Đóng BottomSheet
    _showLoading("Đang xóa ảnh...");
    try {
      await _service.deleteAvatar(widget.userId); // Gọi service
      setState(() => _currentAvatarUrl = "assets/images/logo.png"); // Dùng ảnh mặc định
      _hideLoading();
      _showSnackBar('Đã xóa ảnh đại diện.', color: Colors.green);
    } catch (e) {
      _hideLoading();
      _showSnackBar('Không thể xóa ảnh: $e', color: Colors.red);
    }
  }

  Future<void> _updateGeneralUserData() async { // Cập nhật thông tin chung
    _showLoading("Đang lưu thay đổi...");
    try {
      await _service.updateGeneralUserData( // Gọi service
        userId: widget.userId,
        fullName: _fullNameController.text,
        bio: _bioController.text,
        city: _cityController.text,
        phoneNumber: _phoneController.text,
        selectedDate: _selectedDate,
        selectedGender: _selectedGender,
      );
      _hideLoading();
      _showSnackBar('Cập nhật thông tin thành công!', color: Colors.green);
    } catch (e) {
      _hideLoading();
      _showSnackBar('Cập nhật thất bại: $e', color: Colors.red);
    }
  }

  Future<void> _selectDate(BuildContext context) async { // Chọn ngày sinh
    final DateTime? picked = await showDatePicker( // Mở date picker
      context: context,
      initialDate: _selectedDate ?? DateTime.now(), // Ngày mặc định
      firstDate: DateTime(1900), // Từ năm 1900
      lastDate: DateTime.now(), // Tối đa hôm nay
    );
    if (picked != null && picked != _selectedDate) { // Nếu chọn mới
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _deletePhoneNumber() async { // Xóa số điện thoại
    bool? confirmDelete = await showDialog<bool>( // Hỏi xác nhận
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa số điện thoại này?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(false), // Hủy
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true), // Xác nhận
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) { // Nếu xác nhận
      _showLoading("Đang xóa...");
      try {
        await _service.deletePhoneNumber(widget.userId); // Gọi service
        setState(() => _phoneController.clear()); // Xóa text
        _hideLoading();
        _showSnackBar('Đã xóa số điện thoại.', color: Colors.green);
      } catch (e) {
        _hideLoading();
        _showSnackBar('Xóa thất bại: $e', color: Colors.red);
      }
    }
  }

  // --- GIAO DIỆN BUILD ---

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện
    return Scaffold(
      backgroundColor: Colors.grey[50], // Nền xám nhạt
      appBar: PreferredSize( // AppBar tùy chỉnh
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50, // Nền cam nhạt
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)), // Viền dưới
          ),
          child: AppBar(
            leading: IconButton( // Nút back
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Thông tin tài khoản'), // Tiêu đề
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
        ),
      ),
      body: _isLoading // Nếu đang tải
          ? const Center(child: CircularProgressIndicator()) // Hiển thị loading
          : Stack( // Chồng lớp
              children: [
                SingleChildScrollView( // Nội dung cuộn
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Padding
                  child: Column(
                    children: [
                      // === SỬ DỤNG WIDGET MỚI ===
                      _buildAvatarSection(), // Avatar + nickname + bio
                      const SizedBox(height: 24),
                      _buildPersonalDataSection(context), // Dữ liệu cá nhân
                      const SizedBox(height: 24),
                      EmailSection(controller: _emailController), // Email
                      const SizedBox(height: 24),
                      PhoneSection( // Số điện thoại
                        controller: _phoneController,
                        onDelete: _deletePhoneNumber,
                      ),
                      const SizedBox(height: 24),
                      _buildLinkedAccountsSection(), // Liên kết tài khoản
                      // =========================
                    ],
                  ),
                ),
                Positioned( // Lớp phủ mờ ở dưới
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[50]!.withOpacity(0.0),
                          Colors.grey[50]!,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned( // Nút lưu
                  left: 16,
                  right: 16,
                  bottom: 12 + MediaQuery.of(context).padding.bottom, // Tránh notch
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateGeneralUserData, // Vô hiệu nếu loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lưu thay đổi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // === CÁC HÀM BUILD UI (GIỮ LẠI VÌ QUẢN LÝ STATE PHỨC TẠP) ===

  Widget _buildAvatarSection() { // Phần avatar, nickname, bio
    ImageProvider _getAvatarProvider() { // Xác định nguồn ảnh
      if (_newAvatarFile != null) {
        return FileImage(_newAvatarFile!); // Ảnh mới từ file
      }
      if (_currentAvatarUrl.startsWith('http')) {
        return NetworkImage(_currentAvatarUrl); // Ảnh từ mạng
      }
      return const AssetImage("assets/images/logo.png"); // Ảnh mặc định
    }

    return Column(
      children: [
        GestureDetector( // Vùng nhấn để đổi ảnh
          onTap: _isUploadingAvatar ? null : _showAvatarSourceDialog, // Mở dialog chọn ảnh
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar( // Avatar tròn
                radius: 50,
                backgroundImage: _getAvatarProvider(),
                backgroundColor: Colors.grey.shade200,
                child: _isUploadingAvatar // Nếu đang tải
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue.shade700,
                        ),
                      )
                    : null,
              ),
              Positioned( // Icon camera
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row( // Dòng nickname + nút edit
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Expanded(
              flex: 3,
              child: _isEditingNickname // Nếu đang chỉnh sửa
                  ? TextField( // Ô nhập
                      controller: _nicknameController,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text( // Hiển thị nickname
                      '@${_nicknameController.text}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton( // Nút edit/check
                  icon: Icon(
                    _isEditingNickname ? Icons.check_circle : Icons.edit,
                    color: Colors.blue,
                  ),
                  onPressed: _isUploadingAvatar
                      ? null
                      : () {
                          if (_isEditingNickname) {
                            _updateNickname(); // Lưu
                          } else {
                            setState(() => _isEditingNickname = true); // Bật chế độ edit
                          }
                        },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField( // Ô tiểu sử
          controller: _bioController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Hãy kể cho người khác về bản thân bạn.",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDataSection(BuildContext context) { // Phần dữ liệu cá nhân
    return Column(
      children: [
        buildSectionHeader("Dữ liệu cá nhân"), // Tiêu đề
        buildGroupContainer( // Khung nhóm
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLabeledTextField( // Họ tên
                "Họ tên",
                _fullNameController,
                hint: "Chưa có Họ tên",
              ),
              const SizedBox(height: 16),
              Row( // Ngày sinh + giới tính
                children: [
                  Expanded(
                    child: DatePickerWidget( // Widget chọn ngày
                      selectedDate: _selectedDate,
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GenderPickerWidget( // Widget chọn giới tính
                      selectedGender: _selectedGender,
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              buildLabeledTextField( // Thành phố
                "Thành phố cư trú",
                _cityController,
                hint: "Chưa đặt",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedAccountsSection() { // Phần liên kết tài khoản
    return Column(
      children: [
        buildSectionHeader("Liên kết tài khoản"),
        buildGroupContainer(
          child: const SizedBox(
            width: double.infinity,
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Tính năng đang được phát triển.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- BOTTOM SHEET CHỌN NGUỒN ẢNH (GIỮ LẠI VÌ CẦN STATE) ---
  void _showAvatarSourceDialog() { // Mở bottom sheet chọn ảnh
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile( // Từ thư viện
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => _handleAvatarChange(ImageSource.gallery),
            ),
            ListTile( // Chụp ảnh
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh mới'),
              onTap: () => _handleAvatarChange(ImageSource.camera),
            ),
            if (_currentAvatarUrl.startsWith('http') && !_isUploadingAvatar) // Xóa ảnh
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Xóa ảnh đại diện',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _deleteAvatar,
              ),
          ],
        ),
      ),
    );
  }
}