// File: screens/world_map/widget/location_details_modal.dart

import 'package:flutter/material.dart'; // Import thư viện Material
import 'package:cloud_firestore/cloud_firestore.dart'; // Import để dùng kiểu DocumentSnapshot
import 'package:latlong2/latlong.dart'; // Import để dùng kiểu LatLng
// (Các import điều hướng đã bị comment, vì logic điều hướng được xử lý
// thông qua callbacks, do WorldMapScreen quyết định)

// Import widget PhotoGrid
import 'photo_grid.dart'; // Import widget hiển thị grid ảnh

/// Nội dung của Bottom Sheet chi tiết địa điểm.
// Kiểu dữ liệu: StatelessWidget
// Mục đích: Định nghĩa UI cho modal. Widget này là "dumb" (ngu ngốc),
// nó chỉ hiển thị dữ liệu và gọi callbacks, không chứa logic nghiệp vụ.
class LocationDetailsModal extends StatelessWidget {
  // === DỮ LIỆU ĐẦU VÀO (INPUT) ===
  // Kiểu: LatLng. Tọa độ của điểm được chọn.
  final LatLng position;
  // Kiểu: DocumentSnapshot? (nullable). Dữ liệu của địa điểm (nếu là điểm đã có).
  // `null` nếu đây là 1 vị trí mới (nhấn giữ).
  final DocumentSnapshot? existingPlace;
  // Kiểu: String. ID người dùng.
  final String userId;

  // === DỊCH VỤ (TRUYỀN TỪ CHA) ===
  // Kiểu: Function (1 hàm nhận LatLng, trả về Future<String>).
  // Mục đích: Cho phép modal này gọi hàm `getStreetAndCity` từ service
  // mà không cần import service.
  final Future<String> Function(LatLng) getStreetAndCity;

  // === CALLBACKS (OUTPUT) ===
  // Kiểu: VoidCallback (hàm không tham số).
  // Luồng dữ liệu: Được gọi khi bấm nút "Lưu cá nhân".
  final VoidCallback onSaveLocation;
  // Kiểu: VoidCallback (hàm không tham số).
  // Luồng dữ liệu: Được gọi khi bấm nút "Thêm mới".
  final VoidCallback onAddPlace;
  // Kiểu: Function (hàm nhận 1 String là placeId).
  // Luồng dữ liệu: Được gọi khi bấm nút "Viết Review".
  final Function(String) onWriteReview;

  // Constructor
  const LocationDetailsModal({
    Key? key,
    required this.position,
    this.existingPlace,
    required this.userId,
    required this.getStreetAndCity,
    required this.onSaveLocation,
    required this.onAddPlace,
    required this.onWriteReview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- Xử lý dữ liệu đầu vào ---
    // Xác định trạng thái (mới hay cũ)
    final bool isNewPlace = existingPlace == null;
    // Lấy dữ liệu Map (nếu là địa điểm cũ)
    final Map<String, dynamic>? placeData = !isNewPlace
        ? existingPlace!.data() as Map<String, dynamic>
        : null;
    // Lấy tên (nếu là địa điểm cũ)
    final String? placeName = !isNewPlace
        ? placeData!['name'] as String?
        : null;
    // Lấy danh sách ảnh (nếu là địa điểm cũ), an toàn (null -> [])
    final List<dynamic> images = !isNewPlace
        ? (placeData!['images'] ?? [])
        : [];
    // Lấy ID (nếu là địa điểm cũ)
    final String? placeId = !isNewPlace ? existingPlace!.id : null;

    // Chuyển đổi an toàn List<dynamic> sang List<String> cho PhotoGrid
    // `whereType<String>()` lọc ra các phần tử là String
    final List<String> imageUrls = images.whereType<String>().toList();

    // --- Bắt đầu xây dựng UI ---
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), // Đệm
      constraints: BoxConstraints(
        // Giới hạn chiều cao tối đa (tránh tràn màn hình)
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Cột co lại vừa đủ nội dung
        crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
        children: [
          // Thanh kéo (chỉ báo visual cho bottom sheet)
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // === DÒNG 1: TÊN + NÚT ICON ===
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Căn giữa theo chiều dọc
            children: [
              // Cột 1: Tên địa điểm
              Expanded(
                flex: 3, // Chiếm 3 phần
                // `FutureBuilder` xử lý việc hiển thị UI trong khi chờ 1 Future
                child: FutureBuilder<String>(
                  // `future` là nguồn dữ liệu bất đồng bộ
                  future: isNewPlace
                      ? getStreetAndCity(
                          position,
                        ) // Nếu là mới: Gọi hàm geocoding
                      : Future.value(
                          placeName ?? 'Địa điểm',
                        ), // Nếu là cũ: Dùng tên có sẵn
                  // `builder` định nghĩa UI dựa trên trạng thái của future
                  builder: (context, titleSnapshot) {
                    return Text(
                      // `titleSnapshot.data` là kết quả khi future hoàn thành
                      titleSnapshot.data ?? // Nếu có data, dùng nó
                          (isNewPlace // Nếu chưa có data (đang tải)
                              ? 'Vị trí chưa khám phá'
                              : 'Đang tải tên...'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1, // 1 dòng
                      overflow: TextOverflow.ellipsis, // Dấu "..." nếu quá dài
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Cột 2: Các nút Icon
              Row(
                mainAxisSize: MainAxisSize.min, // Co lại vừa đủ
                children: [
                  // Nút Thêm mới
                  if (isNewPlace) // Chỉ hiện khi là địa điểm mới
                    _buildIconSheetButton(
                      icon: Icons.add_location_alt_outlined,
                      label: 'Thêm mới',
                      color: Colors.blue,
                      onTap: onAddPlace, // Gọi callback `onAddPlace`
                    ),
                  if (isNewPlace) const SizedBox(width: 8),

                  // Nút Lưu cá nhân (luôn hiện)
                  _buildIconSheetButton(
                    icon: Icons.bookmark_add_outlined,
                    label: 'Lưu cá nhân',
                    color: Colors.teal,
                    onTap: onSaveLocation, // Gọi callback `onSaveLocation`
                  ),

                  // Nút Đăng Review
                  if (!isNewPlace && placeId != null) ...[
                    // Chỉ hiện khi là điểm cũ (có ID)
                    const SizedBox(width: 8),
                    _buildIconSheetButton(
                      icon: Icons.rate_review_outlined,
                      label: 'Viết Review',
                      color: Colors.orange,
                      onTap: () => onWriteReview(
                        placeId,
                      ), // Gọi callback `onWriteReview`
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // === DÒNG 2: ẢNH ===
          Text(
            'Ảnh',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // SỬ DỤNG WIDGET MỚI (đã refactor)
          // Truyền danh sách URL đã được xử lý an toàn
          PhotoGrid(imageUrls: imageUrls),
          const SizedBox(height: 24),

          // === DÒNG 3: NÚT ĐĂNG BÀI REVIEW (Dạng viên thuốc) ===
          if (!isNewPlace && placeId != null) // Chỉ hiện khi là điểm cũ (có ID)
            SizedBox(
              width: double.infinity, // Nút rộng hết cỡ
              child: ElevatedButton.icon(
                onPressed: () => onWriteReview(placeId), // Gọi callback
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Đăng bài review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Nền
                  foregroundColor: Colors.white, // Chữ
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(), // Bo tròn (hình viên thuốc)
                ),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// Helper vẽ nút Icon (private trong file này)
  /// Đây là 1 *phương thức* trả về Widget.
  Widget _buildIconSheetButton({
    required IconData icon, // Icon
    required String label, // Nhãn (cho Tooltip)
    required Color color, // Màu
    required VoidCallback onTap, // Hàm callback
  }) {
    // `Tooltip` hiển thị `label` khi nhấn giữ
    return Tooltip(
      message: label,
      child: InkWell(
        // `InkWell` cung cấp hiệu ứng gợn sóng (ripple) khi bấm
        onTap: onTap,
        borderRadius: BorderRadius.circular(50), // Bo hiệu ứng
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15), // Nền mờ (màu)
            shape: BoxShape.circle, // Hình tròn
          ),
          child: Icon(icon, color: color, size: 24), // Icon (màu)
        ),
      ),
    );
  }
}
