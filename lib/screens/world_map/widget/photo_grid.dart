// File: screens/world_map/widget/photo_grid.dart

import 'package:flutter/material.dart';

/// Widget hiển thị grid ảnh, tự động điều chỉnh layout
/// dựa trên số lượng ảnh (1, 2, 3, hoặc 4+).
class PhotoGrid extends StatelessWidget {
  final List<String> imageUrls;
  const PhotoGrid({Key? key, required this.imageUrls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int count = imageUrls.length;

    if (count == 0) {
      // Placeholder khi không có ảnh
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Hãy là người đầu tiên khám phá ra vị trí này!',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    const double totalHeight = 180; // Chiều cao cố định

    // 1 ảnh
    if (count == 1) {
      return SizedBox(
        height: totalHeight,
        width: double.infinity,
        child: _buildImage(
          imageUrls[0],
          height: totalHeight,
          width: double.infinity,
          isTaller: true,
        ),
      );
    }

    // 2 ảnh
    if (count == 2) {
      return SizedBox(
        height: totalHeight,
        child: Row(
          children: [
            Expanded(
              child: _buildImage(
                imageUrls[0],
                height: totalHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildImage(
                imageUrls[1],
                height: totalHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
          ],
        ),
      );
    }

    // 3 ảnh
    if (count == 3) {
      return SizedBox(
        height: totalHeight,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildImage(
                imageUrls[0],
                height: totalHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: _buildImage(
                      imageUrls[1],
                      height: double.infinity,
                      width: double.infinity,
                      isTaller: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _buildImage(
                      imageUrls[2],
                      height: double.infinity,
                      width: double.infinity,
                      isTaller: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4+ ảnh
    final int remainingCount = count - 4;
    return SizedBox(
      height: totalHeight,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImage(
                    imageUrls[0],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildImage(
                    imageUrls[1],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImage(
                    imageUrls[2],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildImage(
                    imageUrls[3],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                    overlay: remainingCount > 0
                        ? Container(
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                '+$remainingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper render ảnh (private trong file này)
  Widget _buildImage(
    String imageUrl, {
    required double height,
    required double width,
    Widget? overlay,
    bool isTaller = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: isTaller ? StackFit.expand : StackFit.loose,
        children: [
          Image.network(
            imageUrl,
            height: height,
            width: width,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                height: height,
                width: width,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                height: height,
                width: width,
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.red, size: 30),
                ),
              );
            },
          ),
          if (overlay != null) overlay,
        ],
      ),
    );
  }
}
