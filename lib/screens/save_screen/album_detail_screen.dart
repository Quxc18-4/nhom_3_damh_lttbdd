import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/screens/postDetailScreen.dart';
import '/model/album_models.dart';
import 'package:nhom_3_damh_lttbdd/screens/save_screen/service/album_service.dart';

// Các widget phụ trợ
import 'widgets/album_detail/album_cover_picker_dialog.dart';
import 'widgets/album_detail/album_sliver_app_bar.dart';
import 'widgets/album_detail/album_empty_state.dart';
import 'widgets/album_detail/album_review_card.dart';

/// Màn hình chi tiết bộ sưu tập (Album)
/// Dữ liệu được lấy từ Firebase Firestore thông qua AlbumService
class AlbumDetailScreen extends StatefulWidget {
  final String userId; // ID người dùng (Firebase UID)
  final String albumId; // ID của album trong Firestore
  final String albumTitle; // Tên album hiển thị trên AppBar

  const AlbumDetailScreen({
    Key? key,
    required this.userId,
    required this.albumId,
    required this.albumTitle,
  }) : super(key: key);

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final AlbumService _albumService = AlbumService(); // Dịch vụ Firebase

  bool _isLoading = true; // Trạng thái đang tải dữ liệu
  List<SavedReviewItem> _savedReviews = []; // Danh sách bài viết đã lưu
  String _albumDescription = ''; // Mô tả album
  String? _albumCoverUrl; // Link ảnh bìa album

  @override
  void initState() {
    super.initState();
    _loadAlbumData(); // Tải dữ liệu ngay khi khởi tạo màn hình
  }

  /// Hàm tải dữ liệu album từ Firestore
  Future<void> _loadAlbumData() async {
    setState(() => _isLoading = true);

    try {
      // Lấy song song: thông tin album + danh sách bài viết
      final results = await Future.wait([
        _albumService.fetchAlbumData(widget.userId, widget.albumId),
        _albumService.fetchAlbumReviews(widget.userId, widget.albumId),
      ]);

      final albumData = results[0] as AlbumData;
      final reviews = results[1] as List<SavedReviewItem>;

      if (mounted) {
        setState(() {
          _albumDescription = albumData.description;
          _albumCoverUrl = albumData.coverImageUrl;
          _savedReviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🔥 Lỗi khi tải album: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Cập nhật ảnh bìa album (lưu lại URL vào Firestore)
  Future<void> _updateAlbumCover(String imageUrl) async {
    try {
      await _albumService.updateAlbumCover(
        widget.userId,
        widget.albumId,
        imageUrl,
      );

      if (mounted) {
        setState(() => _albumCoverUrl = imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ảnh bìa!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật ảnh bìa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mở hộp thoại chọn ảnh bìa mới (AlbumCoverPickerDialog)
  void _showCoverPickerDialog() {
    AlbumCoverPickerDialog.show(
      context,
      reviews: _savedReviews,
      onImageSelected: _updateAlbumCover,
    );
  }

  /// Hiển thị hộp thoại chỉnh sửa thông tin album (tên + mô tả)
  void _showEditAlbumDialog() async {
    final titleController = TextEditingController(text: widget.albumTitle);
    final descController = TextEditingController(text: _albumDescription);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Chỉnh sửa bộ sưu tập"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tên bộ sưu tập',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Hủy"),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          TextButton(
            child: const Text("Lưu"),
            onPressed: () {
              Navigator.pop(dialogContext, {
                'title': titleController.text.trim(),
                'description': descController.text.trim(),
              });
            },
          ),
        ],
      ),
    );

    // Nếu người dùng bấm Lưu
    if (result != null) {
      try {
        await _albumService.updateAlbumInfo(
          widget.userId,
          widget.albumId,
          title: result['title']!,
          description: result['description']!,
        );

        if (mounted) {
          setState(() => _albumDescription = result['description']!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi cập nhật: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Xóa toàn bộ album khỏi Firestore
  void _deleteAlbum() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xóa bộ sưu tập"),
        content: const Text(
          "Bạn có chắc muốn xóa bộ sưu tập này?\n"
          "Các bài viết sẽ được đưa về danh sách 'Đã lưu' chính.",
        ),
        actions: [
          TextButton(
            child: const Text("Hủy"),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          TextButton(
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _albumService.deleteAlbum(widget.userId, widget.albumId);

        if (mounted) {
          Navigator.pop(context); // Quay về màn hình trước
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa bộ sưu tập!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Chuyển đến màn hình chi tiết bài viết (PostDetailScreen)
  void _navigateToReviewDetail(String reviewId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(reviewId: reviewId),
      ),
    );
  }

  // ------------------- GIAO DIỆN -------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar co giãn với ảnh bìa và các nút thao tác
          AlbumSliverAppBar(
            albumTitle: widget.albumTitle,
            coverUrl: _getCoverUrl(),
            onEdit: _showEditAlbumDialog,
            onChangeCover: _showCoverPickerDialog,
            onDelete: _deleteAlbum,
          ),

          // Hiển thị tiến trình khi đang tải
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            )
          else if (_savedReviews.isEmpty)
            // Nếu album rỗng
            const SliverFillRemaining(child: AlbumEmptyState())
          else
            // Hiển thị danh sách review trong grid
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return AlbumReviewCard(
                    item: _savedReviews[index],
                    onTap: () =>
                        _navigateToReviewDetail(_savedReviews[index].reviewId),
                  );
                }, childCount: _savedReviews.length),
              ),
            ),
        ],
      ),
    );
  }

  /// Trả về ảnh bìa hợp lệ (nếu không có thì lấy ảnh bài viết đầu tiên)
  String _getCoverUrl() {
    final String fallbackCoverUrl = _savedReviews.isNotEmpty
        ? _savedReviews.first.imageUrl
        : 'https://via.placeholder.com/600x400.png?text=Album+Cover';
    return _albumCoverUrl ?? fallbackCoverUrl;
  }
}
