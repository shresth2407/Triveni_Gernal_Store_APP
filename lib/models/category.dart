import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sortOrder,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] as String,
      imageUrl: data['imageUrl'] as String,
      sortOrder: data['sortOrder'] as int,
    );
  }
}
