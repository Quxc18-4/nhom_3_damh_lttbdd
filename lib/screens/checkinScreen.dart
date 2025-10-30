import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// ⚡️ IMPORT CLOUDINARY SERVICE
// !!! QUAN TRỌNG: Đảm bảo đường dẫn này đúng !!!
import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart'; // <<< Sửa đường dẫn nếu cần
// 🗺️ IMPORTS CHO MINI MAP
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Cần cho hàm tính khoảng cách (tùy chọn)

// =======================================================
// DỮ LIỆU ẢO (ĐÃ XÓA)
// =======================================================
// class Place { ... } // ĐÃ XÓA
// final List<Place> samplePlaces = [ ... ]; // ĐÃ XÓA
// class _PlacePickerModal extends ... // ĐÃ XÓA
// =======================================================

// =======================================================
// MÀU SẮC (Giữ nguyên)
// =======================================================
const Color kAppbarColor = Color(0xFFE4C99E);
const Color kBorderColor = Color(0xFFE4C99E);
const Color kFillColor = Color(0xFFFFF9F2);
// =======================================================

class CheckinScreen extends StatefulWidget {
  final String currentUserId;
  // === THÊM THAM SỐ initialPlaceId (TÙY CHỌN) ===
  final String? initialPlaceId;
  // ===========================================

  const CheckinScreen({
    super.key,
    required this.currentUserId,
    this.initialPlaceId, // Thêm vào constructor
  });

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  // Cloudinary Service & Controllers (Giữ nguyên)
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // === State mới cho Địa điểm ===
  DocumentSnapshot? _selectedPlaceDoc; // Lưu trữ DocumentSnapshot đã chọn
  bool _isLoadingPlace = false; // Trạng thái tải chi tiết địa điểm
  // =============================

  // State Ảnh và Hashtag (Cập nhật dùng XFile)
  List<XFile> _selectedImages = []; // Lưu XFile để upload
  List<String> _hashtags = ['#travelmap', '#checkin']; // Bỏ #dalatdream
  final List<String> _suggestedTags = [
    '#review',
    '#foodie',
    '#amazingvietnam',
    '#phuquoc',
  ];
  bool _isSaving = false;
  final int _maxImages = 10;

  @override
  void initState() {
    super.initState();
    // Nếu có initialPlaceId, tải thông tin địa điểm đó
    if (widget.initialPlaceId != null && widget.initialPlaceId!.isNotEmpty) {
      _fetchPlaceDetails(widget.initialPlaceId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  // Hàm tiện ích _showSnackBar (Giữ nguyên)
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : null,
        ),
      );
    }
  }

  // === HÀM MỚI: TẢI CHI TIẾT ĐỊA ĐIỂM TỪ FIRESTORE ===
  Future<void> _fetchPlaceDetails(String placeId) async {
    if (!mounted) return;
    setState(() => _isLoadingPlace = true);
    try {
      final placeDoc = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .get();
      if (placeDoc.exists && mounted) {
        setState(() {
          _selectedPlaceDoc = placeDoc;
          _isLoadingPlace = false;
        });
      } else if (mounted) {
        _showSnackBar(
          'Không tìm thấy thông tin địa điểm ($placeId). Vui lòng chọn lại.',
          isError: true,
        );
        setState(() => _isLoadingPlace = false);
      }
    } catch (e) {
      print("Lỗi tải chi tiết địa điểm: $e");
      if (mounted) {
        _showSnackBar('Lỗi tải thông tin địa điểm: $e', isError: true);
        setState(() => _isLoadingPlace = false);
      }
    }
  }
  // =====================================================

  // === LOGIC CHỌN ẢNH (Dùng XFile - Giữ nguyên) ===
  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= _maxImages) {
      _showSnackBar('Chỉ được chọn tối đa $_maxImages ảnh.');
      if (Navigator.canPop(context)) Navigator.pop(context);
      return;
    }
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage(
          // Có thể thêm giới hạn imageQuality nếu cần
          // imageQuality: 80,
        );
        if (images.isNotEmpty) {
          int availableSlots = _maxImages - _selectedImages.length;
          int countToAdd = images.length < availableSlots
              ? images.length
              : availableSlots;
          setState(() => _selectedImages.addAll(images.sublist(0, countToAdd)));
          if (images.length > countToAdd)
            _showSnackBar('Đã đạt giới hạn $_maxImages ảnh.');
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: source,
          // imageQuality: 80, // Giảm chất lượng ảnh chụp nếu cần
        );
        if (image != null) setState(() => _selectedImages.add(image));
      }
    } catch (e) {
      print("Lỗi chọn ảnh: $e");
      _showSnackBar("Không thể chọn ảnh: $e", isError: true);
    }
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _showImageSourceDialog() {
    // Giao diện BottomSheet giữ nguyên
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                onPressed: () => _pickImage(ImageSource.gallery),
                label: const Text('Chọn từ thư viện') /*...*/,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: () => _pickImage(ImageSource.camera),
                label: const Text('Chụp ảnh mới') /*...*/,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy') /*...*/,
              ),
            ],
          ),
        ),
      ),
    );
  }
  // =======================================================

  // === LOGIC UPLOAD ẢNH LÊN CLOUDINARY (Dùng XFile - Giữ nguyên) ===
  Future<String?> _uploadLocalFile(XFile imageFile) async {
    File file = File(imageFile.path);
    try {
      return await _cloudinaryService.uploadImageToCloudinary(file);
    } catch (e) {
      print("Lỗi tải ảnh '${imageFile.name}' lên Cloudinary: $e");
      _showSnackBar("Lỗi tải ảnh '${imageFile.name}'.", isError: true);
      return null;
    }
  }
  // ==============================================================

  // === HÀM _submitReview (Đã cập nhật) ===
  Future<void> _submitReview() async {
    // --- VALIDATION ---
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập Tiêu đề.');
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập Nội dung.');
      return;
    }
    if (_selectedPlaceDoc == null) {
      _showSnackBar('Vui lòng chọn địa điểm.');
      return;
    }
    if (_selectedImages.isEmpty) {
      _showSnackBar('Vui lòng thêm ít nhất một ảnh.');
      return;
    }
    if (_isSaving) return;
    // -------------------

    setState(() => _isSaving = true);
    _showSnackBar('Đang xử lý...');

    try {
      // 1. Tải ảnh (dùng _selectedImages)
      List<String> finalImageUrls = [];
      _showSnackBar('Đang tải ${_selectedImages.length} ảnh...');
      List<Future<String?>> uploadFutures = _selectedImages
          .map(_uploadLocalFile)
          .toList();
      List<String?> results = await Future.wait(uploadFutures);
      finalImageUrls = results.whereType<String>().toList(); // Lọc bỏ null

      // Quan trọng: Kiểm tra xem có ảnh nào được tải lên thành công không
      if (finalImageUrls.isEmpty && _selectedImages.isNotEmpty) {
        throw Exception('Không thể tải lên bất kỳ ảnh nào. Vui lòng thử lại.');
      }
      _showSnackBar('Tải ảnh hoàn tất!');

      final placeData =
          _selectedPlaceDoc!.data() as Map<String, dynamic>? ?? {};
      // Lấy mảng categoryIds từ place (mặc định là mảng rỗng nếu không có)
      final List<dynamic> categoryIds =
          placeData['categories'] as List<dynamic>? ?? [];

      // 2. Chuẩn bị dữ liệu Firestore
      final reviewsCollection = FirebaseFirestore.instance.collection(
        'reviews',
      );
      final newDoc = reviewsCollection.doc(); // Firestore tự tạo ID

      final reviewData = {
        'userId': widget.currentUserId,
        'placeId': _selectedPlaceDoc!.id, // <-- Lấy ID từ DocumentSnapshot
        'rating': 5, // Tạm thời, có thể thêm RatingBar sau
        'comment': _commentController.text.trim(),
        'title': _titleController.text.trim(),
        'imageUrls': finalImageUrls, // Danh sách URL đã tải lên
        'hashtags': _hashtags,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'commentCount': 0,
        'categoryIds': categoryIds, // Sao chép mảng ID từ place sang review
      };

      // 3. Ghi vào Firestore
      await newDoc.set(reviewData);

      // 4. Cập nhật reviewCount trong collection 'places'
      await FirebaseFirestore.instance
          .collection('places')
          .doc(_selectedPlaceDoc!.id)
          .update({
            'reviewCount': FieldValue.increment(1),
            // TODO: Có thể cần cập nhật cả ratingAverage ở đây (cần logic tính toán phức tạp hơn)
          });

      _showSnackBar('Đăng bài check-in thành công!');
      if (mounted) Navigator.pop(context); // Quay lại màn hình trước
    } catch (e) {
      _showSnackBar('Lỗi khi đăng bài: $e', isError: true);
    } finally {
      // Luôn tắt trạng thái saving dù thành công hay thất bại
      if (mounted) setState(() => _isSaving = false);
    }
  }
  // ===================================================================

  // === CÁC WIDGET PHỤ ===

  // _buildImageItem (Sửa để dùng XFile - Giữ nguyên)
  Widget _buildImageItem(XFile imageFile, VoidCallback onRemove) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              // Dùng Image.file
              File(imageFile.path),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4, // Điều chỉnh vị trí nút xóa
          child: InkWell(
            onTap: onRemove,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // --- HÀM MỚI: MỞ BẢN ĐỒ MINI ---
  void _showMiniMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép sheet cao
      backgroundColor: Colors.transparent, // Nền trong suốt để thấy bo góc
      builder: (context) => DraggableScrollableSheet(
        // Cho phép kéo thay đổi chiều cao
        initialChildSize: 0.7, // Chiều cao ban đầu (70% màn hình)
        minChildSize: 0.3, // Chiều cao nhỏ nhất (30%)
        maxChildSize: 0.9, // Chiều cao lớn nhất (90%)
        expand: false, // Không chiếm full màn hình ban đầu
        builder: (_, controller) => _MiniMapPicker(
          // Gọi widget Mini Map
          scrollController: controller, // Truyền scroll controller
          onPlaceSelected: (placeDoc) {
            // Cập nhật state khi chọn xong
            if (mounted) setState(() => _selectedPlaceDoc = placeDoc);
            Navigator.pop(context); // Đóng bottom sheet
          },
        ),
      ),
    );
  }
  // -----------------------------

  // --- Các hàm Hashtag (_addHashtag, _removeHashtag, _addSuggestedTag) giữ nguyên ---
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
    setState(() => _hashtags.remove(tag));
  }

  void _addSuggestedTag(String tag) {
    if (!_hashtags.contains(tag) && _hashtags.length < 5) {
      setState(() => _hashtags.add(tag));
    } else if (_hashtags.length >= 5) {
      _showSnackBar('Đã đạt tối đa 5 Hashtag.');
    }
  }
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Checkin',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kAppbarColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
              // === PHẦN ĐỊA ĐIỂM (ĐÃ CẬP NHẬT HOÀN TOÀN) ===
              _buildPlaceSection(),
              // =============================================
              const SizedBox(height: 24),
              _buildHashtagSection(),
              const SizedBox(height: 24),
              _buildPrivacySection(),
              const SizedBox(height: 32),
              SizedBox(
                // Nút Đăng bài
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : _submitReview, // Disable khi đang lưu
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAppbarColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black54,
                          ),
                        )
                      : const Text(
                          'Đăng bài',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === Widget hiển thị Ảnh (Đã cập nhật dùng _selectedImages - Giữ nguyên) ===
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ảnh nổi bật (${_selectedImages.length}/$_maxImages)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _selectedImages.isEmpty
            // Nút Thêm ảnh ban đầu
            ? InkWell(
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
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.black54,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thêm ảnh/bài viết (tối đa $_maxImages)',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // Danh sách ảnh đã chọn và nút '+'
            : SizedBox(
                height: 100, // Chiều cao cố định cho hàng ảnh
                child: Row(
                  children: [
                    // Nút '+' (chỉ hiện khi chưa đủ ảnh)
                    if (_selectedImages.length < _maxImages)
                      InkWell(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, color: Colors.grey),
                              Text(
                                'Thêm ảnh',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '(${_selectedImages.length}/$_maxImages)',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Danh sách ảnh theo chiều ngang
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, // Cuộn ngang
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          final imgFile = _selectedImages[index];
                          // Gọi widget hiển thị thumbnail
                          return _buildImageItem(imgFile, () {
                            setState(() => _selectedImages.removeAt(index));
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  // Widget _buildJourneyContent (Giữ nguyên)
  Widget _buildJourneyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Câu chuyện hành trình',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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

  // === Widget hiển thị Địa điểm (ĐÃ CẬP NHẬT HOÀN TOÀN) ===
  Widget _buildPlaceSection() {
    String placeName = 'Chưa chọn địa điểm';
    String placeAddress = '';
    bool hasSelectedPlace = _selectedPlaceDoc != null;

    if (_isLoadingPlace) {
      // Hiển thị loading nếu đang tải place ban đầu
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Lấy tên và địa chỉ nếu đã chọn
    if (hasSelectedPlace) {
      final data = _selectedPlaceDoc!.data() as Map<String, dynamic>? ?? {};
      placeName = data['name'] ?? 'Địa điểm không tên';
      final location = data['location'] as Map<String, dynamic>? ?? {};
      // Ưu tiên fullAddress, nếu không có thì ghép street + city
      placeAddress = location['fullAddress']?.isNotEmpty == true
          ? location['fullAddress']
          : '${location['street'] ?? ''}, ${location['city'] ?? ''}'
                .replaceAll(RegExp(r'^, |, $'), '')
                .trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vị trí du lịch',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
              Icon(
                Icons.location_on_outlined,
                color: hasSelectedPlace ? Colors.orange : Colors.grey,
                size: 28,
              ), // Icon to hơn chút
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  // Luôn cho phép mở map picker để chọn lại
                  onTap: _showMiniMapPicker, // <-- GỌI HÀM MỞ MAP MINI
                  child: Container(
                    color: Colors
                        .transparent, // Cho phép InkWell bắt sự kiện trên toàn bộ vùng
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placeName,
                          style: TextStyle(
                            fontWeight: hasSelectedPlace
                                ? FontWeight.w600
                                : FontWeight.normal, // Đậm hơn khi đã chọn
                            fontSize: 15,
                            color: hasSelectedPlace
                                ? Colors.black87
                                : Colors.orange, // Màu cam khi chưa chọn
                          ),
                        ),
                        // Hiển thị địa chỉ nếu có
                        if (placeAddress.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              placeAddress,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        // Hiển thị nút "Chọn/Thay đổi"
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            hasSelectedPlace
                                ? 'Chạm để thay đổi địa điểm'
                                : 'Chạm để chọn địa điểm từ bản đồ',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Nút X để xóa lựa chọn hiện tại (chỉ hiện khi đã chọn)
              if (hasSelectedPlace)
                InkWell(
                  onTap: () {
                    if (mounted)
                      setState(() {
                        _selectedPlaceDoc = null;
                      });
                  },
                  borderRadius: BorderRadius.circular(15), // Bo tròn hiệu ứng
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, size: 20, color: Colors.black54),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  // =======================================================

  // Widget _buildHashtagSection (Giữ nguyên)
  Widget _buildHashtagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hashtag',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        // Hiển thị các hashtag đã chọn
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _hashtags
              .map(
                (tag) => Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  backgroundColor: Colors.grey[200],
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeHashtag(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  deleteIconColor: Colors.grey[600],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        // Hiển thị các hashtag gợi ý
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _suggestedTags.map((tag) {
            bool isSelected = _hashtags.contains(tag);
            return ActionChip(
              label: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.grey : Colors.blue[700],
                ),
              ),
              backgroundColor: isSelected ? Colors.grey[300] : Colors.blue[50],
              onPressed: isSelected ? null : () => _addSuggestedTag(tag),
              tooltip: isSelected ? 'Đã chọn' : 'Thêm hashtag này',
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Ô nhập hashtag
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
                    hintText: _hashtags.length < 5
                        ? 'Thêm hashtag...'
                        : 'Đã đủ 5 hashtag',
                    border: InputBorder.none,
                    counterText: '${_hashtags.length}/5 hashtag',
                  ),
                  enabled: _hashtags.length < 5,
                  onSubmitted: (_) => _addHashtag(),
                ),
              ),
              TextButton(
                onPressed: _hashtags.length < 5 ? _addHashtag : null,
                child: Text(
                  'Thêm',
                  style: TextStyle(
                    color: _hashtags.length < 5 ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildPrivacySection (Giữ nguyên)
  Widget _buildPrivacySection() {
    String _privacySetting = 'Công khai';
    IconData _privacyIcon = Icons.public; // Đổi icon thành public
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quyền riêng tư',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
                    Icon(_privacyIcon, color: Colors.black54, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      _privacySetting,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} // End _CheckinScreenState

// =======================================================
// WIDGET MINI MAP PICKER (ĐẶT Ở NGOÀI CLASS STATE)
// =======================================================
class _MiniMapPicker extends StatefulWidget {
  final Function(DocumentSnapshot) onPlaceSelected;
  final ScrollController scrollController; // Để DraggableScrollableSheet cuộn

  const _MiniMapPicker({
    required this.onPlaceSelected,
    required this.scrollController,
  });

  @override
  State<_MiniMapPicker> createState() => _MiniMapPickerState();
}

class _MiniMapPickerState extends State<_MiniMapPicker> {
  final MapController _mapController = MapController();
  List<DocumentSnapshot> _places = [];
  List<Marker> _markers = [];
  bool _isLoading = true;
  String _searchText = '';
  List<DocumentSnapshot> _filteredPlaces = []; // Danh sách lọc
  final TextEditingController _searchController =
      TextEditingController(); // Controller cho search

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose(); // Dispose map controller
    super.dispose();
  }

  // Tải danh sách places từ Firestore
  Future<void> _fetchPlaces() async {
    setState(() => _isLoading = true);
    try {
      // Chỉ lấy các field cần thiết để nhẹ hơn (tùy chọn)
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('places')
          // .select(['name', 'location']) // Chỉ lấy tên và location
          .get();
      _places = snapshot.docs;
      _updateMarkers(); // Tạo marker từ data
      _filterPlaces(); // Lọc danh sách ban đầu (hiển thị tất cả)
    } catch (e) {
      print("Lỗi tải places cho map picker: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách địa điểm: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      // Luôn tắt loading
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Tạo/Cập nhật danh sách Markers cho bản đồ
  void _updateMarkers() {
    _markers = _places
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final coordinates = data['location']?['coordinates'] as GeoPoint?;
          if (coordinates != null) {
            // Tạo Marker cho mỗi địa điểm
            return Marker(
              point: LatLng(
                coordinates.latitude,
                coordinates.longitude,
              ), // Tọa độ
              width: 35,
              height: 35, // Kích thước marker
              child: GestureDetector(
                // Cho phép bấm vào marker
                onTap: () =>
                    widget.onPlaceSelected(doc), // Gọi callback khi chọn
                child: Tooltip(
                  // Hiển thị tên khi hover
                  message: data['name'] ?? 'Địa điểm',
                  child: Container(
                    // Vòng tròn màu xanh chứa icon
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.white,
                      size: 20.0,
                    ), // Icon ghim
                  ),
                ),
              ),
            );
          }
          return null; // Bỏ qua nếu không có tọa độ
        })
        .whereType<Marker>()
        .toList(); // Lọc bỏ các giá trị null
    // Cập nhật UI nếu cần (thường không cần vì MarkerLayer tự build lại)
    // if(mounted) setState(() {});
  }

  // Lọc danh sách địa điểm dựa trên text tìm kiếm
  void _filterPlaces() {
    if (_searchText.isEmpty) {
      _filteredPlaces = _places; // Nếu không tìm kiếm, hiển thị tất cả
    } else {
      // Lọc dựa trên tên, địa chỉ, thành phố (không phân biệt hoa thường)
      _filteredPlaces = _places.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] as String? ?? '';
        final location = data['location'] as Map<String, dynamic>? ?? {};
        final address = location['fullAddress'] as String? ?? '';
        final city = location['city'] as String? ?? '';
        final searchLower = _searchText.toLowerCase();
        return name.toLowerCase().contains(searchLower) ||
            address.toLowerCase().contains(searchLower) ||
            city.toLowerCase().contains(searchLower);
      }).toList();
    }
    // Cập nhật UI để hiển thị danh sách đã lọc
    if (mounted) setState(() {});
  }

  // Di chuyển bản đồ đến vị trí của địa điểm được chọn trong danh sách
  void _moveToPlace(DocumentSnapshot placeDoc) {
    final data = placeDoc.data() as Map<String, dynamic>;
    final coordinates = data['location']?['coordinates'] as GeoPoint?;
    if (coordinates != null) {
      // Di chuyển và zoom gần hơn (mức 15)
      _mapController.move(
        LatLng(coordinates.latitude, coordinates.longitude),
        15.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Trang trí cho bottom sheet
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Thanh kéo và Title
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 0),
            child: Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              'Chọn địa điểm từ bản đồ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Bản đồ Mini
          SizedBox(
            height:
                MediaQuery.of(context).size.height * 0.35, // Chiều cao cố định
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(16.0, 108.0), // Trung tâm VN
                      initialZoom: 5.5, // Zoom tổng quan
                      interactionOptions: const InteractionOptions(
                        flags:
                            InteractiveFlag.pinchZoom |
                            InteractiveFlag.drag, // Chỉ cho zoom và kéo
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.nhom_3_damh_lttbdd', // Thay tên package
                        maxZoom: 19, // Giữ nguyên maxZoom
                      ),
                      MarkerLayer(markers: _markers), // Hiển thị marker
                    ],
                  ),
          ),

          // Thanh Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
            child: TextField(
              controller: _searchController, // Dùng controller
              onChanged: (value) {
                _searchText = value;
                _filterPlaces();
              }, // Lọc khi text thay đổi
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên hoặc địa chỉ...',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Colors.grey,
                ),
                isDense: true, // Nhỏ gọn hơn
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: kBorderColor, width: 1.5),
                ), // Màu cam khi focus
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ), // Điều chỉnh padding
                // Nút X để xóa text
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchText = '';
                          _filterPlaces();
                        }, // Xóa text và lọc lại
                      )
                    : null,
              ),
            ),
          ),

          // Danh sách kết quả (cho phép cuộn độc lập)
          Expanded(
            child: _isLoading
                ? const SizedBox.shrink() // Không hiển thị gì khi map đang load
                : _filteredPlaces.isEmpty
                ? Center(
                    child: Text(
                      _searchText.isEmpty
                          ? 'Kéo bản đồ hoặc tìm kiếm...'
                          : 'Không tìm thấy địa điểm phù hợp.',
                    ),
                  ) // Thông báo động
                : ListView.builder(
                    controller: widget
                        .scrollController, // Quan trọng cho DraggableScrollableSheet
                    itemCount: _filteredPlaces.length,
                    itemBuilder: (context, index) {
                      final placeDoc = _filteredPlaces[index];
                      final data = placeDoc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Không tên';
                      final location =
                          data['location'] as Map<String, dynamic>? ?? {};
                      final address =
                          location['fullAddress'] ?? 'Không địa chỉ';
                      return ListTile(
                        leading: const Icon(
                          Icons.location_pin,
                          color: Colors.blueAccent,
                          size: 28,
                        ), // Icon địa điểm
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ), // Tên địa điểm
                        subtitle: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ), // Địa chỉ (1 dòng)
                        onTap: () => widget.onPlaceSelected(
                          placeDoc,
                        ), // Chọn khi bấm vào list item
                        trailing: IconButton(
                          // Nút di chuyển map tới vị trí
                          icon: const Icon(
                            Icons.my_location,
                            size: 20,
                            color: Colors.grey,
                          ),
                          tooltip: 'Xem trên bản đồ',
                          onPressed: () => _moveToPlace(placeDoc),
                        ),
                        dense: true, // Làm list item nhỏ gọn hơn
                      );
                    },
                  ),
          ),
          // Nút Hủy (tùy chọn)
          // Padding(padding: const EdgeInsets.all(16.0), child: OutlinedButton(onPressed: ()=>Navigator.pop(context), child: const Text('Hủy')))
        ],
      ),
    );
  }
}

// =======================================================
