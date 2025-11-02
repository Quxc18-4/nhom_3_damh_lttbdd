import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// Dialog hiển thị để lưu bài viết vào bookmark hoặc album
class SaveDialog extends StatefulWidget {
  final String userId; // ID người dùng hiện tại
  final String reviewId; // ID bài viết
  final String authorId; // ID tác giả bài viết
  final String? postImageUrl; // URL ảnh chính của bài viết (nếu có)

  const SaveDialog({
    Key? key,
    required this.userId,
    required this.reviewId,
    required this.authorId,
    this.postImageUrl,
  }) : super(key: key);

  /// Static method để hiển thị dialog dễ dàng
  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String reviewId,
    required String authorId,
    String? postImageUrl,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SaveDialog(
        userId: userId,
        reviewId: reviewId,
        authorId: authorId,
        postImageUrl: postImageUrl,
      ),
    );
  }

  @override
  State<SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<SaveDialog> {
  // Kiểm tra user đã đăng nhập chưa
  bool get _isAuthenticated => auth.FirebaseAuth.instance.currentUser != null;

  // =========================================================================
  // ACTIONS
  // =========================================================================

  /// Hiển thị dialog tạo album mới
  Future<void> _showCreateAlbumDialog() async {
    if (!_isAuthenticated) {
      _showErrorSnackbar("Bạn cần đăng nhập để tạo album.");
      return;
    }

    final TextEditingController albumNameController = TextEditingController();

    final String? newAlbumName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Tạo album mới"),
          content: TextField(
            controller: albumNameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Nhập tên album..."),
          ),
          actions: [
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text("Tạo"),
              onPressed: () {
                if (albumNameController.text.trim().isNotEmpty) {
                  Navigator.of(
                    dialogContext,
                  ).pop(albumNameController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    // Nếu có tên album mới, thêm vào Firestore
    if (newAlbumName != null && newAlbumName.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('albums')
            .add({
              'title': newAlbumName,
              'description': '',
              'createdAt': FieldValue.serverTimestamp(),
              'photos': [],
            });

        // Refresh state để hiển thị album mới
        if (mounted) setState(() {});
      } catch (e) {
        _showErrorSnackbar("Tạo album thất bại: $e");
      }
    }
  }

  /// Lưu bài viết vào bookmark
  Future<void> _saveBookmark({String? albumId}) async {
    if (!_isAuthenticated) {
      _showErrorSnackbar("Bạn cần đăng nhập để lưu.");
      return;
    }

    final bool isCreator = (widget.userId == widget.authorId);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('bookmarks')
          .add({
            'reviewID': widget.reviewId,
            'albumId': albumId, // null nếu lưu chung
            'addedAt': FieldValue.serverTimestamp(),
            'postImageUrl': widget.postImageUrl,
            'creator': isCreator, // đánh dấu nếu chính mình tạo bài
          });

      if (mounted) {
        Navigator.of(context).pop(); // đóng dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(albumId == null ? "Đã lưu!" : "Đã lưu vào album!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackbar("Lưu thất bại: $e");
    }
  }

  /// Hiển thị Snackbar lỗi
  void _showErrorSnackbar(String message) {
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // đóng dialog nếu đang mở
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // =========================================================================
  // BUILD UI
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Lưu vào bộ sưu tập"),
      content: FutureBuilder<QuerySnapshot>(
        // Lấy danh sách album của user
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('albums')
            .orderBy('createdAt', descending: true)
            .get(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return const Text("Không thể tải album. Vui lòng thử lại.");
          }

          final albums = snapshot.data?.docs ?? [];

          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: albums.length + 1, // +1 cho nút tạo album mới
              itemBuilder: (context, index) {
                // Item 0: nút tạo album mới
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.add_box_outlined),
                    title: const Text("Tạo album mới..."),
                    onTap: _showCreateAlbumDialog,
                  );
                }

                // Các album hiện có
                final albumDoc = albums[index - 1];
                final albumData = albumDoc.data() as Map<String, dynamic>;
                final String albumId = albumDoc.id;
                final String albumTitle =
                    albumData['title'] ?? 'Album không tên';

                return ListTile(
                  leading: const Icon(Icons.photo_album_outlined),
                  title: Text(albumTitle),
                  onTap: () => _saveBookmark(albumId: albumId),
                );
              },
            ),
          );
        },
      ),
      actions: [
        // Hủy
        TextButton(
          child: const Text("Hủy"),
          onPressed: () => Navigator.of(context).pop(),
        ),

        // Lưu bài viết mà không thêm album
        TextButton(
          child: const Text("LƯU (KHÔNG THÊM VÀO ALBUM)"),
          onPressed: () => _saveBookmark(albumId: null),
        ),
      ],
    );
  }
}
