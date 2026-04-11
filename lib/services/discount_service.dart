import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/discount.dart';

/// Abstract interface for discount persistence operations.
abstract class DiscountService {
  /// Real-time stream of active discounts (isActive == true) for customer UI
  /// and the cart engine.
  Stream<List<Discount>> watchActiveDiscounts();

  /// Real-time stream of all discounts (active + inactive) for admin management.
  Stream<List<Discount>> watchAllDiscounts();

  /// Creates a new discount document.
  /// Forces [isActive] to true and sets [createdAt] to the server timestamp.
  Future<void> createDiscount(Discount discount);

  /// Updates mutable fields of an existing discount document.
  /// Does not overwrite [isActive] or [createdAt].
  Future<void> updateDiscount(Discount discount);

  /// Sets the [isActive] field of a discount document.
  Future<void> setActive(String discountId, bool isActive);
}

/// Firestore-backed implementation of [DiscountService].
///
/// Queries the top-level `discounts` collection, following the same
/// abstract + Firebase implementation pattern used by [AdminProductService].
class FirestoreDiscountService implements DiscountService {
  final FirebaseFirestore _firestore;

  FirestoreDiscountService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('discounts');

  @override
  Stream<List<Discount>> watchActiveDiscounts() {
    return _collection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(Discount.fromFirestore).toList());
  }

  @override
  Stream<List<Discount>> watchAllDiscounts() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Discount.fromFirestore).toList());
  }

  @override
  Future<void> createDiscount(Discount discount) async {
    final data = discount.toFirestore();
    // Enforce isActive=true and use server timestamp for createdAt.
    data['isActive'] = true;
    data['createdAt'] = FieldValue.serverTimestamp();
    await _collection.doc(discount.id).set(data);
  }

  @override
  Future<void> updateDiscount(Discount discount) async {
    // Write only mutable fields — never overwrite isActive or createdAt.
    final Map<String, dynamic> mutable = {
      'name': discount.name,
      'type': discount.type.name,
      'scope': discount.scope.name,
      'targetId': discount.targetId,
    };

    // Include type-specific fields, clearing irrelevant ones to keep the
    // document consistent when the type changes.
    mutable['value'] = discount.value;
    mutable['buyQty'] = discount.buyQty;
    mutable['freeQty'] = discount.freeQty;
    mutable['minQty'] = discount.minQty;
    mutable['discountPercent'] = discount.discountPercent;

    await _collection.doc(discount.id).update(mutable);
  }

  @override
  Future<void> setActive(String discountId, bool isActive) async {
    await _collection.doc(discountId).update({'isActive': isActive});
  }
}
