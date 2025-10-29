import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Giữ lại cho mục đích tham khảo, nhưng không dùng
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// ⚡️ IMPORT CLOUDINARY SERVICE
import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart';


// =======================================================
// DỮ LIỆU ẢO (Dùng thay cho Place Model/API)
// =======================================================
class Place {
  final String id;
  final String name;
  final String address;
  Place({required this.id, required this.name, required this.address});
}

final List<Place> samplePlaces = [
  Place(id: 'dl001', name: 'Đà Lạt', address: 'Lâm Đồng, Việt Nam'),
  Place(id: 'ha002', name: 'Hội An', address: 'Quảng Nam, Việt Nam'),
  Place(id: 'sp003', name: 'Sapa', address: 'Lào Cai, Việt Nam'),
  Place(id: 'pq004', name: 'Phú Quốc', address: 'Kiên Giang, Việt Nam'),
];
// =======================================================

// =======================================================
// MÀU SẮC TỪ THIẾT KẾ
// =======================================================
const Color kAppbarColor = Color(0xFFE4C99E);
const Color kBorderColor = Color(0xFFE4C99E);
const Color kFillColor = Color(0xFFFFF9F2);
// =======================================================


class CheckinScreen extends StatefulWidget {
  final String currentUserId;
  const CheckinScreen({super.key, required this.currentUserId});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  // ⚡️ KHỞI TẠO CLOUDINARY SERVICE
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<String> _imagePaths = [];
  Place? _selectedPlace;
  List<String> _hashtags = ['#travelmap', '#checkin', '#dalatdream'];
  final List<String> _suggestedTags = ['#review', '#foodie', '#amazingvietnam', '#phuquoc'];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  // Hàm tiện ích
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }


  // =======================================================
  // HÀM XỬ LÝ ẢNH CỤC BỘ (THƯ VIỆN/CHỤP) - Giữ nguyên logic chọn ảnh
  // =======================================================

  Future<void> _pickImage(ImageSource source) async {
    if (_imagePaths.length >= 10) {
      _showSnackBar('Chỉ được chọn tối đa 10 ảnh/bài viết.');
      Navigator.pop(context);
      return;
    }

    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path); // LƯU ĐƯỜNG DẪN CỤC BỘ
      });
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Đóng dialog chọn nguồn
    }
  }

  void _showImageSourceDialog() {
    // Logic của BottomSheet giữ nguyên
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
              OutlinedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: const Text('Chọn từ thư viện', style: TextStyle(color: Colors.black87)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                child: const Text('Chụp ảnh mới', style: TextStyle(color: Colors.black87)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context); // Đóng hộp thoại chọn nguồn
                  _showAddImageUrlDialog(); // Mở hộp thoại nhập URL
                },
                child: const Text('Thêm từ URL', style: TextStyle(color: Colors.black87)),
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

  void _showAddImageUrlDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập đường dẫn ảnh (URL)'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final String url = urlController.text.trim();
              if ((url.startsWith('http') || url.startsWith('https')) && _imagePaths.length < 10) {
                setState(() {
                  _imagePaths.add(url);
                });
                Navigator.pop(context);
              } else {
                _showSnackBar('URL không hợp lệ hoặc đã đạt giới hạn ảnh.');
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // HÀM TẢI ẢNH LÊN (THAY THẾ FIREBASE STORAGE BẰNG CLOUDINARY)
  // =======================================================

  Future<String?> _uploadLocalFile(String path) async {
    // Nếu là URL mạng, không cần upload
    if (path.startsWith('http') || path.startsWith('https')) {
      return path;
    }

    File file = File(path);
    // ⚡️ GỌI DỊCH VỤ CLOUDINARY
    try {
      String? uploadedUrl = await _cloudinaryService.uploadImageToCloudinary(file);
      return uploadedUrl;
    } catch (e) {
      print("Lỗi tải ảnh lên Cloudinary: $e");
      return null;
    }
  }

  // ===================================================================
  // HÀM _submitReview (Đã thêm lại reviewId)
  // ===================================================================
  Future<void> _submitReview() async {
    if (_titleController.text.isEmpty || _commentController.text.isEmpty || _selectedPlace == null) {
      _showSnackBar('Vui lòng nhập Tiêu đề, Nội dung và Chọn địa điểm.');
      return;
    }
    if (_imagePaths.isEmpty) {
      _showSnackBar('Vui lòng thêm ít nhất một ảnh.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final reviewsCollection = FirebaseFirestore.instance.collection('reviews');
      final newDoc = reviewsCollection.doc();
      final reviewId = newDoc.id; // ✅ ĐÃ BỎ COMMENT VÀ SỬ DỤNG REVIEW ID

      // 1. Tải ảnh (chỉ tải ảnh cục bộ, giữ nguyên URL mạng)
      List<String> finalImageUrls = [];
      for (int i = 0; i < _imagePaths.length; i++) {
        // Chỉ truyền path. Hàm _uploadLocalFile đã được sửa để chỉ dùng path.
        final url = await _uploadLocalFile(_imagePaths[i]);
        if (url != null) {
          finalImageUrls.add(url);
        }
      }

      // ⚡️ CHỈ THẤT BẠI NẾU KHÔNG CÓ URL NÀO HỢP LỆ (Cả local upload và network URL)
      if (finalImageUrls.isEmpty) {
        _showSnackBar('Không có ảnh hợp lệ nào được tải lên hoặc tìm thấy.');
        if (mounted) {
          setState(() { _isSaving = false; });
        }
        return;
      }

      // 2. Chuẩn bị dữ liệu Firestore
      final reviewData = {
        'userId': widget.currentUserId,
        'placeId': _selectedPlace!.id,
        'rating': 5,
        'comment': _commentController.text.trim(),
        'title': _titleController.text.trim(),
        'imageUrls': finalImageUrls,
        'hashtags': _hashtags,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'commentCount': 0,
      };

      await newDoc.set(reviewData);

      _showSnackBar('Đăng bài check-in thành công!');
      Navigator.pop(context);

    } catch (e) {
      _showSnackBar('Lỗi khi đăng bài: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =======================================================
  // CÁC WIDGET PHỤ (Giữ nguyên)
  // =======================================================

  Widget _buildImageItem(String path, VoidCallback onRemove) {
    bool isNetwork = path.startsWith('http') || path.startsWith('https');
    ImageProvider imageProvider;

    if (isNetwork) {
      imageProvider = NetworkImage(path);
    } else {
      imageProvider = FileImage(File(path));
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image(
              image: imageProvider,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                  width: 100, height: 100, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // --- CÁC WIDGET UI KHÁC GIỮ NGUYÊN (build, buildImageSection, buildJourneyContent, buildPlaceSection, buildHashtagSection, buildPrivacySection) ---
  // ... (Phần còn lại của _CheckinScreenState và _PlacePickerModal)

  // Hàm xử lý địa điểm
  void _showPlacePickerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _PlacePickerModal(
          onPlaceSelected: (place) {
            setState(() {
              _selectedPlace = place;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // Hàm xử lý hashtag
  void _addHashtag() {
    final tag = _hashtagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_hashtags.contains(tag) && _hashtags.length < 5) {
      setState(() {
        _hashtags.add(tag.startsWith('#') ? tag : '#$tag');
        _hashtagController.clear();
      });
    } else if (_hashtags.length >= 5) {
      _showSnackBar('Đã đạt tối đa 5 Hashtag.');
    }
  }

  void _removeHashtag(String tag) {
    setState(() {
      _hashtags.remove(tag);
    });
  }

  void _addSuggestedTag(String tag) {
    if (!_hashtags.contains(tag) && _hashtags.length < 5) {
      setState(() {
        _hashtags.add(tag);
      });
    } else if (_hashtags.length >= 5) {
      _showSnackBar('Đã đạt tối đa 5 Hashtag.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
            'Checkin',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: kAppbarColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildJourneyContent(),
              const SizedBox(height: 24),
              _buildPlaceSection(),
              const SizedBox(height: 24),
              _buildHashtagSection(),
              const SizedBox(height: 24),
              _buildPrivacySection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAppbarColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  )
                      : const Text(
                      'Đăng bài',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ảnh nổi bật', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        if (_imagePaths.isEmpty)
          InkWell(
            onTap: _showImageSourceDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              decoration: BoxDecoration(
                color: kFillColor,
                border: Border.all(color: kBorderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: Colors.black54, size: 28),
                  const SizedBox(height: 8),
                  const Text(
                    'Thêm ảnh/bài viết (tối đa 10)',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(${_imagePaths.length}/10 ảnh/bài viết)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: Row(
              children: [
                if (_imagePaths.length < 10) // Chỉ hiển thị nút '+' nếu chưa đủ 10 ảnh
                  InkWell(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8.0), // Thêm margin
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, color: Colors.grey),
                          Text(
                            'Thêm ảnh/bài viết',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
                          ),
                          Text(
                            '(${_imagePaths.length}/10)',
                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, index) {
                      final path = _imagePaths[index];
                      return _buildImageItem(
                        path,
                            () {
                          setState(() {
                            _imagePaths.removeAt(index);
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildJourneyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Câu chuyện hành trình', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kFillColor,
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Tiêu đề chuyến đi',
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kFillColor,
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Chia sẻ về hành trình của bạn...',
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vị trí du lịch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: kFillColor,
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.orange),
              const SizedBox(width: 8),

              if (_selectedPlace == null)
                Expanded(
                  child: InkWell(
                    onTap: _showPlacePickerDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Text(
                          'Thêm địa điểm',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500, fontSize: 15)
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _selectedPlace!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                      ),
                      Text(
                          _selectedPlace!.address,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)
                      ),
                    ],
                  ),
                ),

              if (_selectedPlace != null)
                GestureDetector(
                  onTap: () {
                    setState(() { _selectedPlace = null; });
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.close, size: 20, color: Colors.black54),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hashtag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _hashtags.map((tag) {
            return Chip(
              label: Text(tag, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              backgroundColor: Colors.grey[200],
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _removeHashtag(tag),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _suggestedTags.map((tag) {
            bool isSelected = _hashtags.contains(tag);
            return ActionChip(
              label: Text(tag, style: TextStyle(fontSize: 12, color: isSelected ? Colors.grey : Colors.blue[700])),
              backgroundColor: isSelected ? Colors.grey[300] : Colors.blue[50],
              onPressed: isSelected ? null : () => _addSuggestedTag(tag),
              tooltip: isSelected ? 'Đã chọn' : 'Thêm hashtag này',
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kFillColor,
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hashtagController,
                  decoration: InputDecoration(
                      hintText: _hashtags.length < 5 ? 'Thêm hashtag...' : 'Đã đủ 5 hashtag',
                      border: InputBorder.none,
                      counterText: '${_hashtags.length}/5 hashtag'
                  ),
                  enabled: _hashtags.length < 5,
                  onSubmitted: (_) => _addHashtag(),
                ),
              ),
              TextButton(
                onPressed: _hashtags.length < 5 ? _addHashtag : null,
                child: Text('Thêm', style: TextStyle(color: _hashtags.length < 5 ? Colors.orange : Colors.grey)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    String _privacySetting = 'Công khai';
    IconData _privacyIcon = Icons.lock_open;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quyền riêng tư', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            _showSnackBar('Chức năng chọn quyền riêng tư chưa được cài đặt.');
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: kFillColor,
              border: Border.all(color: kBorderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_privacyIcon, color: Colors.black54),
                    SizedBox(width: 12),
                    Text(
                        _privacySetting,
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87)
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
              ],
            ),
          ),
        )
      ],
    );
  }
}

// =======================================================
// WIDGET MODAL CHỌN ĐỊA ĐIỂM (PlacePickerModal)
// =======================================================

class _PlacePickerModal extends StatefulWidget {
  final Function(Place) onPlaceSelected;
  const _PlacePickerModal({required this.onPlaceSelected});

  @override
  State<_PlacePickerModal> createState() => _PlacePlacePickerModalState();
}

class _PlacePlacePickerModalState extends State<_PlacePickerModal> {
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final filteredPlaces = _searchText.isEmpty
        ? samplePlaces
        : samplePlaces.where((place) =>
    place.name.toLowerCase().contains(_searchText.toLowerCase()) ||
        place.address.toLowerCase().contains(_searchText.toLowerCase())
    ).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text('Chọn địa điểm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm địa điểm...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: kBorderColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _searchText.isNotEmpty ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  setState(() { _searchText = ''; });
                },
              ) : null,
            ),
          ),
          const SizedBox(height: 16),

          if (filteredPlaces.isEmpty && _searchText.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text('Không tìm thấy địa điểm phù hợp.'),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredPlaces.length,
                itemBuilder: (context, index) {
                  final place = filteredPlaces[index];
                  return ListTile(
                    leading: Icon(Icons.location_pin, color: Colors.grey[400]),
                    title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(place.address, style: TextStyle(color: Colors.grey[600])),
                    onTap: () => widget.onPlaceSelected(place),
                  );
                },
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.black87)),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!)
              ),
            ),
          ),
        ],
      ),
    );
  }
}
