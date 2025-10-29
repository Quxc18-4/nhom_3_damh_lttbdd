import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlbumTabContent extends StatefulWidget {
  final String userId; // ✅ Thêm userId để lọc bài viết

  const AlbumTabContent({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<AlbumTabContent> createState() => _AlbumTabContentState();
}

class _AlbumTabContentState extends State<AlbumTabContent> {
  List<String> _allPhotos = [];
  int _totalAlbums = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotosFromPosts();
  }

  // ✅ Fetch tất cả ảnh từ bài viết của user
  Future<void> _loadPhotosFromPosts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Lấy tất cả bài viết của user
      QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<String> photos = [];

      // 2. Lặp qua từng bài viết và lấy imageUrls
      for (var doc in reviewSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final List<dynamic> imageUrls = data['imageUrls'] ?? [];

        // Thêm tất cả ảnh vào danh sách
        for (var url in imageUrls) {
          if (url is String && url.isNotEmpty) {
            photos.add(url);
          }
        }
      }

      // 3. Lấy số lượng albums (từ subcollection albums)
      QuerySnapshot albumSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('albums')
          .get();

      if (mounted) {
        setState(() {
          _allPhotos = photos;
          _totalAlbums = albumSnapshot.docs.length;
          _isLoading = false;
        });
      }

    } catch (e) {
      print("Lỗi load ảnh: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAlbumSummaryCard(),
          const SizedBox(height: 24),
          _buildPhotoGridSection(),
        ],
      ),
    );
  }

  // ===================================================================
  // WIDGETS
  // ===================================================================

  Widget _buildAlbumSummaryCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              " ●  Bộ sưu tập ảnh",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              "Tổng hợp những khoảnh khắc đẹp nhất từ các chuyến du lịch, được chia thành nhiều album theo chủ đề.",
              style: TextStyle(height: 1.5),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.photo_library_outlined,
              "$_totalAlbums Albums",
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.camera_alt_outlined,
              "${_allPhotos.length} Photos",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildPhotoGridSection() {
    if (_allPhotos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có ảnh nào',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            " ↳  Ảnh đã đăng",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: _allPhotos.length,
          itemBuilder: (context, index) {
            return _buildPhotoItem(_allPhotos[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoItem(String imageUrl, int index) {
    return GestureDetector(
      onTap: () {
        // ✅ Mở fullscreen khi tap vào ảnh
        _showPhotoViewer(context, index);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: Colors.orange,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.grey[500],
                size: 30,
              ),
            );
          },
        ),
      ),
    );
  }

  // ✅ Hiển thị ảnh fullscreen với khả năng swipe
  void _showPhotoViewer(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _PhotoViewer(
        photos: _allPhotos,
        initialIndex: initialIndex,
      ),
    );
  }
}

// ===================================================================
// PHOTO VIEWER (Fullscreen với PageView)
// ===================================================================

class _PhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // PageView để swipe qua lại giữa các ảnh
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    widget.photos[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Header với nút đóng và số thứ tự ảnh
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation hints (nếu có nhiều ảnh)
          if (widget.photos.length > 1) ...[
            if (_currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            if (_currentIndex < widget.photos.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}