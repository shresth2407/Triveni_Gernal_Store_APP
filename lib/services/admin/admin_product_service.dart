import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';

abstract class AdminProductService {
  Future<List<Category>> getCategories();
  Future<List<Item>> getProducts();
  Future<void> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> addProduct(Item product);
  Future<void> updateProduct(Item product);
}

class FirestoreAdminProductService implements AdminProductService {
  final FirebaseFirestore _firestore;

  FirestoreAdminProductService({FirebaseFirestore? firestore})
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
  Future<List<Item>> getProducts() async {
    final snapshot = await _firestore.collection('products').get();
    return snapshot.docs.map(Item.fromFirestore).toList();
  }

  @override
  Future<void> addCategory(Category category) async {
    await _firestore.collection('categories').doc(category.id).set({
      'name': category.name,
      'imageUrl': category.imageUrl,
      'sortOrder': category.sortOrder,
    });
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _firestore.collection('categories').doc(category.id).update({
      'name': category.name,
      'imageUrl': category.imageUrl,
      'sortOrder': category.sortOrder,
    });
  }

  @override
  Future<void> addProduct(Item product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .set(product.toFirestore());
  }

  @override
  Future<void> updateProduct(Item product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .update(product.toFirestore());
  }
}
