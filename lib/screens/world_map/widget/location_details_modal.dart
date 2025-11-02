// File: screens/world_map/widget/location_details_modal.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
// import 'package:nhom_3_damh_lttbdd/screens/addPlaceRequest.dart';
// import 'package:nhom_3_damh_lttbdd/screens/checkinScreen.dart';

// Import widget PhotoGrid
import 'photo_grid.dart';

/// Nội dung của Bottom Sheet chi tiết địa điểm.
class LocationDetailsModal extends StatelessWidget {
  final LatLng position;
  final DocumentSnapshot? existingPlace;
  final String userId;

  // Hàm Future lấy tên đường (truyền từ service)
  final Future<String> Function(LatLng) getStreetAndCity;

  // Callbacks cho các nút
  final VoidCallback onSaveLocation;
  final VoidCallback onAddPlace;
  final Function(String) onWriteReview; // Truyền vào placeId

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
    // Xác định trạng thái và lấy dữ liệu
    final bool isNewPlace = existingPlace == null;
    final Map<String, dynamic>? placeData = !isNewPlace
        ? existingPlace!.data() as Map<String, dynamic>
        : null;
    final String? placeName = !isNewPlace
        ? placeData!['name'] as String?
        : null;
    final List<dynamic> images = !isNewPlace
        ? (placeData!['images'] ?? [])
        : [];
    final String? placeId = !isNewPlace ? existingPlace!.id : null;

    // Chuyển đổi an toàn List<dynamic> sang List<String> cho PhotoGrid
    final List<String> imageUrls = images.whereType<String>().toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh kéo
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cột 1: Tên địa điểm
              Expanded(
                flex: 3,
                child: FutureBuilder<String>(
                  future: isNewPlace
                      ? getStreetAndCity(position) // Gọi hàm future
                      : Future.value(placeName ?? 'Địa điểm'),
                  builder: (context, titleSnapshot) {
                    return Text(
                      titleSnapshot.data ??
                          (isNewPlace
                              ? 'Vị trí chưa khám phá'
                              : 'Đang tải tên...'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Cột 2: Các nút Icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút Thêm mới
                  if (isNewPlace)
                    _buildIconSheetButton(
                      icon: Icons.add_location_alt_outlined,
                      label: 'Thêm mới',
                      color: Colors.blue,
                      onTap: onAddPlace, // Gọi callback
                    ),
                  if (isNewPlace) const SizedBox(width: 8),

                  // Nút Lưu cá nhân
                  _buildIconSheetButton(
                    icon: Icons.bookmark_add_outlined,
                    label: 'Lưu cá nhân',
                    color: Colors.teal,
                    onTap: onSaveLocation, // Gọi callback
                  ),

                  // Nút Đăng Review
                  if (!isNewPlace && placeId != null) ...[
                    const SizedBox(width: 8),
                    _buildIconSheetButton(
                      icon: Icons.rate_review_outlined,
                      label: 'Viết Review',
                      color: Colors.orange,
                      onTap: () => onWriteReview(placeId), // Gọi callback
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
          // SỬ DỤNG WIDGET MỚI
          PhotoGrid(imageUrls: imageUrls),
          const SizedBox(height: 24),

          // === DÒNG 3: NÚT ĐĂNG BÀI REVIEW (Dạng viên thuốc) ===
          if (!isNewPlace && placeId != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onWriteReview(placeId), // Gọi callback
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Đăng bài review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Helper vẽ nút Icon (private trong file này)
  Widget _buildIconSheetButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
