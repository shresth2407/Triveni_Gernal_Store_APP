import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final int quantity;
  final String categoryId;
  final bool inStock;
  final Map<String, dynamic>? offer;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.quantity = 0,
    required this.categoryId,
    required this.inStock,
    this.offer, // ✅ optional now
  });

  // ✅ Dynamic price (basic)
  double get effectivePrice {
    if (offer == null) return price;

    if (offer!['type'] == 'percentage') {
      return price * (1 - (offer!['value'] / 100));
    }

    return price; // others handled in cart
  }

  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Item(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      imageUrl: data['imageUrl'] as String,
      price: (data['price'] as num).toDouble(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      categoryId: data['categoryId'] as String,
      inStock: data['inStock'] as bool,
      offer: data['offer'] as Map<String, dynamic>?, // ✅ FIXED
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'price': price,
    'quantity': quantity,
    'categoryId': categoryId,
    'inStock': inStock,
    if (offer != null) 'offer': offer, // ✅ save offer
  };
}