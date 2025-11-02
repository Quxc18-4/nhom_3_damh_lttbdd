import 'package:cloud_firestore/cloud_firestore.dart';

class SavedReviewItem {
  final String reviewId;
  final String title;
  final String content;
  final String imageUrl;

  SavedReviewItem({
    required this.reviewId,
    required this.title,
    required this.content,
    required this.imageUrl,
  });

  factory SavedReviewItem.fromReviewDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedReviewItem(
      reviewId: doc.id,
      title: data['title'] ?? 'Không có tiêu đề',
      content: data['comment'] ?? '',
      imageUrl:
          (data['imageUrls'] != null && (data['imageUrls'] as List).isNotEmpty)
          ? data['imageUrls'][0]
          : 'https://via.placeholder.com/300x200.png?text=No+Image',
    );
  }
}

class AlbumData {
  final String description;
  final String? coverImageUrl;

  AlbumData({required this.description, this.coverImageUrl});

  factory AlbumData.fromFirestore(Map<String, dynamic> data) {
    return AlbumData(
      description: data['description'] ?? '',
      coverImageUrl: data['coverImageUrl'] as String?,
    );
  }
}
