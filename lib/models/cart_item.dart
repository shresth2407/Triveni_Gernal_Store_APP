import 'item.dart';

class CartItem {
  final Item item;
  final int quantity;

  const CartItem({
    required this.item,
    required this.quantity,
  });

  double get lineTotal => item.price * quantity;
}
