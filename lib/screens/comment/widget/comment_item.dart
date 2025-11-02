// File: screens/comment/widget/comment_item.dart

import 'package:flutter/material.dart'; // Thư viện chính Flutter để xây dựng UI
import 'package:intl/intl.dart'; // Định dạng ngày giờ (HH:mm, dd/MM)
import 'package:nhom_3_damh_lttbdd/model/comment_model.dart'; // Model CommentModel chứa dữ liệu bình luận

class CommentItem extends StatelessWidget { // Widget hiển thị một bình luận (comment hoặc reply)
  final CommentModel comment; // Dữ liệu bình luận: nội dung, tác giả, like, thời gian, v.v.
  final VoidCallback onLike; // Hàm gọi khi người dùng nhấn "Thích"
  final VoidCallback onReply; // Hàm gọi khi người dùng nhấn "Phản hồi"

  const CommentItem({ // Constructor nhận các tham số bắt buộc
    Key? key,
    required this.comment, // Bắt buộc: dữ liệu bình luận
    required this.onLike, // Bắt buộc: hành động khi thích
    required this.onReply, // Bắt buộc: hành động khi trả lời
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Xây dựng giao diện cho một comment
    final timeFormat = DateFormat('HH:mm, dd/MM'); // Định dạng thời gian: 14:30, 05/11

    return Padding( // Padding quanh comment: trái-phải 16dp, trên-dưới 10dp
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row( // Dòng ngang: avatar + nội dung
        crossAxisAlignment: CrossAxisAlignment.start, // Căn trên cùng (avatar và tên)
        children: [
          CircleAvatar( // Avatar người bình luận
            radius: 18, // Bán kính 18dp → đường kính 36dp
            backgroundImage: comment.author.avatarUrl.startsWith('http') // Kiểm tra là URL
                ? NetworkImage(comment.author.avatarUrl) // Tải ảnh từ mạng
                : AssetImage(comment.author.avatarUrl) as ImageProvider, // Dùng ảnh local
            backgroundColor: Colors.grey.shade200, // Nền xám nếu ảnh lỗi
          ),
          const SizedBox(width: 12), // Khoảng cách giữa avatar và nội dung

          Expanded( // Nội dung chiếm phần còn lại
            child: Column( // Cột dọc: tên + thời gian + nội dung + hành động
              crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
              children: [
                Row( // Dòng ngang: tên + thời gian
                  children: [
                    Text( // Tên người bình luận
                      comment.author.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, // In đậm
                        fontSize: 14, // Cỡ chữ 14
                      ),
                    ),
                    const SizedBox(width: 8), // Khoảng cách giữa tên và thời gian
                    Text( // Thời gian bình luận
                      timeFormat.format(comment.commentedAt), // Định dạng: HH:mm, dd/MM
                      style: TextStyle(
                        color: Colors.grey.shade500, // Màu xám
                        fontSize: 11, // Cỡ nhỏ
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // Khoảng cách giữa dòng tên và nội dung

                Text( // Nội dung bình luận
                  comment.content,
                  style: const TextStyle(fontSize: 15), // Cỡ chữ 15
                ),
                const SizedBox(height: 8), // Khoảng cách giữa nội dung và hành động

                Row( // Dòng ngang: nút Thích + nút Phản hồi
                  children: [
                    // Nút Thích
                    InkWell( // Vùng nhấn có hiệu ứng gợn sóng
                      onTap: onLike, // Gọi hàm khi nhấn
                      child: Row( // Dòng nhỏ: chữ "Thích" + số lượt thích
                        children: [
                          Text( // Chữ "Thích"
                            'Thích',
                            style: TextStyle(
                              color: comment.isLikedByUser // Nếu đã thích
                                  ? Colors.red.shade700 // Màu đỏ
                                  : Colors.blue.shade700, // Màu xanh
                              fontWeight: FontWeight.w500, // Chữ đậm nhẹ
                              fontSize: 12, // Cỡ nhỏ
                            ),
                          ),
                          if (comment.likeCount > 0) // Nếu có lượt thích
                            Padding( // Số lượt thích trong ngoặc
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                '(${comment.likeCount})', // Ví dụ: (5)
                                style: TextStyle(
                                  color: Colors.grey.shade600, // Màu xám đậm
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16), // Khoảng cách giữa "Thích" và "Phản hồi"

                    // Nút Phản hồi
                    InkWell( // Vùng nhấn
                      onTap: onReply, // Gọi hàm khi nhấn
                      child: Text( // Chữ "Phản hồi"
                        'Phản hồi',
                        style: TextStyle(
                          color: Colors.blue.shade700, // Màu xanh
                          fontWeight: FontWeight.w500, // Đậm nhẹ
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}