// File: screens/comment/commentScreen.dart

import 'package:flutter/material.dart'; // Thư viện chính Flutter để xây dựng UI
import 'package:cloud_firestore/cloud_firestore.dart'; // Kết nối Firestore để lấy stream comment
import 'package:firebase_auth/firebase_auth.dart' as auth; // Firebase Auth để lấy userId hiện tại
import 'package:intl/intl.dart'; // Định dạng ngày giờ (dùng trong comment_item.dart)

// Import Models
import 'package:nhom_3_damh_lttbdd/model/comment_model.dart'; // Model cho Comment (id, content, user, like, v.v.)
import 'package:nhom_3_damh_lttbdd/model/post_model.dart'; // Model cho Post (authorId, commentCount)

// Import Service và Widgets đã tách
import 'service/comment_service.dart'; // Service xử lý: stream, gửi, like, map data
import 'widget/comment_item.dart'; // Widget hiển thị một bình luận
import 'widget/comment_input_bar.dart'; // Widget thanh nhập + gửi comment

// Callback cho thông báo
typedef OnNotificationCreated = // Kiểu hàm callback khi có comment mới
    void Function( // Hàm nhận 4 tham số
      String recipientId, // ID người nhận thông báo (tác giả bài viết hoặc người được reply)
      String senderId, // ID người gửi comment
      String reviewId, // ID bài review
      String message, // Nội dung thông báo
    );

class CommentScreen extends StatefulWidget { // Màn hình bình luận (dạng bottom sheet)
  final String reviewId; // ID bài review (để truy vấn comment)
  final Post post; // Thông tin bài viết (authorId, commentCount)
  final OnNotificationCreated onCommentSent; // Callback để tạo thông báo khi gửi comment

  const CommentScreen({ // Constructor nhận các tham số bắt buộc
    Key? key,
    required this.reviewId,
    required this.post,
    required this.onCommentSent,
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState(); // Tạo state
}

class _CommentScreenState extends State<CommentScreen> { // State của màn hình bình luận
  // Service
  final CommentService _service = CommentService(); // Khởi tạo service xử lý comment

  // Controllers
  final TextEditingController _commentController = TextEditingController(); // Controller cho ô nhập
  final FocusNode _commentFocus = FocusNode(); // FocusNode để điều khiển bàn phím

  // State
  bool _isSending = false; // Đang gửi comment (hiển thị loading)
  CommentModel? _replyingToComment; // Bình luận đang trả lời (null nếu comment mới)

  @override
  void dispose() { // Dọn dẹp khi widget bị hủy
    _commentController.dispose(); // Giải phóng controller
    _commentFocus.dispose(); // Giải phóng focus
    super.dispose();
  }

  String get _currentUserId => // Lấy ID người dùng hiện tại
      auth.FirebaseAuth.instance.currentUser?.uid ?? ''; // Nếu null → rỗng
  bool get _isAuthenticated => _currentUserId.isNotEmpty; // Kiểm tra đã đăng nhập chưa

  // --- HÀM XỬ LÝ LOGIC (CONTROLLERS) ---

  void _showSnackBar(String message, {bool isError = false}) { // Hiển thị thông báo
    if (!mounted) return; // Nếu widget đã bị hủy → bỏ qua
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), // Nội dung
        backgroundColor: isError ? Colors.red : Colors.green, // Màu đỏ nếu lỗi, xanh nếu thành công
        duration: const Duration(seconds: 2), // Hiển thị 2 giây
      ),
    );
  }

  Future<void> _sendComment() async { // Gửi bình luận
    final commentText = _commentController.text.trim(); // Lấy nội dung, bỏ khoảng trắng
    if (commentText.isEmpty || !_isAuthenticated || _isSending) return; // Kiểm tra điều kiện

    setState(() => _isSending = true); // Bật loading
    _commentFocus.unfocus(); // Ẩn bàn phím

    try {
      // 1. Gửi comment (đã bao gồm cập nhật commentCount)
      await _service.sendComment( // Gọi service
        reviewId: widget.reviewId,
        currentUserId: _currentUserId,
        content: commentText,
        replyingToComment: _replyingToComment, // Nếu là reply → truyền vào
      );

      // 2. Kích hoạt Callback tạo thông báo
      String recipientId = (_replyingToComment != null) // Người nhận thông báo
          ? _replyingToComment!.userId // Nếu reply → người bị reply
          : widget.post.authorId; // Nếu comment mới → tác giả bài viết

      // Chỉ gửi thông báo nếu người nhận không phải là chính mình
      if (recipientId != _currentUserId) {
        widget.onCommentSent( // Gọi callback
          recipientId,
          _currentUserId,
          widget.reviewId,
          commentText,
        );
      }

      // 3. Reset UI
      _commentController.clear(); // Xóa ô nhập
      setState(() => _replyingToComment = null); // Hủy trạng thái reply
      _showSnackBar('Bình luận đã được gửi!'); // Thông báo thành công
    } catch (e) {
      _showSnackBar( // Hiển thị lỗi
        e.toString().replaceFirst("Exception: ", ""),
        isError: true,
      );
    } finally {
      if (mounted) { // Nếu widget còn tồn tại
        setState(() => _isSending = false); // Tắt loading
      }
    }
  }

  Future<void> _toggleCommentLike(CommentModel comment) async { // Thích/bỏ thích
    if (!_isAuthenticated) return; // Chưa đăng nhập → bỏ qua
    try {
      await _service.toggleCommentLike( // Gọi service
        reviewId: widget.reviewId,
        commentId: comment.id,
        currentUserId: _currentUserId,
        isCurrentlyLiked: comment.isLikedByUser, // Trạng thái hiện tại
      );
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst("Exception: ", ""),
        isError: true,
      );
    }
  }

  void _startReplyToUser(CommentModel comment) { // Bắt đầu trả lời
    if (!_isAuthenticated) { // Chưa đăng nhập
      _showSnackBar("Bạn cần đăng nhập để phản hồi!", isError: true);
      return;
    }
    setState(() {
      _replyingToComment = comment; // Gán đang reply
      _commentController.text = '@${comment.author.name} '; // Thêm @tên
      _commentFocus.requestFocus(); // Mở bàn phím
      _commentController.selection = TextSelection.fromPosition( // Đặt con trỏ cuối
        TextPosition(offset: _commentController.text.length),
      );
    });
  }

  void _cancelReply() { // Hủy trả lời
    setState(() {
      _replyingToComment = null; // Xóa trạng thái
      _commentController.clear(); // Xóa nội dung
      _commentFocus.unfocus(); // Ẩn bàn phím
    });
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildHeader() { // Header: tiêu đề + nút đóng
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 12, left: 16, right: 8), // Padding
      decoration: BoxDecoration( // Viền dưới
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn hai bên
        children: [
          Text( // Tiêu đề
            'Bình luận (${widget.post.commentCount})', // Hiển thị số lượng
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          IconButton( // Nút đóng
            icon: const Icon(Icons.close, color: Colors.black54),
            onPressed: () => Navigator.pop(context), // Đóng bottom sheet
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện chính
    final mediaQuery = MediaQuery.of(context); // Lấy kích thước màn hình
    final double maxSheetHeight = mediaQuery.size.height * 0.9; // Chiều cao tối đa 90%

    return Container( // Khung bottom sheet
      height: maxSheetHeight, // Chiều cao cố định
      decoration: const BoxDecoration( // Bo góc trên
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column( // Cột dọc: header + danh sách + thanh nhập
        children: [
          _buildHeader(), // Header

          Expanded( // Danh sách comment chiếm phần còn lại
            child: StreamBuilder<QuerySnapshot>( // Stream real-time từ Firestore
              stream: _service.getCommentsStream(widget.reviewId), // Stream comment
              builder: (context, snapshot) { // Xử lý trạng thái stream
                if (snapshot.hasError) { // Lỗi kết nối
                  return Center(
                    child: Text('Lỗi tải bình luận: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) { // Đang tải
                  return const Center(child: CircularProgressIndicator());
                }

                final commentDocs = snapshot.data?.docs ?? []; // List document
                if (commentDocs.isEmpty) { // Chưa có comment
                  return const Center(
                    child: Text(
                      'Chưa có bình luận nào. Hãy là người đầu tiên!',
                    ),
                  );
                }

                return FutureBuilder<List<CommentModel>>( // Map document → model
                  // Map data (lấy user, like status)
                  future: _service.mapCommentsWithUsers( // Gọi service
                    commentDocs,
                    widget.reviewId,
                    _currentUserId,
                  ),
                  builder: (context, userSnapshot) { // Xử lý trạng thái map
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) { // Đang xử lý
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData) { // Lỗi
                      return const Center(
                        child: Text('Lỗi hiển thị dữ liệu bình luận.'),
                      );
                    }

                    final comments = userSnapshot.data!; // List model hoàn chỉnh

                    // Sử dụng Widget mới
                    return ListView.builder( // Hiển thị danh sách
                      padding: const EdgeInsets.only(top: 8, bottom: 8), // Padding
                      itemCount: comments.length, // Số lượng
                      itemBuilder: (context, index) { // Xây dựng từng item
                        return CommentItem( // Widget comment
                          comment: comments[index],
                          onLike: () => _toggleCommentLike(comments[index]), // Thích
                          onReply: () => _startReplyToUser(comments[index]), // Trả lời
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Sử dụng Widget mới
          CommentInputBar( // Thanh nhập
            controller: _commentController,
            focusNode: _commentFocus,
            isSending: _isSending,
            replyingToComment: _replyingToComment,
            onSend: _sendComment, // Gửi
            onCancelReply: _cancelReply, // Hủy reply
          ),
        ],
      ),
    );
  }
}