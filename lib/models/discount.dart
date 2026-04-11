import 'package:cloud_firestore/cloud_firestore.dart';

enum DiscountType { percentage, bogo, bulk }

enum DiscountScope { product, category }

class Discount {
  final String id;
  final String name;
  final DiscountType type;
  final DiscountScope scope;
  final String targetId;
  final bool isActive;
  final DateTime createdAt;

  // percentage
  final double? value;

  // bogo
  final int? buyQty;
  final int? freeQty;

  // bulk
  final int? minQty;
  final double? discountPercent;

  const Discount({
    required this.id,
    required this.name,
    required this.type,
    required this.scope,
    required this.targetId,
    required this.isActive,
    required this.createdAt,
    this.value,
    this.buyQty,
    this.freeQty,
    this.minQty,
    this.discountPercent,
  });

  factory Discount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Discount(
      id: doc.id,
      name: data['name'] as String,
      type: DiscountType.values.byName(data['type'] as String),
      scope: DiscountScope.values.byName(data['scope'] as String),
      targetId: data['targetId'] as String,
      isActive: data['isActive'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      value: (data['value'] as num?)?.toDouble(),
      buyQty: (data['buyQty'] as num?)?.toInt(),
      freeQty: (data['freeQty'] as num?)?.toInt(),
      minQty: (data['minQty'] as num?)?.toInt(),
      discountPercent: (data['discountPercent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type.name,
    'scope': scope.name,
    'targetId': targetId,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    if (value != null) 'value': value,
    if (buyQty != null) 'buyQty': buyQty,
    if (freeQty != null) 'freeQty': freeQty,
    if (minQty != null) 'minQty': minQty,
    if (discountPercent != null) 'discountPercent': discountPercent,
  };
}
