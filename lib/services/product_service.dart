import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

abstract class ProductService {
  Future<List<Category>> getCategories();
  Future<List<Item>> getItems({String? categoryId});
  Future<Item> getItemById(String id);
}

class FirestoreProductService implements ProductService {
  final FirebaseFirestore _firestore;

  FirestoreProductService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Category>> getCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('sortOrder')
        .get();
    return snapshot.docs.map(Category.fromFirestore).toList();
  }

  @override
  Future<List<Item>> getItems({String? categoryId}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('products');
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    final snapshot = await query.get();
    return snapshot.docs.map(Item.fromFirestore).toList();
  }

  @override
  Future<Item> getItemById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (!doc.exists) {
      throw Exception('Item not found: $id');
    }
    return Item.fromFirestore(doc);
  }
}
