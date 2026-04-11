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
        return 'BUY ${discount.buyQty} GET ${discount.freeQty}';
      case DiscountType.bulk:
        return '${discount.discountPercent!.toInt()}% OFF ${discount.minQty}+';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _badgeText,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}