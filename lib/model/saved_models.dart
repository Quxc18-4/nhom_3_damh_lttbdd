import 'package:cloud_firestore/cloud_firestore.dart';

enum SavedCategory { all, review, place }

String categoryToVietnamese(SavedCategory category) {
  switch (category) {
    case SavedCategory.all:
      return 'Tất cả';
    case SavedCategory.place:
      return 'Địa điểm';
    case SavedCategory.review:
      return 'Bài viết';
  }
}

class SavedItemsData {
  final int totalCount;
  final List<SavedItem> items;

  SavedItemsData({required this.totalCount, required this.items});
}

class SavedItem {
  final String id;
  final String contentId;
  final String title;
  final String subtitle;
  final SavedCategory category;
  final String imageUrl;
  final String authorOrRating;
  final String location;
  final DocumentSnapshot bookmarkDoc;

  SavedItem({
    required this.id,
    required this.contentId,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.imageUrl,
    required this.authorOrRating,
    required this.location,
    required this.bookmarkDoc,
  });

  factory SavedItem.fromBookmarkDoc(
    DocumentSnapshot bookmarkDoc, {
    required String contentId,
    required String title,
    required String subtitle,
    required SavedCategory category,
    required String imageUrl,
    required String authorOrRating,
    required String location,
  }) {
    return SavedItem(
      id: bookmarkDoc.id,
      contentId: contentId,
      title: title,
      subtitle: subtitle,
      category: category,
      imageUrl: imageUrl,
      authorOrRating: authorOrRating,
      location: location,
      bookmarkDoc: bookmarkDoc,
    );
  }
}

class Album {
  final String id;
  final String title;
  final String? description;
  final String coverImageUrl;
  final int reviewCount;

  Album({
    required this.id,
    required this.title,
    this.description,
    required this.coverImageUrl,
    this.reviewCount = 0,
  });

  factory Album.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String? cover;
    if (data.containsKey('photos') &&
        data['photos'] is List &&
        (data['photos'] as List).isNotEmpty) {
      cover = (data['photos'] as List).first as String?;
    }

    return Album(
      id: doc.id,
      title: data['title'] ?? 'Không có tiêu đề',
      description: data['description'],
      coverImageUrl:
          cover ?? 'https://via.placeholder.com/180x180.png?text=No+Cover',
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  Album copyWith({int? reviewCount, String? coverImageUrl}) {
    return Album(
      id: this.id,
      title: this.title,
      description: this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
