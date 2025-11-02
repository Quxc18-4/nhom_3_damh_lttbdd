import 'package:flutter/material.dart';

/// Widget xem ảnh toàn màn hình với khả năng zoom & swipe
class PhotoViewer extends StatefulWidget {
  final List<String> photos; // Danh sách URL ảnh
  final int initialIndex; // Vị trí ảnh ban đầu khi mở viewer

  const PhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late PageController _controller; // Controller để quản lý trang của PageView
  late int _current; // Index hiện tại của ảnh

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(
      initialPage: _current,
    ); // Khởi tạo PageController với ảnh ban đầu
  }

  @override
  void dispose() {
    _controller.dispose(); // Giải phóng controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background tối, trong suốt
      body: Stack(
        children: [
          // PageView để lướt giữa các ảnh
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) =>
                setState(() => _current = i), // Cập nhật ảnh hiện tại
            itemBuilder: (_, i) => Center(
              child: InteractiveViewer(
                // Cho phép zoom & pan ảnh
                child: Image.network(
                  widget.photos[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          // Header hiển thị số ảnh & nút đóng
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hiển thị số lượng ảnh hiện tại / tổng số ảnh
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    child: Text(
                      '${_current + 1} / ${widget.photos.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  // Nút đóng
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
