// file: lib/model/category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;

  CategoryModel({required this.id, required this.name});

  // Factory để tạo model từ DocumentSnapshot của Firestore
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id, // Lấy DocumentID
      name: data['name'] ?? '', // Lấy trường 'name'
    );
  }

  // Ghi đè hai hàm này là RẤT QUAN TRỌNG
  // để so sánh các đối tượng trong List (ví dụ: _selectedCategories.remove(category))
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
