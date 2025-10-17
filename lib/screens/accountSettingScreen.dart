import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSettingScreen extends StatefulWidget {
  final String userId;

  const AccountSettingScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<AccountSettingScreen> createState() => _AccountSettingScreenState();
}

class _AccountSettingScreenState extends State<AccountSettingScreen> {
  // Thêm controller cho fullName
  final _nicknameController = TextEditingController();
  final _fullNameController = TextEditingController(); // (MỚI)
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = true;
  bool _isEditingNickname = false; // (MỚI) State để kiểm soát việc sửa nickname

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

  Widget _buildGroupContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Nền trắng
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300), // Viền xám
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
          _fullNameController.text =
              data['fullName'] ?? ''; // (MỚI) Lấy fullName
          _emailController.text = data['email'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _cityController.text = data['city'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _selectedGender = data['gender']?.isEmpty ? null : data['gender'];
          if (data['birthDate'] != null) {
            _selectedDate = (data['birthDate'] as Timestamp).toDate();
          }
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // (MỚI) Hàm chỉ để cập nhật nickname
  Future<void> _updateNickname() async {
    // (Sau này bạn có thể thêm logic check trùng nickname ở đây)
    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nickname không được để trống.')),
      );
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'name': newNickname});
    setState(() {
      _isEditingNickname = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật Nickname thành công!')),
    );
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
            'birthDate': _selectedDate,
            'gender': _selectedGender ?? '',
          });

      // --- THAY ĐỔI CHÍNH Ở ĐÂY ---
      // Yêu cầu Flutter build lại giao diện sau khi đã lưu
      setState(() {
        // Lệnh setState rỗng này đủ để yêu cầu Flutter
        // cập nhật lại UI dựa trên trạng thái mới của các controller.
      });

      Navigator.of(context).pop(); // Tắt loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thành công!')),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Tắt loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cập nhật thất bại: $e')));
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
    // Hiển thị dialog xác nhận
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa số điện thoại này không?',
          ),
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

    // Nếu người dùng xác nhận xóa
    if (confirmDelete == true) {
      try {
        // Cập nhật trường phoneNumber thành rỗng trên Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({'phoneNumber': ''});

        // Cập nhật lại giao diện
        setState(() {
          _phoneController.clear();
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa số điện thoại.')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
      }
    }
  }

  // --- GIAO DIỆN ---
  // Thay thế toàn bộ hàm build() trong file accountSettingScreen.dart

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

      // --- THAY ĐỔI CHÍNH: BỎ bottomNavigationBar VÀ DÙNG STACK ---
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              // BƯỚC 1: BỌC TOÀN BỘ BODY TRONG MỘT STACK
              children: [
                // BƯỚC 2: PHẦN NỘI DUNG CHÍNH (NẰM DƯỚI CÙNG)
                SingleChildScrollView(
                  // NOTE 1: Tăng padding dưới để item cuối không bị che bởi nút
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

                // BƯỚC 3: LỚP NỀN MỜ (NẰM TRÊN NỘI DUNG, DƯỚI NÚT BẤM)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120, // Chiều cao của vùng mờ
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[50]!.withOpacity(
                            0.0,
                          ), // Bắt đầu trong suốt
                          Colors.grey[50]!, // Kết thúc với màu nền
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // BƯỚC 4: NÚT BẤM (NẰM TRÊN CÙNG)
                Positioned(
                  left: 16,
                  right: 16,
                  // NOTE 2: Vị trí của nút so với cạnh dưới
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

  // --- CÁC WIDGET CON ĐỂ XÂY DỰNG GIAO DIỆN ---

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/images/logo.png"),
            ),
            Container(
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
          ],
        ),
        const SizedBox(height: 8),
        // THAY ĐỔI: Sử dụng Row để căn giữa nickname và nút sửa một cách linh hoạt
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Spacer để đẩy nội dung vào giữa
            const Spacer(flex: 2),
            // Nickname sẽ co giãn ở giữa
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
            // Nút sửa nằm ở bên phải, chiếm một phần không gian
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    _isEditingNickname ? Icons.check_circle : Icons.edit,
                    color: Colors.blue,
                  ),
                  onPressed: () {
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
                    borderSide: BorderSide.none, // Bỏ viền trong
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // (THAY ĐỔI) Logic hiển thị và xóa số điện thoại
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

              // --- THAY ĐỔI CHÍNH: SỬ DỤNG STACK ĐỂ ĐẶT NÚT LÊN TRÊN ---
              Stack(
                alignment:
                    Alignment.centerRight, // Căn chỉnh icon về phía bên phải
                children: [
                  // Lớp dưới: Khung nhập liệu chiếm toàn bộ chiều rộng
                  TextFormField(
                    controller: _phoneController,
                    enabled: !hasPhone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Chưa có Số di động",
                      filled: true,
                      fillColor: hasPhone ? Colors.grey.shade200 : Colors.white,
                      // Không còn suffixIcon ở đây nữa
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

                  // Lớp trên: Icon thùng rác, chỉ hiển thị khi có SĐT
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
          // THAY ĐỔI: Bọc nội dung trong SizedBox để có chiều cao tối thiểu
          child: SizedBox(
            width: double.infinity, // Đảm bảo SizedBox chiếm hết chiều rộng
            height: 50, // Đặt chiều cao mong muốn
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Căn giữa theo chiều dọc
              children: [
                const Text(
                  "Tính năng đang được phát triển.",
                  style: TextStyle(color: Colors.grey),
                ),
                // (Sau này bạn có thể thêm các nút liên kết ở đây)
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
            ), // Tăng padding
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
            ), // Điều chỉnh padding
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
