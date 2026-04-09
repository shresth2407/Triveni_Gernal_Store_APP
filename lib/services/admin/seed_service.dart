import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';

abstract class SeedService {
  Future<SeedResult> seedData();
}

class FirestoreSeedService implements SeedService {
  final FirebaseFirestore _firestore;

  FirestoreSeedService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // @override
  // Future<SeedResult> seedData() async {
  //   final batch = _firestore.batch();
  //
  //   // Categories
  //   final categoriesRef = _firestore.collection('categories');
  //   final fruitsRef = categoriesRef.doc('fruits');
  //   final vegetablesRef = categoriesRef.doc('vegetables');
  //   final dairyRef = categoriesRef.doc('dairy');
  //
  //   batch.set(fruitsRef, {
  //     'name': 'Fruits',
  //     'imageUrl': 'https://placeholder.com/fruits.png',
  //     'sortOrder': 1,
  //   });
  //   batch.set(vegetablesRef, {
  //     'name': 'Vegetables',
  //     'imageUrl': 'https://placeholder.com/vegetables.png',
  //     'sortOrder': 2,
  //   });
  //   batch.set(dairyRef, {
  //     'name': 'Dairy',
  //     'imageUrl': 'https://placeholder.com/dairy.png',
  //     'sortOrder': 3,
  //   });
  //
  //   // Products
  //   final productsRef = _firestore.collection('products');
  //
  //   batch.set(productsRef.doc('apple'), {
  //     'name': 'Apple',
  //     'description': 'Fresh red apples',
  //     'imageUrl': 'https://placeholder.com/apple.png',
  //     'price': 1.99,
  //     'quantity': 100,
  //     'categoryId': 'fruits',
  //     'inStock': true,
  //   });
  //   batch.set(productsRef.doc('banana'), {
  //     'name': 'Banana',
  //     'description': 'Ripe yellow bananas',
  //     'imageUrl': 'https://placeholder.com/banana.png',
  //     'price': 0.99,
  //     'quantity': 150,
  //     'categoryId': 'fruits',
  //     'inStock': true,
  //   });
  //   batch.set(productsRef.doc('carrot'), {
  //     'name': 'Carrot',
  //     'description': 'Organic carrots',
  //     'imageUrl': 'https://placeholder.com/carrot.png',
  //     'price': 1.49,
  //     'quantity': 80,
  //     'categoryId': 'vegetables',
  //     'inStock': true,
  //   });
  //   batch.set(productsRef.doc('broccoli'), {
  //     'name': 'Broccoli',
  //     'description': 'Fresh broccoli florets',
  //     'imageUrl': 'https://placeholder.com/broccoli.png',
  //     'price': 2.49,
  //     'quantity': 60,
  //     'categoryId': 'vegetables',
  //     'inStock': true,
  //   });
  //   batch.set(productsRef.doc('milk'), {
  //     'name': 'Milk',
  //     'description': 'Whole milk 1L',
  //     'imageUrl': 'https://placeholder.com/milk.png',
  //     'price': 1.79,
  //     'quantity': 200,
  //     'categoryId': 'dairy',
  //     'inStock': true,
  //   });
  //   batch.set(productsRef.doc('cheese'), {
  //     'name': 'Cheese',
  //     'description': 'Cheddar cheese 200g',
  //     'imageUrl': 'https://placeholder.com/cheese.png',
  //     'price': 3.99,
  //     'quantity': 50,
  //     'categoryId': 'dairy',
  //     'inStock': true,
  //   });
  //
  //   await batch.commit();
  //
  //   return const SeedResult(categoriesSeeded: 3, productsSeeded: 6);
  // }




  @override
  Future<SeedResult> seedData() async {
    final batch = _firestore.batch();

    // Categories
    final categoriesRef = _firestore.collection('categories');
    final fruitsRef = categoriesRef.doc('fruits');
    final vegetablesRef = categoriesRef.doc('vegetables');
    final dairyRef = categoriesRef.doc('dairy');

    batch.set(fruitsRef, {
      'name': 'Fruits',
      'imageUrl': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf',
      'sortOrder': 1,
    });

    batch.set(vegetablesRef, {
      'name': 'Vegetables',
      'imageUrl': 'https://images.unsplash.com/photo-1506806732259-39c2d0268443',
      'sortOrder': 2,
    });

    batch.set(dairyRef, {
      'name': 'Dairy',
      'imageUrl': 'https://images.unsplash.com/photo-1580910051074-3eb694886505',
      'sortOrder': 3,
    });

    // Products
    final productsRef = _firestore.collection('products');

    batch.set(productsRef.doc('apple'), {
      'name': 'Apple',
      'description': 'Fresh and juicy red apples, rich in fiber and vitamins.',
      'imageUrl': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6',
      'price': 120.0,
      'quantity': 100,
      'categoryId': 'fruits',
      'unit': 'kg',
      'rating': 4.5,
      'inStock': true,
    });

    batch.set(productsRef.doc('banana'), {
      'name': 'Banana',
      'description': 'Naturally sweet bananas, high in potassium and energy.',
      'imageUrl': 'https://images.unsplash.com/photo-1574226516831-e1dff420e37f',
      'price': 60.0,
      'quantity': 150,
      'categoryId': 'fruits',
      'unit': 'dozen',
      'rating': 4.3,
      'inStock': true,
    });

    batch.set(productsRef.doc('carrot'), {
      'name': 'Carrot',
      'description': 'Organic carrots, rich in beta-carotene and antioxidants.',
      'imageUrl': 'https://images.unsplash.com/photo-1582515073490-dc0c7d3c7b37',
      'price': 40.0,
      'quantity': 80,
      'categoryId': 'vegetables',
      'unit': 'kg',
      'rating': 4.4,
      'inStock': true,
    });

    batch.set(productsRef.doc('broccoli'), {
      'name': 'Broccoli',
      'description': 'Fresh green broccoli packed with vitamins and minerals.',
      'imageUrl': 'https://images.unsplash.com/photo-1615486363973-f79b8a4b8c90',
      'price': 90.0,
      'quantity': 60,
      'categoryId': 'vegetables',
      'unit': 'kg',
      'rating': 4.2,
      'inStock': true,
    });

    batch.set(productsRef.doc('milk'), {
      'name': 'Milk',
      'description': 'Pure full cream milk, rich in calcium and protein.',
      'imageUrl': 'https://images.unsplash.com/photo-1585238342028-4c4f3f0a62a1',
      'price': 55.0,
      'quantity': 200,
      'categoryId': 'dairy',
      'unit': 'litre',
      'rating': 4.6,
      'inStock': true,
    });

    batch.set(productsRef.doc('cheese'), {
      'name': 'Cheese',
      'description': 'Premium cheddar cheese with rich taste and smooth texture.',
      'imageUrl': 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092',
      'price': 180.0,
      'quantity': 50,
      'categoryId': 'dairy',
      'unit': 'pack',
      'rating': 4.7,
      'inStock': true,
    });

    await batch.commit();

    return const SeedResult(categoriesSeeded: 3, productsSeeded: 6);
  }
}
