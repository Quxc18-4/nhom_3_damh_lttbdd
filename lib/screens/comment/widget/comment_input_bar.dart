// File: screens/comment/widget/comment_input_bar.dart

import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/model/comment_model.dart';

class CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final CommentModel? replyingToComment;
  final VoidCallback onSend;
  final VoidCallback onCancelReply;

  const CommentInputBar({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.isSending,
    this.replyingToComment,
    required this.onSend,
    required this.onCancelReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + viewInsets,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị trạng thái đang trả lời
          if (replyingToComment != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Trả lời ${replyingToComment!.author.name}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: onCancelReply,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          if (replyingToComment != null) const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: replyingToComment != null
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
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
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
    );
  }
}
