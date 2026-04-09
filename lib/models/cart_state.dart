import 'cart_item.dart';

class CartState {
  final List<CartItem> items;

  const CartState({this.items = const []});

  double get total => items.fold(0, (sum, ci) => sum + ci.lineTotal);
  bool get isEmpty => items.isEmpty;
}
