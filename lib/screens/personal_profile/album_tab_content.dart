import 'package:flutter/material.dart';
// Chỉ import class AlbumService để tránh import thừa
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/service/album_service.dart'
    show AlbumService;
// Import widget hiển thị thông tin tổng quan của album
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/widgets/album_tab_content/album_summary_card.dart'
    show AlbumSummaryCard;
// Import widget hiển thị lưới ảnh
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/widgets/album_tab_content/photo_grid_section.dart'
    show PhotoGridSection;

// Widget chính cho tab Album trong Profile
class AlbumTabContent extends StatefulWidget {
  final String userId; // ID của user mà tab này sẽ hiển thị album

  const AlbumTabContent({super.key, required this.userId});

  @override
  State<AlbumTabContent> createState() => _AlbumTabContentState();
}

class _AlbumTabContentState extends State<AlbumTabContent> {
  final AlbumService _service = AlbumService(); // Service xử lý dữ liệu album
  bool _loading = true; // Trạng thái loading khi lấy dữ liệu
  List<String> _photos = []; // Danh sách URL ảnh
  int _albums = 0; // Tổng số album

  @override
  void initState() {
    super.initState();
    _loadData(); // Gọi hàm tải dữ liệu ngay khi widget được khởi tạo
  }

  // Hàm bất đồng bộ tải dữ liệu album và ảnh từ Firestore
  Future<void> _loadData() async {
    try {
      final data = await _service.fetchUserAlbums(widget.userId);
      setState(() {
        // Chuyển dữ liệu về dạng list String và số lượng album
        _photos = List<String>.from(data['photos']);
        _albums = data['albumCount'];
        _loading = false; // Tắt trạng thái loading
      });
    } catch (e) {
      // Nếu có lỗi, vẫn tắt loading nhưng không crash app
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị loading spinner nếu dữ liệu chưa có
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    // Nếu đã tải xong, hiển thị nội dung chính
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Widget hiển thị tổng số album và ảnh
          AlbumSummaryCard(totalAlbums: _albums, totalPhotos: _photos.length),
          const SizedBox(height: 24),
          // Widget hiển thị lưới các ảnh
          PhotoGridSection(photos: _photos),
        ],
      ),
    );
  }
}
