import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double? offerPrice;
  final int quantity;
  final String categoryId;
  final bool inStock;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.offerPrice,
    this.quantity = 0,
    required this.categoryId,
    required this.inStock,
  });

  double get effectivePrice => offerPrice ?? price;

  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      imageUrl: data['imageUrl'] as String,
      price: (data['price'] as num).toDouble(),
      offerPrice: data['offerPrice'] != null
          ? (data['offerPrice'] as num).toDouble()
          : null,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      categoryId: data['categoryId'] as String,
      inStock: data['inStock'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'price': price,
        if (offerPrice != null) 'offerPrice': offerPrice,
        'quantity': quantity,
        'categoryId': categoryId,
        'inStock': inStock,
      };
}
