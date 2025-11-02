import 'package:flutter/material.dart';
import '/model/comment_model.dart';

/// Widget nhập bình luận hoặc phản hồi comment
class CommentInput extends StatelessWidget {
  /// Controller cho TextField
  final TextEditingController controller;

  /// FocusNode để điều khiển focus TextField
  final FocusNode focusNode;

  /// Nếu đang trả lời một comment, giữ thông tin comment đó
  final CommentModel? replyingTo;

  /// Trạng thái gửi comment (đang loading)
  final bool isSending;

  /// Callback khi nhấn gửi
  final VoidCallback onSend;

  /// Callback khi hủy trả lời
  final VoidCallback onCancelReply;

  const CommentInput({
    Key? key,
    required this.controller,
    required this.focusNode,
    this.replyingTo,
    required this.isSending,
    required this.onSend,
    required this.onCancelReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding và background
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị dòng thông báo nếu đang trả lời comment
            if (replyingTo != null) _buildReplyIndicator(context),

            // Hàng input chính
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      // Hint text thay đổi khi đang trả lời
                      hintText: replyingTo != null
                          ? 'Viết phản hồi...'
                          : 'Viết bình luận...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    // Gửi khi nhấn Enter
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),

                // Nút gửi hoặc loading
                isSending
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: onSend,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget hiển thị thông báo đang trả lời comment
  Widget _buildReplyIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Hiển thị tên người đang trả lời
          Expanded(
            child: Text(
              'Trả lời ${replyingTo!.author.name}',
              style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
              overflow: TextOverflow.ellipsis, // cắt chữ nếu quá dài
            ),
          ),

          // Nút hủy trả lời
          InkWell(
            onTap: onCancelReply,
            child: Icon(Icons.close, size: 16, color: Colors.blue.shade800),
          ),
        ],
      ),
    );
  }
}
