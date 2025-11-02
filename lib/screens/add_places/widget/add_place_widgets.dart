// File: screens/add_places/widget/add_place_widgets.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nhom_3_damh_lttbdd/model/category_model.dart';

// === WIDGET 1: KHU VỰC CHỌN DANH MỤC ===
class CategoryChipsArea extends StatelessWidget {
  final List<CategoryModel> selectedCategories;
  final int maxCategories;
  final VoidCallback onAdd;
  final Function(CategoryModel) onRemove;

  const CategoryChipsArea({
    Key? key,
    required this.selectedCategories,
    required this.maxCategories,
    required this.onAdd,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          ...selectedCategories
              .map(
                (category) => _CategoryChip(
                  category: category,
                  onRemove: () => onRemove(category),
                ),
              )
              .toList(),
          if (selectedCategories.length < maxCategories)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Thêm',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// === WIDGET 1.1: CHIP DANH MỤC (Private) ===
class _CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onRemove;

  const _CategoryChip({
    Key? key,
    required this.category,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 6, right: 10, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Icon(Icons.close, size: 14, color: Colors.orange.shade800),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            category.name,
            style: TextStyle(
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// === WIDGET 2: KHU VỰC CHỌN ẢNH ===
class ImageSelectionArea extends StatelessWidget {
  final List<XFile> selectedImages;
  final int maxImages;
  final VoidCallback onAdd;
  final Function(XFile) onRemove;

  const ImageSelectionArea({
    Key? key,
    required this.selectedImages,
    required this.maxImages,
    required this.onAdd,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          ...selectedImages
              .map(
                (imageFile) => _ImageThumbnail(
                  imageFile: imageFile,
                  onRemove: () => onRemove(imageFile),
                ),
              )
              .toList(),
          if (selectedImages.length < maxImages)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.grey.shade600,
                      size: 30,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thêm ảnh',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// === WIDGET 2.1: THUMBNAIL ẢNH (Private) ===
class _ImageThumbnail extends StatelessWidget {
  final XFile imageFile;
  final VoidCallback onRemove;

  const _ImageThumbnail({
    Key? key,
    required this.imageFile,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(imageFile.path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.error_outline, color: Colors.red, size: 30),
              ),
            ),
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
