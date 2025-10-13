import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thêm gói intl để định dạng ngày tháng

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({Key? key}) : super(key: key);

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final _nameController = TextEditingController(text: "Mydei Nguyễn");
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;

  // Hàm chọn ngày sinh
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

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Sử dụng AppBar tùy chỉnh để có nền màu cam
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200))
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Phần Avatar và Bio ---
            _buildAvatarSection(),
            const SizedBox(height: 24),

            // --- Phần Dữ liệu cá nhân ---
            _buildPersonalDataSection(context),
            const SizedBox(height: 24),

            // --- Phần Email ---
            _buildEmailSection(),
            const SizedBox(height: 24),

            // --- Phần Số di động ---
            _buildPhoneSection(),
            const SizedBox(height: 24),

            // --- Phần Liên kết tài khoản ---
            _buildLinkedAccountsSection(),
          ],
        ),
      ),
    );
  }

  // --- CÁC WIDGET CON ---

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/images/logo.png"), // Thay bằng avatarPath
            ),
            Container(
              decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "@mydei_nguyen",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.edit, size: 18, color: Colors.grey[600]),
              onPressed: () {},
            )
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
        _buildSectionHeader("Dữ liệu cá nhân", "Chỉnh sửa", () {}),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabeledTextField("Họ tên", _nameController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGenderPicker(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLabeledTextField("Thành phố cư trú", _cityController, hint: "Chưa đặt"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSection() {
    return Column(
      children: [
        _buildSectionHeader("Email", "Thêm", () {}),
        const Text(
          "Email được sử dụng để đăng nhập và nhận thông báo.",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _buildLabeledTextField("", TextEditingController(), hint: "Chưa có Email"),
      ],
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      children: [
        _buildSectionHeader("Số di động", "Thêm", () {}),
        const Text(
          "Thêm tối đa 3 số điện thoại để đăng nhập và nhận thông báo.",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12)
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "**********35204",
                  style: TextStyle(fontSize: 16, letterSpacing: 1.5),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text("Xóa", style: TextStyle(color: Colors.red)),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildLinkedAccountsSection() {
    return Column(
      children: [
        _buildSectionHeader("Liên kết tài khoản", "", () {}),
        // Thêm các nút liên kết mạng xã hội ở đây
      ],
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildSectionHeader(
      String title, String actionText, VoidCallback onActionTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (actionText.isNotEmpty)
            TextButton(
              onPressed: onActionTap,
              child: Text(actionText),
            ),
        ],
      ),
    );
  }

  Widget _buildLabeledTextField(String label, TextEditingController controller, {String hint = ""}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(label, style: const TextStyle(color: Colors.grey)),
        if (label.isNotEmpty)
          const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400)
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400)
            ),
          ),
          items: ["Nam", "Nữ", "Khác"]
              .map((label) => DropdownMenuItem(
            value: label,
            child: Text(label),
          ))
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