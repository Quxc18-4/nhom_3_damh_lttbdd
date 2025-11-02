// File: screens/checkin/checkin_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Import Service và Widgets đã tách
import 'service/checkin_service.dart';
import 'widget/checkin_widgets.dart';
import 'widget/mini_map_picker.dart';

// Màu sắc (lấy từ file gốc)
const Color kAppbarColor = Color(0xFFE4C99E);

class CheckinScreen extends StatefulWidget {
  final String currentUserId;
  final String? initialPlaceId;

  const CheckinScreen({
    super.key,
    required this.currentUserId,
    this.initialPlaceId,
  });

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  // Service
  final CheckinService _service = CheckinService();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();

  // State
  DocumentSnapshot? _selectedPlaceDoc;
  bool _isLoadingPlace = false;
  List<XFile> _selectedImages = [];
  List<String> _hashtags = ['#travelmap', '#checkin'];
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
    if (widget.initialPlaceId != null && widget.initialPlaceId!.isNotEmpty) {
      _handleFetchPlaceDetails(widget.initialPlaceId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  // === HÀM XỬ LÝ LOGIC (GỌI SERVICE) ===

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

  /// Tải chi tiết địa điểm (gọi service)
  Future<void> _handleFetchPlaceDetails(String placeId) async {
    if (!mounted) return;
    setState(() => _isLoadingPlace = true);
    try {
      final placeDoc = await _service.fetchPlaceDetails(placeId);
      if (mounted) {
        setState(() {
          _selectedPlaceDoc = placeDoc;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi tải thông tin địa điểm: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoadingPlace = false);
    }
  }

  /// Xử lý chọn ảnh (gọi service)
  Future<void> _handlePickImage(ImageSource source) async {
    if (Navigator.canPop(context)) Navigator.pop(context); // Đóng dialog
    try {
      if (source == ImageSource.gallery) {
        final images = await _service.pickImagesFromGallery(
          _selectedImages.length,
          _maxImages,
        );
        if (images.isNotEmpty) {
          setState(() => _selectedImages.addAll(images));
          if (_selectedImages.length == _maxImages) {
            _showSnackBar('Đã đạt giới hạn $images ảnh.');
          }
        }
      } else {
        final image = await _service.pickImageFromCamera(
          _selectedImages.length,
          _maxImages,
        );
        if (image != null) setState(() => _selectedImages.add(image));
      }
    } catch (e) {
      _showSnackBar("Không thể chọn ảnh: $e", isError: true);
    }
  }

  /// Gửi bài review (gọi service)
  Future<void> _handleSubmitReview() async {
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

    setState(() => _isSaving = true);
    _showSnackBar('Đang xử lý...');

    try {
      await _service.submitReview(
        userId: widget.currentUserId,
        selectedPlaceDoc: _selectedPlaceDoc!,
        title: _titleController.text.trim(),
        comment: _commentController.text.trim(),
        hashtags: _hashtags,
        selectedImages: _selectedImages,
      );
      _showSnackBar('Đăng bài check-in thành công!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Lỗi khi đăng bài: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // === HÀM XỬ LÝ UI (SHOW DIALOG, SETSTATE...) ===

  /// Hiển thị dialog chọn Nguồn ảnh
  void _showImageSourceDialog() {
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
                onPressed: () => _handlePickImage(ImageSource.gallery),
                label: const Text('Chọn từ thư viện'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: () => _handlePickImage(ImageSource.camera),
                label: const Text('Chụp ảnh mới'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hiển thị Mini Map Picker
  void _showMiniMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => MiniMapPicker(
          // <-- GỌI WIDGET MỚI
          scrollController: controller,
          onPlaceSelected: (placeDoc) {
            if (mounted) setState(() => _selectedPlaceDoc = placeDoc);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // --- Logic Hashtag (Giữ lại vì setState trực tiếp) ---
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
              // === SỬ DỤNG CÁC WIDGET ĐÃ TÁCH ===

              // 1. Image Section
              // (Phần này hơi phức tạp vì _buildImageItem nằm trong _buildImageSection,
              // nên tôi sẽ giữ nguyên hàm _buildImageItem trong state này)
              ImageSection(
                selectedImages: _selectedImages,
                maxImages: _maxImages,
                onAddImage: _showImageSourceDialog,
                onRemoveImage: (imageFile) {
                  // Định nghĩa logic xóa trực tiếp ở đây
                  setState(() {
                    _selectedImages.removeWhere(
                      (f) => f.path == imageFile.path,
                    );
                  });
                },
              ),
              const SizedBox(height: 24),

              // 2. Journey Content
              JourneyContentSection(
                titleController: _titleController,
                commentController: _commentController,
              ),
              const SizedBox(height: 24),

              // 3. Place Section
              PlaceSection(
                selectedPlaceDoc: _selectedPlaceDoc,
                isLoadingPlace: _isLoadingPlace,
                onShowMiniMap: _showMiniMapPicker,
                onClearPlace: () {
                  setState(() => _selectedPlaceDoc = null);
                },
              ),
              const SizedBox(height: 24),

              // 4. Hashtag Section
              HashtagSection(
                hashtags: _hashtags,
                suggestedTags: _suggestedTags,
                hashtagController: _hashtagController,
                onAddHashtag: _addHashtag,
                onRemoveHashtag: _removeHashtag,
                onAddSuggestedTag: _addSuggestedTag,
              ),
              const SizedBox(height: 24),

              // 5. Privacy Section
              PrivacySection(
                onTap: () {
                  _showSnackBar(
                    'Chức năng chọn quyền riêng tư chưa được cài đặt.',
                  );
                },
              ),
              const SizedBox(height: 32),

              // 6. Nút Đăng bài
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSubmitReview,
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
}
