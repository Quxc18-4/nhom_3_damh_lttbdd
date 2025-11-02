// File: screens/comment/widget/comment_input_bar.dart

import 'package:flutter/material.dart'; // Thư viện chính của Flutter để xây dựng UI
import 'package:nhom_3_damh_lttbdd/model/comment_model.dart'; // Model CommentModel để biết đang trả lời ai

class CommentInputBar extends StatelessWidget { // Widget thanh nhập bình luận (gửi comment hoặc reply)
  final TextEditingController controller; // Controller quản lý nội dung người dùng nhập
  final FocusNode focusNode; // FocusNode để điều khiển bàn phím (mở/đóng, focus)
  final bool isSending; // Trạng thái đang gửi comment (hiển thị loading)
  final CommentModel? replyingToComment; // Bình luận đang trả lời (nếu có) → null nếu là comment mới
  final VoidCallback onSend; // Hàm gọi khi người dùng nhấn gửi (icon hoặc Enter)
  final VoidCallback onCancelReply; // Hàm gọi khi người dùng hủy trả lời (nhấn nút x)

  const CommentInputBar({ // Constructor nhận các tham số bắt buộc
    Key? key,
    required this.controller, // Bắt buộc
    required this.focusNode,
    required this.isSending,
    this.replyingToComment, // Tùy chọn (null nếu không trả lời)
    required this.onSend,
    required this.onCancelReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện thanh nhập
    final viewInsets = MediaQuery.of(context).viewInsets.bottom; // Lấy chiều cao bàn phím (khi mở)

    return Container( // Khung bao bọc toàn bộ thanh nhập
      padding: EdgeInsets.only( // Padding: trái-phải 16dp, trên 8dp, dưới 8dp + bàn phím
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + viewInsets, // Đẩy thanh lên khi bàn phím hiện
      ),
      decoration: BoxDecoration( // Trang trí khung
        color: Colors.white, // Nền trắng
        border: Border(top: BorderSide(color: Colors.grey.shade200)), // Viền trên xám nhạt
      ),
      child: Column( // Cột dọc: trạng thái trả lời + ô nhập + nút gửi
        mainAxisSize: MainAxisSize.min, // Chỉ chiếm không gian cần thiết
        crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
        children: [
          // Hiển thị trạng thái đang trả lời
          if (replyingToComment != null) // Nếu đang trả lời một bình luận
            Container( // Khung nhỏ hiển thị "Trả lời @Tên"
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Padding trong khung
              decoration: BoxDecoration( // Trang trí
                color: Colors.blue.shade50, // Nền xanh nhạt
                borderRadius: BorderRadius.circular(8), // Bo góc
              ),
              child: Row( // Dòng ngang: text + nút x
                children: [
                  Expanded( // Văn bản chiếm hết chỗ
                    child: Text(
                      'Trả lời ${replyingToComment!.author.name}', // Hiển thị tên người đang trả lời
                      style: TextStyle(
                        color: Colors.blue.shade800, // Màu xanh đậm
                        fontSize: 13, // Cỡ chữ nhỏ
                      ),
                      overflow: TextOverflow.ellipsis, // Cắt nếu quá dài
                    ),
                  ),
                  InkWell( // Vùng nhấn để hủy trả lời
                    onTap: onCancelReply, // Gọi hàm hủy
                    child: Icon(
                      Icons.close, // Icon chữ X
                      size: 16, // Nhỏ
                      color: Colors.blue.shade800, // Màu xanh đậm
                    ),
                  ),
                ],
              ),
            ),
          if (replyingToComment != null) const SizedBox(height: 8), // Khoảng cách nếu có trạng thái trả lời

          Row( // Dòng chính: ô nhập + nút gửi
            children: [
              Expanded( // Ô nhập chiếm phần lớn
                child: TextField( // Ô nhập liệu
                  controller: controller, // Gắn controller
                  focusNode: focusNode, // Gắn focus
                  minLines: 1, // Tối thiểu 1 dòng
                  maxLines: 4, // Tối đa 4 dòng (tự mở rộng)
                  decoration: InputDecoration( // Trang trí ô nhập
                    hintText: replyingToComment != null // Gợi ý tùy theo trạng thái
                        ? 'Viết phản hồi...'
                        : 'Viết bình luận...',
                    contentPadding: const EdgeInsets.symmetric( // Padding trong ô
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder( // Viền
                      borderRadius: BorderRadius.circular(20), // Bo góc tròn
                      borderSide: BorderSide(color: Colors.grey.shade300), // Màu viền xám
                    ),
                  ),
                  onSubmitted: (_) => onSend(), // Gửi khi nhấn Enter (bàn phím)
                ),
              ),
              const SizedBox(width: 8), // Khoảng cách giữa ô nhập và nút gửi
              isSending // Nếu đang gửi
                  ? const SizedBox( // Hiển thị loading
                      width: 32, // Kích thước nhỏ
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2), // Vòng tròn mỏng
                    )
                  : IconButton( // Nếu không gửi → hiển thị icon gửi
                      icon: const Icon(Icons.send, color: Colors.blue), // Icon máy bay giấy
                      onPressed: onSend, // Gọi hàm gửi khi nhấn
                    ),
            ],
          ),
        ],
      ),
    );
  }
}