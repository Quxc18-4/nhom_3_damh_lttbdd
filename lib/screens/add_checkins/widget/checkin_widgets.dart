// File: screens/checkin/widget/checkin_widgets.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

// Màu sắc (lấy từ file gốc)
const Color kAppbarColor = Color(0xFFE4C99E);
const Color kBorderColor = Color(0xFFE4C99E);
const Color kFillColor = Color(0xFFFFF9F2);

// === WIDGET 1: HIỂN THỊ ẢNH ===
class ImageSection extends StatelessWidget {
  final List<XFile> selectedImages;
  final int maxImages;
  final VoidCallback onAddImage;
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
          'Ảnh nổi bật (${selectedImages.length}/$maxImages)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        selectedImages.isEmpty
            ? _buildAddImageButton(context)
            : _buildImageRow(context),
      ],
    );
  }

  Widget _buildAddImageButton(BuildContext context) {
    return InkWell(
      onTap: onAddImage,
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

  Widget _buildImageRow(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Row(
        children: [
          if (selectedImages.length < maxImages)
            InkWell(
              onTap: onAddImage,
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
                      '(${selectedImages.length}/$maxImages)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                final imgFile = selectedImages[index];
                // Cần truyền callback onRemove từ state
                // Do widget này stateless, nên onRemove phải được truyền từ state
                // Tạm thời để trống:
                return ImageItem(
                  imageFile: imgFile,
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
class ImageItem extends StatelessWidget {
  final XFile imageFile;
  final VoidCallback onRemove;

  const ImageItem({Key? key, required this.imageFile, required this.onRemove})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imageFile.path),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
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
        Positioned(
          right: 4,
          top: 4,
          child: InkWell(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.black54,
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
            controller: titleController,
            decoration: const InputDecoration(
              hintText: 'Tiêu đề chuyến đi',
              border: InputBorder.none,
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
            controller: commentController,
            maxLines: 5,
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
  final DocumentSnapshot? selectedPlaceDoc;
  final bool isLoadingPlace;
  final VoidCallback onShowMiniMap;
  final VoidCallback onClearPlace;

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
    bool hasSelectedPlace = selectedPlaceDoc != null;

    if (isLoadingPlace) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (hasSelectedPlace) {
      final data = selectedPlaceDoc!.data() as Map<String, dynamic>? ?? {};
      placeName = data['name'] ?? 'Địa điểm không tên';
      final location = data['location'] as Map<String, dynamic>? ?? {};
      placeAddress = location['fullAddress']?.isNotEmpty == true
          ? location['fullAddress']
          : '${location['street'] ?? ''}, ${location['city'] ?? ''}'
                .replaceAll(RegExp(r'^, |, $'), '')
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
                color: hasSelectedPlace ? Colors.orange : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onShowMiniMap,
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placeName,
                          style: TextStyle(
                            fontWeight: hasSelectedPlace
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 15,
                            color: hasSelectedPlace
                                ? Colors.black87
                                : Colors.orange,
                          ),
                        ),
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
              if (hasSelectedPlace)
                InkWell(
                  onTap: onClearPlace,
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
  final VoidCallback onAddHashtag;
  final Function(String) onRemoveHashtag;
  final Function(String) onAddSuggestedTag;

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
    bool canAddMore = hashtags.length < 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hashtag',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: hashtags
              .map(
                (tag) => Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  backgroundColor: Colors.grey[200],
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => onRemoveHashtag(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  deleteIconColor: Colors.grey[600],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: suggestedTags.map((tag) {
            bool isSelected = hashtags.contains(tag);
            return ActionChip(
              label: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.grey : Colors.blue[700],
                ),
              ),
              backgroundColor: isSelected ? Colors.grey[300] : Colors.blue[50],
              onPressed: isSelected ? null : () => onAddSuggestedTag(tag),
              tooltip: isSelected ? 'Đã chọn' : 'Thêm hashtag này',
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
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
                    hintText: canAddMore
                        ? 'Thêm hashtag...'
                        : 'Đã đủ 5 hashtag',
                    border: InputBorder.none,
                    counterText: '${hashtags.length}/5 hashtag',
                  ),
                  enabled: canAddMore,
                  onSubmitted: (_) => onAddHashtag(),
                ),
              ),
              TextButton(
                onPressed: canAddMore ? onAddHashtag : null,
                child: Text(
                  'Thêm',
                  style: TextStyle(
                    color: canAddMore ? Colors.orange : Colors.grey,
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
  final VoidCallback onTap;
  const PrivacySection({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: kFillColor,
              border: Border.all(color: kBorderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
