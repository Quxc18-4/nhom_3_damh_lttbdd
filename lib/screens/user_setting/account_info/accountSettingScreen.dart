// File: screens/user_setting/account_setting/accountSettingScreen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Import Service và Widgets đã tách
import 'service/account_setting_service.dart';
import 'widget/account_setting_widgets.dart';

class AccountSettingScreen extends StatefulWidget {
  final String userId;

  const AccountSettingScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<AccountSettingScreen> createState() => _AccountSettingScreenState();
}

class _AccountSettingScreenState extends State<AccountSettingScreen> {
  // --- SERVICE ---
  final AccountSettingService _service = AccountSettingService();

  // --- CONTROLLERS ---
  final _nicknameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // --- STATES ---
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = true;
  bool _isEditingNickname = false;
  String _currentAvatarUrl = "assets/images/logo.png";
  File? _newAvatarFile;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- HÀM TIỆN ÍCH ---
  void _showSnackBar(String message, {Color color = Colors.black87}) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoading() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // --- LOGIC XỬ LÝ DỮ LIỆU (CONTROLLERS) ---

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final docSnapshot = await _service.loadUserData(widget.userId);
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          _nicknameController.text = data['name'] ?? '';
          _fullNameController.text = data['fullName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _cityController.text = data['city'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _selectedGender = data['gender']?.isEmpty ? null : data['gender'];
          if (data['birthDate'] != null) {
            _selectedDate = (data['birthDate'] as Timestamp).toDate();
          }
          _currentAvatarUrl = data['avatarUrl'] ?? "assets/images/logo.png";
        });
      }
    } catch (e) {
      _showSnackBar("Lỗi tải dữ liệu: $e", color: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNickname() async {
    try {
      await _service.updateNickname(
        widget.userId,
        _nicknameController.text.trim(),
      );
      setState(() => _isEditingNickname = false);
      _showSnackBar('Cập nhật Nickname thành công!', color: Colors.green);
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst("Exception: ", ""),
        color: Colors.red,
      );
    }
  }

  Future<void> _handleAvatarChange(ImageSource source) async {
    Navigator.pop(context); // Đóng BottomSheet
    try {
      final File? imageFile = await _service.pickImage(source);
      if (imageFile == null) return;

      setState(() {
        _newAvatarFile = imageFile;
        _isUploadingAvatar = true;
      });

      final uploadedUrl = await _service.uploadAndUpdateAvatar(
        widget.userId,
        _newAvatarFile!,
      );

      setState(() {
        _currentAvatarUrl = uploadedUrl;
        _newAvatarFile = null;
      });
      _showSnackBar('Cập nhật ảnh đại diện thành công!', color: Colors.green);
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst("Exception: ", ""),
        color: Colors.red,
      );
      _newAvatarFile = null; // Reset nếu lỗi
    } finally {
      setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _deleteAvatar() async {
    Navigator.pop(context); // Đóng BottomSheet
    _showLoading("Đang xóa ảnh...");
    try {
      await _service.deleteAvatar(widget.userId);
      setState(() => _currentAvatarUrl = "assets/images/logo.png");
      _hideLoading();
      _showSnackBar('Đã xóa ảnh đại diện.', color: Colors.green);
    } catch (e) {
      _hideLoading();
      _showSnackBar('Không thể xóa ảnh: $e', color: Colors.red);
    }
  }

  Future<void> _updateGeneralUserData() async {
    _showLoading("Đang lưu thay đổi...");
    try {
      await _service.updateGeneralUserData(
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _deletePhoneNumber() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa số điện thoại này?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      _showLoading("Đang xóa...");
      try {
        await _service.deletePhoneNumber(widget.userId);
        setState(() => _phoneController.clear());
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Thông tin tài khoản'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    children: [
                      // === SỬ DỤNG WIDGET MỚI ===
                      _buildAvatarSection(), // Giữ lại hàm này vì nó phức tạp
                      const SizedBox(height: 24),
                      _buildPersonalDataSection(context), // Giữ lại hàm này
                      const SizedBox(height: 24),
                      EmailSection(controller: _emailController),
                      const SizedBox(height: 24),
                      PhoneSection(
                        controller: _phoneController,
                        onDelete: _deletePhoneNumber,
                      ),
                      const SizedBox(height: 24),
                      _buildLinkedAccountsSection(), // Giữ lại hàm này
                      // =========================
                    ],
                  ),
                ),
                Positioned(
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
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12 + MediaQuery.of(context).padding.bottom,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateGeneralUserData,
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

  Widget _buildAvatarSection() {
    ImageProvider _getAvatarProvider() {
      if (_newAvatarFile != null) {
        return FileImage(_newAvatarFile!);
      }
      if (_currentAvatarUrl.startsWith('http')) {
        return NetworkImage(_currentAvatarUrl);
      }
      return const AssetImage("assets/images/logo.png");
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _isUploadingAvatar ? null : _showAvatarSourceDialog,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _getAvatarProvider(),
                backgroundColor: Colors.grey.shade200,
                child: _isUploadingAvatar
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue.shade700,
                        ),
                      )
                    : null,
              ),
              Positioned(
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Expanded(
              flex: 3,
              child: _isEditingNickname
                  ? TextField(
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
                  : Text(
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
                child: IconButton(
                  icon: Icon(
                    _isEditingNickname ? Icons.check_circle : Icons.edit,
                    color: Colors.blue,
                  ),
                  onPressed: _isUploadingAvatar
                      ? null
                      : () {
                          if (_isEditingNickname) {
                            _updateNickname();
                          } else {
                            setState(() => _isEditingNickname = true);
                          }
                        },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
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

  Widget _buildPersonalDataSection(BuildContext context) {
    return Column(
      children: [
        buildSectionHeader("Dữ liệu cá nhân"),
        buildGroupContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLabeledTextField(
                "Họ tên",
                _fullNameController,
                hint: "Chưa có Họ tên",
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DatePickerWidget(
                      selectedDate: _selectedDate,
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GenderPickerWidget(
                      selectedGender: _selectedGender,
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              buildLabeledTextField(
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

  Widget _buildLinkedAccountsSection() {
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
  void _showAvatarSourceDialog() {
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
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => _handleAvatarChange(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh mới'),
              onTap: () => _handleAvatarChange(ImageSource.camera),
            ),
            if (_currentAvatarUrl.startsWith('http') && !_isUploadingAvatar)
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
