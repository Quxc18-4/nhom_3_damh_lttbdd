import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nhom_3_damh_lttbdd/screens/loginScreen.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class AdminDashBoardRequestView extends StatefulWidget {
  final String userId;
  const AdminDashBoardRequestView({Key? key, required this.userId})
    : super(key: key);

  @override
  State<AdminDashBoardRequestView> createState() =>
      _AdminDashBoardRequestViewState();
}

class _AdminDashBoardRequestViewState extends State<AdminDashBoardRequestView> {
  // Khai báo Firebase Instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Biến trạng thái
  String _selectedTab = 'pending'; // 'pending', 'banners'
  File? _selectedImageFile; // File ảnh tạm thời từ Camera/Gallery
  String? _manualImageUrl; // URL nhập thủ công

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
      // Nút Floating Action Button chỉ hiện khi ở tab Banner
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

  // --- WIDGETS CHUNG ---

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
          setState(() {
            _selectedTab = status;
          });
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
      return _buildPendingPlacesList();
    } else {
      return _buildBannersList();
    }
  }

  // --- HÀM XỬ LÝ ẢNH & LƯU TRỮ ---

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        // Cập nhật trạng thái sau khi chọn ảnh
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _manualImageUrl = null;
        });
        if (mounted) Navigator.of(context).pop(); // Đóng Bottom Sheet
      }
    } catch (e) {
      _showSnackBar('Lỗi khi chọn ảnh: $e', isError: true);
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    final String fileName =
        'banners/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
    final storageRef = _storage.ref().child(fileName);
    final uploadTask = storageRef.putFile(imageFile);

    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  // --- CHỨC NĂNG DUYỆT PLACE (TAB 1) ---

  Widget _buildPendingPlacesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('placeSubmissions')
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Không có địa điểm nào chờ duyệt.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        final submissions = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final submission = submissions[index];
            return _buildPlaceSubmissionCard(submission);
          },
        );
      },
    );
  }

  Widget _buildPlaceSubmissionCard(DocumentSnapshot submission) {
    final data = submission.data() as Map<String, dynamic>? ?? {};
    final placeData = data['placeData'] as Map<String, dynamic>? ?? {};

    final location = placeData['location'] as Map<String, dynamic>? ?? {};
    final name = placeData['name'] ?? 'Chưa có tên';
    final fullAddress = location['fullAddress'] ?? 'Chưa có địa chỉ';
    final description = placeData['description'] ?? '';
    final status = data['status'] ?? 'pending';
    final createdDate = (data['submittedAt'] as Timestamp?)?.toDate();

    String? imageUrl;
    final images = placeData['images'];
    if (images is List && images.isNotEmpty) {
      imageUrl = images[0] as String?;
    } else if (images is Map && images.isNotEmpty) {
      imageUrl = images.values.first as String?;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 60),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        fullAddress,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),

                if (createdDate != null)
                  Text(
                    'Gửi lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(createdDate)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),

                if (status == 'pending') ...[
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () => _rejectPlace(submission.id),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Duyệt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _approvePlace(submission),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePlace(DocumentSnapshot submission) async {
    final String submissionId = submission.id;
    final Map<String, dynamic> data = submission.data() as Map<String, dynamic>;
    final Map<String, dynamic>? placeData =
        data['placeData'] as Map<String, dynamic>?;

    if (placeData == null) {
      _showSnackBar('Lỗi: Dữ liệu địa điểm bị thiếu.', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Duyệt địa điểm',
      'Bạn có chắc chắn muốn duyệt địa điểm "${placeData['name']}"?',
    );

    if (!confirmed) return;

    _showLoadingDialog();

    try {
      WriteBatch batch = _firestore.batch();

      // 1. Cập nhật status trong placeSubmissions
      final submissionRef = _firestore
          .collection('placeSubmissions')
          .doc(submissionId);
      batch.update(submissionRef, {'status': 'approved'});

      // 2. Tạo document mới trong places
      final Map<String, dynamic> finalPlaceData = Map<String, dynamic>.from(
        placeData,
      );
      finalPlaceData['approvedBy'] = widget.userId;
      finalPlaceData['createdAt'] = FieldValue.serverTimestamp();
      finalPlaceData['ratingAverage'] = 0.0; // Khởi tạo trường mới
      finalPlaceData['reviewCount'] = 0; // Khởi tạo trường mới

      final newPlaceRef = _firestore.collection('places').doc();
      batch.set(newPlaceRef, finalPlaceData);

      // 3. Cập nhật count cho category
      final categoriesData = placeData['categories'];
      List<String> categoryList = [];

      if (categoriesData is String && categoriesData.isNotEmpty) {
        categoryList = [categoriesData];
      } else if (categoriesData is List) {
        categoryList = categoriesData.map((e) => e.toString()).toList();
      }

      for (final categoryName in categoryList) {
        if (categoryName.isNotEmpty) {
          final categoryQuery = await _firestore
              .collection('categories')
              .where('name', isEqualTo: categoryName)
              .limit(1)
              .get();

          if (categoryQuery.docs.isNotEmpty) {
            final categoryRef = categoryQuery.docs.first.reference;
            batch.update(categoryRef, {'count': FieldValue.increment(1)});
          }
        }
      }

      await batch.commit();

      Navigator.of(context).pop();
      _showSnackBar('Đã duyệt địa điểm thành công!');
    } catch (e) {
      Navigator.of(context).pop();
      print('Lỗi khi duyệt place $submissionId: $e');
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
      final submissionRef = _firestore
          .collection('placeSubmissions')
          .doc(submissionId);
      await submissionRef.update({
        'status': 'rejected',
        'rejectedBy': widget.userId,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
      _showSnackBar('Đã từ chối địa điểm.');
    } catch (e) {
      Navigator.of(context).pop();
      print('Lỗi khi từ chối place $submissionId: $e');
      _showSnackBar('Lỗi khi từ chối địa điểm: $e', isError: true);
    }
  }

  // --- CHỨC NĂNG QUẢN LÝ BANNER (TAB 2) ---

  Widget _buildBannersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('banners')
          .orderBy('startDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có banner nào.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final banners = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: banners.length,
          itemBuilder: (context, index) {
            final banner = banners[index];
            return _buildBannerCard(banner);
          },
        );
      },
    );
  }

  Widget _buildBannerCard(DocumentSnapshot banner) {
    final data = banner.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Không có tiêu đề';
    final content = data['content'] ?? ''; // LẤY TRƯỜNG CONTENT
    final imageUrl = data['imageUrl'] ?? 'N/A';
    final startDate = (data['startDate'] as Timestamp?)?.toDate();
    final endDate = (data['endDate'] as Timestamp?)?.toDate();

    Color statusColor = Colors.grey;
    String statusText = 'Unknown';
    if (startDate != null && endDate != null) {
      final now = DateTime.now();
      if (now.isBefore(startDate)) {
        statusColor = Colors.blue;
        statusText = 'Sắp diễn ra';
      } else if (now.isAfter(endDate)) {
        statusColor = Colors.red;
        statusText = 'Hết hạn';
      } else {
        statusColor = Colors.green;
        statusText = 'Đang hiển thị';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Hiển thị CONTENT
            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  content,
                  style: TextStyle(color: Colors.grey[800], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            if (imageUrl != 'N/A' && imageUrl.startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text(
                          'Không tải được ảnh. URL không hợp lệ.',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),

            Text(
              'URL Ảnh: $imageUrl',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (startDate != null)
              Text(
                'Bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(startDate)}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            const SizedBox(height: 4),
            if (endDate != null)
              Text(
                'Kết thúc: ${DateFormat('dd/MM/yyyy HH:mm').format(endDate)}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),

            const Divider(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Xóa Banner'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () => _deleteBanner(banner.id, title),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Hàm hiển thị Bottom Sheet chọn nguồn ảnh hoặc nhập URL
  Future<void> _showImageSourceOptions() {
    // Sửa lỗi 'use_of_void_result' bằng cách khai báo rõ ràng Future<void>
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ Thư viện (Gallery)'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh (Camera)'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Nhập URL thủ công'),
              onTap: () {
                Navigator.of(context).pop();
                _showManualUrlDialog();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showManualUrlDialog() async {
    final urlController = TextEditingController(text: _manualImageUrl);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nhập URL Ảnh'),
            content: TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL Ảnh Banner (Cloudinary/Link)',
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
      // Cập nhật lại trạng thái bên ngoài dialog
      setState(() {
        _manualImageUrl = urlController.text;
        _selectedImageFile = null;
      });
    }
  }

  Future<void> _showCreateBannerDialog() async {
    // Reset trạng thái ảnh khi mở Dialog mới
    setState(() {
      _selectedImageFile = null;
      _manualImageUrl = null;
    });

    final titleController = TextEditingController();
    final contentController =
        TextEditingController(); // KHAI BÁO CONTENT CONTROLLER
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

                    // TRƯỜNG CONTENT MỚI
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung Banner (Content)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Nút chọn ảnh
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: Text(
                        _selectedImageFile != null
                            ? 'Đã chọn ảnh (${_selectedImageFile!.path.split('/').last})'
                            : (_manualImageUrl != null
                                  ? 'URL đã nhập'
                                  : 'Chọn nguồn ảnh'),
                      ),
                      onPressed: () async {
                        // SỬA: Thêm async/await để giải quyết lỗi cũ
                        await _showImageSourceOptions();
                        setStateInDialog(() {});
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

                    // Ngày kết thúc
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
                              setStateInDialog(() {
                                durationDays = value;
                              });
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

  // SỬA: Thêm tham số content vào _createBanner
  Future<void> _createBanner(
    String title,
    String content,
    int durationDays,
  ) async {
    _showLoadingDialog();

    String finalImageUrl;

    try {
      if (_selectedImageFile != null) {
        finalImageUrl = await _uploadImage(_selectedImageFile!);
      } else if (_manualImageUrl != null) {
        finalImageUrl = _manualImageUrl!;
      } else {
        Navigator.of(context).pop();
        _showSnackBar('Lỗi: Không tìm thấy URL ảnh.', isError: true);
        return;
      }

      final now = DateTime.now();
      final startDate = now;
      final endDate = now.add(Duration(days: durationDays));

      await _firestore.collection('banners').add({
        'title': title,
        'content': content, // LƯU TRƯỜNG CONTENT MỚI
        'imageUrl': finalImageUrl,
        'startDate': startDate,
        'endDate': endDate,
        'createdBy': widget.userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
      _showSnackBar('Đã tạo Banner thành công!');
    } catch (e) {
      Navigator.of(context).pop();
      print('Lỗi khi tạo banner: $e');
      _showSnackBar('Lỗi khi tạo Banner: $e', isError: true);
    }

    // Đảm bảo reset trạng thái sau khi tạo xong
    setState(() {
      _selectedImageFile = null;
      _manualImageUrl = null;
    });
  }

  Future<void> _deleteBanner(String bannerId, String title) async {
    final confirmed = await _showConfirmDialog(
      'Xóa Banner',
      'Bạn có chắc chắn muốn xóa banner "${title}"?',
    );

    if (!confirmed) return;

    _showLoadingDialog();

    try {
      await _firestore.collection('banners').doc(bannerId).delete();

      Navigator.of(context).pop();
      _showSnackBar('Đã xóa Banner thành công!');
    } catch (e) {
      Navigator.of(context).pop();
      print('Lỗi khi xóa banner $bannerId: $e');
      _showSnackBar('Lỗi khi xóa Banner: $e', isError: true);
    }
  }

  // --- HÀM HỖ TRỢ CHUNG ---

  Future<void> _showLogoutDialog() async {
    final confirmed = await _showConfirmDialog(
      'Đăng xuất',
      'Bạn có chắc chắn muốn đăng xuất?',
    );

    if (confirmed) {
      _showLoadingDialog();
      try {
        await _auth.signOut();

        // Đóng dialog loading
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Điều hướng đến LoginScreen và xóa tất cả các route trước đó
        if (mounted) {
          // Thay thế pushReplacementNamed bằng pushReplacement với MaterialPageRoute
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              // THAY THẾ bằng tên class LoginScreen thực tế của bạn
              builder: (context) => LoginScreen(),
            ),
          );

          // Hoặc sử dụng pushAndRemoveUntil để đảm bảo không còn route nào
          /*
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()), 
            (Route<dynamic> route) => false,
          );
          */
        }
      } catch (e) {
        // Đóng dialog loading khi có lỗi
        if (mounted) {
          Navigator.of(context).pop();
        }
        _showSnackBar('Lỗi khi đăng xuất: $e', isError: true);
      }
    }
  }

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
}
