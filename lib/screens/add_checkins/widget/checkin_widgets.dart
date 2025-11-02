// File: screens/checkin/widget/checkin_widgets.dart

import 'dart:io'; // Import `dart:io` để dùng `File` (cho `Image.file`)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Import `XFile`

// Màu sắc (lấy từ file gốc)
const Color kAppbarColor = Color(0xFFE4C99E);
const Color kBorderColor = Color(0xFFE4C99E);
const Color kFillColor = Color(0xFFFFF9F2);

// === WIDGET 1: HIỂN THỊ ẢNH ===
// `StatelessWidget`: Vì nó không tự thay đổi. Nó chỉ hiển thị
// dữ liệu (`selectedImages`) được truyền từ `CheckinScreen`.
// Khi `CheckinScreen` gọi `setState` và truyền `selectedImages` mới
// vào, `StatelessWidget` này sẽ tự động được `build` lại.
class ImageSection extends StatelessWidget {
  // `final` vì thuộc tính của Widget là bất biến
  final List<XFile> selectedImages;
  final int maxImages;

  // `VoidCallback`: Một kiểu dữ liệu (function type) cho một hàm
  // không nhận tham số và không trả về gì.
  // Dùng cho `onAddImage`.
  final VoidCallback onAddImage;

  // `Function(XFile)`: Một kiểu dữ liệu cho một hàm nhận vào
  // một `XFile` và không trả về gì.
  // Dùng cho `onRemoveImage`.
  final Function(XFile) onRemoveImage;

  const ImageSection({
    Key? key,
    required this.selectedImages,
    required this.maxImages,
    required this.onAddImage,
    required this.onRemoveImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // Hiển thị số lượng ảnh
          'Ảnh nổi bật (${selectedImages.length}/$maxImages)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        // **Logic hiển thị:**
        // Nếu danh sách rỗng -> hiển thị nút "Add" lớn.
        // Nếu không rỗng -> hiển thị hàng ngang các ảnh.
        selectedImages.isEmpty
            ? _buildAddImageButton(context)
            : _buildImageRow(context),
      ],
    );
  }

  // Hàm private để vẽ nút "Add" lớn
  Widget _buildAddImageButton(BuildContext context) {
    return InkWell(
      // `InkWell` để tạo hiệu ứng "splash" khi bấm
      onTap:
          onAddImage, // Khi bấm -> gọi callback (hàm `_showImageSourceDialog` của CheckinScreen)
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        decoration: BoxDecoration(
          color: kFillColor,
          border: Border.all(color: kBorderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.black54,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm ảnh/bài viết (tối đa $maxImages)',
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm private để vẽ hàng ngang (Nút "Add" nhỏ + ListView ảnh)
  Widget _buildImageRow(BuildContext context) {
    return SizedBox(
      height: 100, // Cố định chiều cao của hàng
      child: Row(
        children: [
          // 1. Nút "Add" nhỏ (chỉ hiển thị nếu chưa đạt max)
          if (selectedImages.length < maxImages)
            InkWell(
              onTap: onAddImage, // Gọi callback `_showImageSourceDialog`
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.grey),
                    Text(
                      'Thêm ảnh',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                    Text(
                      '(${selectedImages.length}/$maxImages)', // Hiển thị số lượng
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          // 2. Danh sách ảnh đã chọn
          Expanded(
            // `Expanded`: Chiếm hết phần không gian còn lại trong `Row`
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // Cuộn ngang
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                final imgFile = selectedImages[index];

                // Trả về widget `ImageItem`
                return ImageItem(
                  imageFile: imgFile,
                  // Truyền callback `onRemove` vào `ImageItem`.
                  // Khi `ImageItem` gọi `onRemove`, nó sẽ kích hoạt
                  // `onRemoveImage(imgFile)` của `ImageSection`,
                  // và `onRemoveImage(imgFile)` này lại kích hoạt
                  // hàm `setState` bên trong `CheckinScreen`.
                  // Đây gọi là "lifting state up" hoặc "callback chaining".
                  onRemove: () => onRemoveImage(imgFile),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// === WIDGET 1.1: THUMBNAIL ẢNH ===
// Widget `StatelessWidget` con, chỉ để hiển thị 1 ảnh thumbnail.
class ImageItem extends StatelessWidget {
  final XFile imageFile;
  final VoidCallback onRemove; // Nhận callback xóa

  const ImageItem({Key? key, required this.imageFile, required this.onRemove})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // `Stack`: Dùng để chồng các widget lên nhau (ảnh ở dưới, nút 'X' ở trên).
    return Stack(
      clipBehavior: Clip.none, // Cho phép nút 'X' tràn ra ngoài
      children: [
        // Lớp 1: Ảnh
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ClipRRect(
            // Cắt bo góc
            borderRadius: BorderRadius.circular(8),
            // `Image.file`: Widget để hiển thị ảnh từ một `File` trong
            // hệ thống.
            // `File(imageFile.path)`: Chuyển đổi `XFile` -> `String` (path) -> `File`.
            child: Image.file(
              File(imageFile.path),
              width: 100,
              height: 100,
              fit: BoxFit.cover, // Đảm bảo ảnh lấp đầy 100x100 (có thể bị cắt)
              // `errorBuilder`: Hiển thị nếu file ảnh bị lỗi
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                ),
              ),
            ),
          ),
        ),
        // Lớp 2: Nút 'X'
        Positioned(
          // Đặt vị trí chính xác
          right: 4, // Cách lề phải 4 (của Stack)
          top: 4, // Cách lề trên 4
          child: InkWell(
            onTap: onRemove, // Gọi callback `onRemove` khi bấm
            child: const CircleAvatar(
              // Nút 'X' hình tròn
              radius: 10,
              backgroundColor: Colors.black54, // Nền đen mờ
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// === WIDGET 2: NỘI DUNG HÀNH TRÌNH (TITLE, COMMENT) ===
class JourneyContentSection extends StatelessWidget {
  // Nhận vào các `TextEditingController` từ `CheckinScreen`.
  final TextEditingController titleController;
  final TextEditingController commentController;

  const JourneyContentSection({
    Key? key,
    required this.titleController,
    required this.commentController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Câu chuyện hành trình',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kFillColor,
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: titleController, // Gắn controller
            decoration: const InputDecoration(
              hintText: 'Tiêu đề chuyến đi',
              border: InputBorder.none, // Bỏ đường gạch chân (underline)
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kFillColor,
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: commentController, // Gắn controller
            maxLines: 5, // Cho phép nhập 5 dòng
            decoration: const InputDecoration(
              hintText: 'Chia sẻ về hành trình của bạn...',
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

// === WIDGET 3: CHỌN ĐỊA ĐIỂM ===
class PlaceSection extends StatelessWidget {
  // `DocumentSnapshot?` (nullable): Nhận địa điểm đã chọn (hoặc null).
  final DocumentSnapshot? selectedPlaceDoc;
  final bool isLoadingPlace; // Nhận trạng thái loading
  final VoidCallback onShowMiniMap; // Callback để mở map
  final VoidCallback onClearPlace; // Callback để xóa địa điểm

  const PlaceSection({
    Key? key,
    this.selectedPlaceDoc,
    required this.isLoadingPlace,
    required this.onShowMiniMap,
    required this.onClearPlace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String placeName = 'Chưa chọn địa điểm';
    String placeAddress = '';

    // Kiểm tra xem `selectedPlaceDoc` có phải là `null` hay không.
    bool hasSelectedPlace = selectedPlaceDoc != null;

    // Nếu đang tải (ví dụ: khi mới mở màn hình với initialPlaceId)
    // -> hiển thị vòng quay và dừng lại (return).
    if (isLoadingPlace) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Nếu đã chọn địa điểm (không null) -> trích xuất dữ liệu
    if (hasSelectedPlace) {
      // `!`: Dùng "null assertion" vì đã kiểm tra `hasSelectedPlace`
      final data = selectedPlaceDoc!.data() as Map<String, dynamic>? ?? {};
      placeName = data['name'] ?? 'Địa điểm không tên';
      final location = data['location'] as Map<String, dynamic>? ?? {};

      // Logic lấy địa chỉ: Ưu tiên 'fullAddress'
      placeAddress = location['fullAddress']?.isNotEmpty == true
          ? location['fullAddress']
          : '${location['street'] ?? ''}, ${location['city'] ?? ''}'
                .replaceAll(RegExp(r'^, |, $'), '') // Xóa dấu phẩy thừa
                .trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vị trí du lịch',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: kFillColor,
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                // Đổi màu Icon dựa trên trạng thái `hasSelectedPlace`
                color: hasSelectedPlace ? Colors.orange : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  // Làm cho khu vực text có thể bấm được
                  onTap: onShowMiniMap, // Gọi callback `_showMiniMapPicker`
                  child: Container(
                    color: Colors.transparent, // Đảm bảo bắt "tap" cả vùng
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placeName,
                          style: TextStyle(
                            // Đổi style text dựa trên trạng thái
                            fontWeight: hasSelectedPlace
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 15,
                            color: hasSelectedPlace
                                ? Colors.black87
                                : Colors.orange, // Màu cam nếu chưa chọn
                          ),
                        ),
                        // Chỉ hiển thị địa chỉ nếu `placeAddress` không rỗng
                        if (placeAddress.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              placeAddress,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            // Đổi text hướng dẫn dựa trên trạng thái
                            hasSelectedPlace
                                ? 'Chạm để thay đổi địa điểm'
                                : 'Chạm để chọn địa điểm từ bản đồ',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Nút 'X' (Xóa địa điểm)
              // Chỉ hiển thị nếu `hasSelectedPlace` là true
              if (hasSelectedPlace)
                InkWell(
                  onTap:
                      onClearPlace, // Gọi callback `setState(() => _selectedPlaceDoc = null)`
                  borderRadius: BorderRadius.circular(15),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, size: 20, color: Colors.black54),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// === WIDGET 4: HASHTAG ===
class HashtagSection extends StatelessWidget {
  final List<String> hashtags;
  final List<String> suggestedTags;
  final TextEditingController hashtagController;
  final VoidCallback onAddHashtag; // Callback `_addHashtag`
  final Function(String) onRemoveHashtag; // Callback `_removeHashtag`
  final Function(String) onAddSuggestedTag; // Callback `_addSuggestedTag`

  const HashtagSection({
    Key? key,
    required this.hashtags,
    required this.suggestedTags,
    required this.hashtagController,
    required this.onAddHashtag,
    required this.onRemoveHashtag,
    required this.onAddSuggestedTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Biến `bool` cục bộ để kiểm soát logic
    bool canAddMore = hashtags.length < 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hashtag',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        // `Wrap`: Một widget rất hay. Nó hoạt động giống `Row` (sắp xếp
        // các `Chip` theo chiều ngang), nhưng khi hết chỗ, nó sẽ
        // tự động "ngắt" xuống dòng mới (thay vì báo lỗi overflow).
        Wrap(
          spacing: 8.0, // Khoảng cách ngang giữa các Chip
          runSpacing: 4.0, // Khoảng cách dọc giữa các hàng (nếu có ngắt dòng)
          children: hashtags
              .map(
                // 1. Lặp qua danh sách `hashtags`
                (tag) => Chip(
                  // 2. Biến mỗi `String` thành một `Chip` widget
                  label: Text(
                    tag,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  backgroundColor: Colors.grey[200],
                  deleteIcon: const Icon(Icons.close, size: 16),
                  // Khi bấm nút xóa của Chip...
                  onDeleted: () =>
                      onRemoveHashtag(tag), // ...gọi callback `_removeHashtag`
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  deleteIconColor: Colors.grey[600],
                ),
              )
              .toList(), // 3. Chuyển kết quả `map` thành `List<Widget>`
        ),
        const SizedBox(height: 8),
        // `Wrap` thứ 2: Dành cho các tag gợi ý
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: suggestedTags.map((tag) {
            // Kiểm tra xem tag gợi ý này đã được chọn (nằm trong list) chưa
            bool isSelected = hashtags.contains(tag);

            // `ActionChip`: Một loại Chip được thiết kế để thực hiện hành động
            return ActionChip(
              label: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  // Đổi màu text dựa trên `isSelected`
                  color: isSelected ? Colors.grey : Colors.blue[700],
                ),
              ),
              backgroundColor: isSelected ? Colors.grey[300] : Colors.blue[50],

              // Vô hiệu hóa nút nếu `isSelected` là true
              onPressed: isSelected ? null : () => onAddSuggestedTag(tag),

              tooltip: isSelected ? 'Đã chọn' : 'Thêm hashtag này',
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Ô nhập hashtag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kFillColor,
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: hashtagController,
                  decoration: InputDecoration(
                    hintText:
                        canAddMore // Đổi hint text
                        ? 'Thêm hashtag...'
                        : 'Đã đủ 5 hashtag',
                    border: InputBorder.none,
                    counterText:
                        '${hashtags.length}/5 hashtag', // Hiển thị bộ đếm
                  ),
                  enabled: canAddMore, // Vô hiệu hóa TextField nếu đã đủ 5
                  // Khi người dùng bấm "Enter" / "Done" trên bàn phím
                  onSubmitted: (_) => onAddHashtag(),
                ),
              ),
              TextButton(
                // Vô hiệu hóa nút "Thêm" nếu không thể thêm
                onPressed: canAddMore ? onAddHashtag : null,
                child: Text(
                  'Thêm',
                  style: TextStyle(
                    color: canAddMore
                        ? Colors.orange
                        : Colors.grey, // Đổi màu nút
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// === WIDGET 5: QUYỀN RIÊNG TƯ ===
class PrivacySection extends StatelessWidget {
  final VoidCallback onTap; // Callback khi người dùng bấm
  const PrivacySection({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hiện tại đang hardcode (cố định) giá trị
    String privacySetting = 'Công khai';
    IconData privacyIcon = Icons.public;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quyền riêng tư',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        InkWell(
          // Widget để bắt sự kiện "tap"
          onTap: onTap, // Gọi callback (hiển thị SnackBar "chưa cài đặt")
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: kFillColor,
              border: Border.all(color: kBorderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Đẩy 2 bên ra xa
              children: [
                // Bên trái: Icon + Text
                Row(
                  children: [
                    Icon(privacyIcon, color: Colors.black54, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      privacySetting,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                // Bên phải: Icon mũi tên
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
