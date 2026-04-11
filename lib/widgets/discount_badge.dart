import 'package:flutter/material.dart';

import '../models/discount.dart';

const _kGreen = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFFE8F5E9);

class DiscountBadge extends StatelessWidget {
  final Discount discount;

  const DiscountBadge({super.key, required this.discount});

  String get _badgeText {
    switch (discount.type) {
      case DiscountType.percentage:
        return '${discount.value!.toInt()}% OFF';
      case DiscountType.bogo:
        return 'BUY ${discount.buyQty} GET ${discount.freeQty} FREE';
      case DiscountType.bulk:
        return 'SAVE ${discount.discountPercent!.toInt()}% on ${discount.minQty}+';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: _kGreenLight,
      child: Text(
        _badgeText,
        style: const TextStyle(fontSize: 10, color: _kGreen),
      ),
    );
  }
}
