import 'package:flutter/material.dart';
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/service/album_service.dart'
    show AlbumService;
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/widgets/album_tab_content/album_summary_card.dart'
    show AlbumSummaryCard;
import 'package:nhom_3_damh_lttbdd/screens/personal_profile/widgets/album_tab_content/photo_grid_section.dart'
    show PhotoGridSection;

class AlbumTabContent extends StatefulWidget {
  final String userId;
  const AlbumTabContent({super.key, required this.userId});

  @override
  State<AlbumTabContent> createState() => _AlbumTabContentState();
}

class _AlbumTabContentState extends State<AlbumTabContent> {
  final AlbumService _service = AlbumService();
  bool _loading = true;
  List<String> _photos = [];
  int _albums = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _service.fetchUserAlbums(widget.userId);
      setState(() {
        _photos = List<String>.from(data['photos']);
        _albums = data['albumCount'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlbumSummaryCard(totalAlbums: _albums, totalPhotos: _photos.length),
          const SizedBox(height: 24),
          PhotoGridSection(photos: _photos),
        ],
      ),
    );
  }
}
