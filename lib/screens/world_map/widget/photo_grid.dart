// File: screens/world_map/widget/photo_grid.dart

import 'package:flutter/material.dart'; // Import thư viện Material cơ bản của Flutter

/// Widget hiển thị grid ảnh, tự động điều chỉnh layout
/// dựa trên số lượng ảnh (1, 2, 3, hoặc 4+).
// Kiểu dữ liệu: StatelessWidget (Widget không có trạng thái nội tại)
// Mục đích: Tách biệt logic phức tạp của việc hiển thị grid ảnh ra khỏi modal
// (LocationDetailsModal), giúp code sạch sẽ và dễ bảo trì hơn.
class PhotoGrid extends StatelessWidget {
  // Kiểu dữ liệu: List<String> (danh sách các URL ảnh)
  // Luồng dữ liệu: Được truyền vào từ widget cha (LocationDetailsModal).
  // `final` nghĩa là nó không thể thay đổi sau khi widget được khởi tạo.
  final List<String> imageUrls;

  // Constructor (hàm khởi tạo) của widget.
  // Yêu cầu `imageUrls` phải được cung cấp khi tạo PhotoGrid.
  const PhotoGrid({Key? key, required this.imageUrls}) : super(key: key);

  @override
  // Hàm `build` định nghĩa cấu trúc UI của widget này.
  Widget build(BuildContext context) {
    // Lấy số lượng ảnh từ danh sách truyền vào.
    final int count = imageUrls.length;

    // --- TRƯỜNG HỢP 0: KHÔNG CÓ ẢNH ---
    if (count == 0) {
      // Nếu không có ảnh, trả về một "placeholder" (vùng giữ chỗ).
      return Container(
        height: 150, // Chiều cao cố định
        width: double.infinity, // Chiều rộng lấp đầy
        decoration: BoxDecoration(
          color: Colors.grey[200], // Nền xám nhạt
          borderRadius: BorderRadius.circular(12), // Bo góc
        ),
        child: Center(
          // Căn giữa nội dung
          child: Text(
            'Hãy là người đầu tiên khám phá ra vị trí này!',
            style: TextStyle(
              fontStyle: FontStyle.italic, // Chữ nghiêng
              color: Colors.grey[700], // Màu xám đậm
            ),
            textAlign: TextAlign.center, // Căn giữa văn bản
          ),
        ),
      );
    }

    // Chiều cao cố định cho toàn bộ grid ảnh, bất kể có bao nhiêu ảnh.
    const double totalHeight = 180;

    // --- TRƯỜNG HỢP 1: 1 ẢNH ---
    if (count == 1) {
      // Trả về một `SizedBox` để ràng buộc kích thước
      return SizedBox(
        height: totalHeight,
        width: double.infinity,
        // Gọi hàm helper `_buildImage` để hiển thị 1 ảnh duy nhất
        child: _buildImage(
          imageUrls[0], // URL của ảnh đầu tiên
          height: totalHeight,
          width: double.infinity,
          isTaller: true, // Flag cho StackFit
        ),
      );
    }

    // --- TRƯỜNG HỢP 2: 2 ẢNH ---
    if (count == 2) {
      return SizedBox(
        height: totalHeight,
        // Sử dụng `Row` để sắp xếp 2 ảnh cạnh nhau
        child: Row(
          children: [
            // `Expanded` để mỗi ảnh chiếm 1 phần không gian bằng nhau (flex: 1)
            Expanded(
              child: _buildImage(
                imageUrls[0], // Ảnh 1
                height: totalHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
            const SizedBox(width: 4), // Khoảng cách nhỏ giữa 2 ảnh
            Expanded(
              child: _buildImage(
                imageUrls[1], // Ảnh 2
                height: totalHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
          ],
        ),
      );
    }

    // --- TRƯỜNG HỢP 3: 3 ẢNH ---
    if (count == 3) {
      return SizedBox(
        height: totalHeight,
        child: Row(
          children: [
            // Ảnh 1 (bên trái, to hơn)
            Expanded(
              flex: 2, // Chiếm 2 phần không gian
              child: _buildImage(
                imageUrls[0],
                height: totalHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
            const SizedBox(width: 4), // Khoảng cách
            // Cột 2 (bên phải, chứa 2 ảnh nhỏ)
            Expanded(
              flex: 1, // Chiếm 1 phần không gian
              // Sử dụng `Column` để xếp 2 ảnh trên dưới
              child: Column(
                children: [
                  // Ảnh 2 (nửa trên)
                  Expanded(
                    child: _buildImage(
                      imageUrls[1],
                      height: double.infinity, // Lấp đầy 1/2 chiều cao cột
                      width: double.infinity, // Lấp đầy chiều rộng cột
                      isTaller: true,
                    ),
                  ),
                  const SizedBox(height: 4), // Khoảng cách
                  // Ảnh 3 (nửa dưới)
                  Expanded(
                    child: _buildImage(
                      imageUrls[2],
                      height: double.infinity, // Lấp đầy 1/2 chiều cao cột
                      width: double.infinity, // Lấp đầy chiều rộng cột
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

    // --- TRƯỜNG HỢP 4: 4+ ẢNH ---
    // (Bao gồm 4 ảnh, 5 ảnh, 6 ảnh, v.v.)
    // Tính số lượng ảnh còn lại (ngoài 4 ảnh được hiển thị)
    final int remainingCount = count - 4;
    return SizedBox(
      height: totalHeight,
      // Sử dụng `Column` để tạo 2 hàng ảnh
      child: Column(
        children: [
          // Hàng 1 (chứa 2 ảnh)
          Expanded(
            child: Row(
              children: [
                // Ảnh 1 (Hàng 1, Cột 1)
                Expanded(
                  child: _buildImage(
                    imageUrls[0],
                    height: double.infinity, // Lấp đầy 1/2 chiều cao
                    width: double.infinity, // Lấp đầy 1/2 chiều rộng
                    isTaller: true,
                  ),
                ),
                const SizedBox(width: 4),
                // Ảnh 2 (Hàng 1, Cột 2)
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
          const SizedBox(height: 4), // Khoảng cách giữa 2 hàng
          // Hàng 2 (chứa 2 ảnh)
          Expanded(
            child: Row(
              children: [
                // Ảnh 3 (Hàng 2, Cột 1)
                Expanded(
                  child: _buildImage(
                    imageUrls[2],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
                const SizedBox(width: 4),
                // Ảnh 4 (Hàng 2, Cột 2) - Ảnh này có thể có lớp phủ (overlay)
                Expanded(
                  child: _buildImage(
                    imageUrls[3],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                    // `overlay` là một widget được truyền vào `_buildImage`
                    // Nó sẽ được vẽ đè lên trên ảnh.
                    overlay:
                        remainingCount >
                            0 // Chỉ thêm overlay nếu có 5+ ảnh
                        ? Container(
                            // Lớp phủ màu đen mờ
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                '+$remainingCount', // Hiển thị số lượng "+X"
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : null, // Không có overlay nếu chỉ có 4 ảnh
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Phương thức Helper (private) để render một ảnh
  /// Nó chịu trách nhiệm bo góc, hiển thị loading, và xử lý lỗi.
  Widget _buildImage(
    String imageUrl, { // Tham số bắt buộc: URL của ảnh
    // Các tham số đặt tên (named parameters):
    required double height, // Chiều cao yêu cầu
    required double width, // Chiều rộng yêu cầu
    Widget? overlay, // Lớp phủ (nullable - có thể có hoặc không)
    bool isTaller = false, // Flag để set StackFit
  }) {
    // `ClipRRect` dùng để cắt widget con (Stack) theo hình chữ nhật bo góc.
    return ClipRRect(
      borderRadius: BorderRadius.circular(8), // Bo góc 8px
      // `Stack` cho phép các widget con đè lên nhau (ví dụ: ảnh và lớp overlay)
      child: Stack(
        // `fit` xác định cách các widget con (không có vị trí) trong Stack
        // lấp đầy không gian. `expand` bắt chúng lấp đầy.
        fit: isTaller ? StackFit.expand : StackFit.loose,
        children: [
          // Lớp 1: Ảnh
          // `Image.network` là widget của Flutter để tải và hiển thị ảnh từ URL.
          Image.network(
            imageUrl, // Nguồn ảnh
            height: height,
            width: width,
            // `fit: BoxFit.cover`: Phóng to/thu nhỏ và cắt ảnh
            // để lấp đầy không gian mà không làm méo ảnh.
            fit: BoxFit.cover,
            // `loadingBuilder` hiển thị 1 widget *trong khi* ảnh đang tải.
            loadingBuilder: (context, child, loadingProgress) {
              // `loadingProgress` là null khi tải xong.
              if (loadingProgress == null)
                return child; // Trả về `child` (chính là cái ảnh)
              // Nếu `loadingProgress` không null (đang tải), trả về 1 widget loading
              return Container(
                color: Colors.grey[200], // Nền xám
                height: height,
                width: width,
                child: Center(
                  child: CircularProgressIndicator(
                    // Hiển thị % đã tải nếu thông tin `expectedTotalBytes` có sẵn
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null, // Nếu không, hiển thị vòng xoay vô định
                    strokeWidth: 2, // Độ dày vòng xoay
                  ),
                ),
              );
            },
            // `errorBuilder` hiển thị 1 widget *nếu* tải ảnh bị lỗi
            // (ví dụ: URL hỏng, không có mạng).
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                height: height,
                width: width,
                child: const Center(
                  // Hiển thị icon lỗi
                  child: Icon(Icons.error_outline, color: Colors.red, size: 30),
                ),
              );
            },
          ),
          // Lớp 2: Lớp phủ (Overlay)
          // Chỉ vẽ widget này nếu `overlay` không null.
          if (overlay != null)
            overlay, // `overlay` là widget được truyền vào (ví dụ: Container "+X")
        ],
      ),
    );
  }
}
