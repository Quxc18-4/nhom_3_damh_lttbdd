import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  // =======================================================
  // HÀM XỬ LÝ ẢNH CỤC BỘ (THƯ VIỆN/CHỤP)
  // =======================================================

  Future<void> _pickImage(ImageSource source) async {
    if (_imagePaths.length >= 10) {
      _showSnackBar('Chỉ được chọn tối đa 10 ảnh/bài viết.');
      Navigator.pop(context); // Đóng dialog nếu đã đầy
      return;
    }

    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path); // LƯU ĐƯỜNG DẪN CỤC BỘ
      });
    }
    // Sửa lỗi tiềm ẩn: Chỉ pop nếu dialog còn mở
    if (Navigator.canPop(context)) {
       Navigator.pop(context); // Đóng dialog chọn nguồn
    }
  }

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
                  backgroundColor: Colors.grey[200], // Màu xám nhạt như thiết kế
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
                  _imagePaths.add(url); // LƯU URL MẠNG TRỰC TIẾP
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
  // HÀM XỬ LÝ ĐỊA ĐIỂM (Giữ nguyên)
  // =======================================================

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

  // =======================================================
  // HÀM XỬ LÝ HASHTAG (Giữ nguyên)
  // =======================================================

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
    if (!_hashtags.contains(tag) && _hashtags.length < 5) { // Thêm check giới hạn
      setState(() {
        _hashtags.add(tag);
      });
    } else if (_hashtags.length >= 5) {
      _showSnackBar('Đã đạt tối đa 5 Hashtag.');
    }
  }


  // =======================================================
  // HÀM LƯU DỮ LIỆU (FIREBASE)
  // =======================================================

  Future<String?> _uploadLocalFile(String path, String reviewId, String userId, int index) async {
    if (path.startsWith('http') || path.startsWith('https')) {
      return path; // Nếu là URL mạng, không cần upload
    }

    File file = File(path);
    String fileName = '$reviewId/photo_$index.jpg';
    Reference ref = FirebaseStorage.instance.ref().child('reviews/$userId/$fileName');

    try {
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Lỗi tải ảnh lên Storage: $e");
      return null;
    }
  }

  // ===================================================================
  // SỬA HÀM _submitReview (Đổi tên trường cho khớp)
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
      final reviewId = newDoc.id;

      // 1. Tải ảnh (chỉ tải ảnh cục bộ, giữ nguyên URL mạng)
      List<String> finalImageUrls = [];
      for (int i = 0; i < _imagePaths.length; i++) {
        final url = await _uploadLocalFile(_imagePaths[i], reviewId, widget.currentUserId, i);
        if (url != null) {
          finalImageUrls.add(url);
        }
      }

      if (finalImageUrls.isEmpty && _imagePaths.any((path) => !(path.startsWith('http') || path.startsWith('https')))) {
        // Chỉ báo lỗi nếu có ảnh cục bộ nhưng không tải lên được
        _showSnackBar('Không thể tải ảnh lên. Vui lòng thử lại.');
        // Đặt _isSaving về false để người dùng có thể thử lại
         if (mounted) {
           setState(() { _isSaving = false; });
         }
        return;
      }
      // Nếu chỉ có URL mạng thì finalImageUrls có thể rỗng, vẫn tiếp tục


      // SỬA CÁC TÊN TRƯỜNG CHO KHỚP VỚI exploreScreen
      final reviewData = {
        'authorId': widget.currentUserId, // SỬA 1: 'userId' -> 'authorId'
        'placeId': _selectedPlace!.id,
        'rating': 5, // Tạm thời hard-code
        'comment': _commentController.text.trim(),
        'title': _titleController.text.trim(),
        'imageUrls': finalImageUrls.isNotEmpty ? finalImageUrls : _imagePaths.where((path) => path.startsWith('http')).toList(), // Ưu tiên URL đã upload, nếu không có thì lấy URL mạng đã nhập
        'hashtags': _hashtags, // exploreScreen đã sửa để đọc 'hashtags'
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,     // SỬA 2: 'likesCount' -> 'likeCount'
        'commentCount': 0,  // SỬA 3: 'commentsCount' -> 'commentCount'
      };

      // Kiểm tra lại lần cuối trước khi ghi
      if ((reviewData['imageUrls'] as List).isEmpty) {
          _showSnackBar('Không có ảnh hợp lệ để đăng.');
          if (mounted) { setState(() { _isSaving = false; }); }
          return;
      }

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

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // =======================================================
  // WIDGET BUILDER (Giữ nguyên)
  // =======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Checkin',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: kAppbarColor, // Màu beige từ thiết kế
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [],
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
                  width: 100, height: 100, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))), // Ít gây khó chịu hơn màu đỏ
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
          Container(
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
            bool isSelected = _hashtags.contains(tag); // Kiểm tra tag đã được chọn chưa
            return ActionChip(
              label: Text(tag, style: TextStyle(fontSize: 12, color: isSelected ? Colors.grey : Colors.blue[700])),
              backgroundColor: isSelected ? Colors.grey[300] : Colors.blue[50],
              onPressed: isSelected ? null : () => _addSuggestedTag(tag), // Vô hiệu hóa nếu đã chọn
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
                    hintText: _hashtags.length < 5 ? 'Thêm hashtag...' : 'Đã đủ 5 hashtag', // Gợi ý khi đủ tag
                    border: InputBorder.none,
                    counterText: '${_hashtags.length}/5 hashtag'
                  ),
                   enabled: _hashtags.length < 5, // Vô hiệu hóa input khi đủ 5 tag
                   onSubmitted: (_) => _addHashtag(), // Thêm bằng nút Enter
                ),
              ),
              TextButton(
                onPressed: _hashtags.length < 5 ? _addHashtag : null, // Vô hiệu hóa nút Thêm khi đủ tag
                child: Text('Thêm', style: TextStyle(color: _hashtags.length < 5 ? Colors.orange : Colors.grey)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    // Tạm thời để Công khai, bạn có thể thêm logic chọn sau
    String _privacySetting = 'Công khai';
    IconData _privacyIcon = Icons.lock_open;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quyền riêng tư', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        InkWell( // Thêm InkWell để có thể bấm chọn sau này
          onTap: () {
             _showSnackBar('Chức năng chọn quyền riêng tư chưa được cài đặt.');
             // TODO: Thêm logic mở dialog chọn quyền riêng tư
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
    // Lọc dữ liệu trực tiếp trong build
    final filteredPlaces = _searchText.isEmpty
        ? samplePlaces // Hiển thị tất cả nếu không tìm kiếm
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
              suffixIcon: _searchText.isNotEmpty ? IconButton( // Thêm nút xóa text
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                     setState(() { _searchText = ''; });
                     // Có thể cần controller.clear() nếu bạn dùng TextEditingController
                  },
              ) : null,
            ),
             // Có thể thêm controller nếu cần xóa text từ nút suffixIcon
             // controller: _searchController,
          ),
          const SizedBox(height: 16),

          // Hiển thị thông báo nếu không có kết quả
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
                    leading: Icon(Icons.location_pin, color: Colors.grey[400]), // Thêm icon cho đẹp
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