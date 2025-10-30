import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // ✅ Mới
import 'dart:io'; // ✅ Mới
import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart'; // ✅ Mới

class AccountSettingScreen extends StatefulWidget {
  final String userId;

  const AccountSettingScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  State<AccountSettingScreen> createState() => _AccountSettingScreenState();
}

class _AccountSettingScreenState extends State<AccountSettingScreen> {
  // --- CONTROLLERS VÀ SERVICES ---
  final _nicknameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService(); // ✅ Khởi tạo Cloudinary

  // --- STATES ---
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = true;
  bool _isEditingNickname = false;

  String _currentAvatarUrl = "assets/images/default_avatar.png"; // ✅ URL ảnh đại diện hiện tại
  File? _newAvatarFile; // ✅ File ảnh cục bộ mới được chọn
  bool _isUploadingAvatar = false; // ✅ Theo dõi trạng thái upload

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

  // Hàm tiện ích
  void _showSnackBar(String message, {Color color = Colors.black87}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  Widget _buildGroupContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  // --- LOGIC XỬ LÝ DỮ LIỆU VỚI FIREBASE ---

  Future<void> _loadUserData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

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
          // ✅ LẤY AVATAR URL HIỆN TẠI
          _currentAvatarUrl = data['avatarUrl'] ?? "assets/images/default_avatar.png";
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNickname() async {
    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty) {
      _showSnackBar('Nickname không được để trống.', color: Colors.red);
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'name': newNickname});
    setState(() {
      _isEditingNickname = false;
    });
    _showSnackBar('Cập nhật Nickname thành công!', color: Colors.green);
  }

  // ✅ HÀM XỬ LÝ TẢI AVATAR LÊN CLOUDINARY VÀ CẬP NHẬT FIRESTORE
  Future<void> _handleAvatarChange(ImageSource source) async {
    Navigator.pop(context); // Đóng BottomSheet chọn nguồn
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _newAvatarFile = File(image.path); // Hiển thị ảnh cục bộ mới ngay lập tức
      _isUploadingAvatar = true;
    });

    try {
      final uploadedUrl = await _cloudinaryService.uploadImageToCloudinary(_newAvatarFile!);

      if (uploadedUrl != null) {
        // ✅ BƯỚC 2: CẬP NHẬT avatarUrl MỚI VÀO FIRESTORE
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
          'avatarUrl': uploadedUrl,
        });

        // Cập nhật state cục bộ để hiển thị ảnh mới và URL mới
        setState(() {
          _currentAvatarUrl = uploadedUrl;
          _newAvatarFile = null;
        });
        _showSnackBar('Cập nhật ảnh đại diện thành công!', color: Colors.green);
      } else {
        _showSnackBar('Tải ảnh lên thất bại. Vui lòng thử lại.', color: Colors.red);
      }
    } catch (e) {
      _showSnackBar('Lỗi hệ thống khi upload: $e', color: Colors.red);
      print("Lỗi upload avatar: $e");
    } finally {
      setState(() {
        _isUploadingAvatar = false;
        if (_newAvatarFile != null) _newAvatarFile = null; // Reset nếu upload thất bại
      });
    }
  }

  // ✅ BOTTOM SHEET CHỌN NGUỒN ẢNH
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
                title: const Text('Xóa ảnh đại diện', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  // ✅ HÀM XÓA AVATAR
  Future<void> _deleteAvatar() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'avatarUrl': FieldValue.delete(), // Xóa trường avatarUrl
      });
      setState(() {
        _currentAvatarUrl = "assets/images/default_avatar.png";
      });
      _showSnackBar('Đã xóa ảnh đại diện.', color: Colors.green);
    } catch (e) {
      _showSnackBar('Không thể xóa ảnh: $e', color: Colors.red);
    }
  }


  // Hàm cập nhật các thông tin còn lại
  Future<void> _updateGeneralUserData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'fullName': _fullNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'birthDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'gender': _selectedGender ?? '',
      });

      Navigator.of(context).pop(); // Tắt loading
      _showSnackBar('Cập nhật thông tin thành công!', color: Colors.green);

    } catch (e) {
      Navigator.of(context).pop(); // Tắt loading
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _deletePhoneNumber() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa số điện thoại này không?'),
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
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({'phoneNumber': FieldValue.delete()}); // Dùng FieldValue.delete

        setState(() {
          _phoneController.clear();
        });

        _showSnackBar('Đã xóa số điện thoại.', color: Colors.green);
      } catch (e) {
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
                _buildAvatarSection(),
                const SizedBox(height: 24),
                _buildPersonalDataSection(context),
                const SizedBox(height: 24),
                _buildEmailSection(),
                const SizedBox(height: 24),
                _buildPhoneSection(),
                const SizedBox(height: 24),
                _buildLinkedAccountsSection(),
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
              onPressed: _updateGeneralUserData,
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

  // ✅ THAY THẾ: WIDGET XỬ LÝ AVATAR MỚI
  Widget _buildAvatarSection() {
    ImageProvider _getAvatarProvider() {
      // 1. Nếu có ảnh cục bộ mới (chưa upload)
      if (_newAvatarFile != null) {
        return FileImage(_newAvatarFile!);
      }
      // 2. Nếu có URL ảnh mạng (đã upload)
      if (_currentAvatarUrl.startsWith('http')) {
        return NetworkImage(_currentAvatarUrl);
      }
      // 3. Ảnh mặc định
      return const AssetImage("assets/images/logo.png"); // Dùng logo làm mặc định
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _isUploadingAvatar ? null : _showAvatarSourceDialog, // Mở dialog chọn nguồn ảnh
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ảnh đại diện
              CircleAvatar(
                radius: 50,
                backgroundImage: _getAvatarProvider(),
                backgroundColor: Colors.grey.shade200,
                child: _isUploadingAvatar
                    ? Center(
                  child: CircularProgressIndicator(
                      color: Colors.blue.shade700
                  ),
                )
                    : null,
              ),
              // Icon camera/chỉnh sửa
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
                    child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // --- NICKNAME VÀ BIO ---
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
                  onPressed: _isUploadingAvatar ? null : () {
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
        _buildSectionHeader("Dữ liệu cá nhân", "", () {}),
        _buildGroupContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabeledTextField(
                "Họ tên",
                _fullNameController,
                hint: "Chưa có Họ tên",
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDatePicker(context)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildGenderPicker()),
                ],
              ),
              const SizedBox(height: 16),
              _buildLabeledTextField(
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

  Widget _buildEmailSection() {
    return Column(
      children: [
        _buildSectionHeader("Email", "", () {}),
        _buildGroupContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Email được sử dụng để đăng nhập và nhận thông báo.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection() {
    bool hasPhone = _phoneController.text.isNotEmpty;
    return Column(
      children: [
        _buildSectionHeader("Số di động", "", () {}),
        _buildGroupContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Số điện thoại để xác thực và nhận thông báo.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),

              Stack(
                alignment:
                Alignment.centerRight,
                children: [
                  TextFormField(
                    controller: _phoneController,
                    enabled: !hasPhone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Chưa có Số di động",
                      filled: true,
                      fillColor: hasPhone ? Colors.grey.shade200 : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: hasPhone
                            ? BorderSide.none
                            : BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),

                  if (hasPhone)
                    IconButton(
                      onPressed: _deletePhoneNumber,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                ],
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
        _buildSectionHeader("Liên kết tài khoản", "", () {}),
        _buildGroupContainer(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
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

  Widget _buildSectionHeader(
      String title,
      String actionText,
      VoidCallback onActionTap,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (actionText.isNotEmpty)
            TextButton(onPressed: onActionTap, child: Text(actionText)),
        ],
      ),
    );
  }

  Widget _buildLabeledTextField(
      String label,
      TextEditingController controller, {
        String hint = "",
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(label, style: const TextStyle(color: Colors.grey)),
        if (label.isNotEmpty) const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ngày sinh", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? "Chưa đặt"
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Giới tính", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          hint: const Text("Chưa đặt"),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          items: ["Nam", "Nữ", "Khác"]
              .map(
                (label) => DropdownMenuItem(value: label, child: Text(label)),
          )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
        ),
      ],
    );
  }
}
