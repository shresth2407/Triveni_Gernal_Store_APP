import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/admin/admin_data_providers.dart';
import '../../providers/discount_providers.dart';
import '../../widgets/discount_badge.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────
const _kRed        = Color(0xFFDC143C);
const _kDarkRed    = Color(0xFFB22222);
const _kLightRed   = Color(0xFFFFF0F0);
const _kRoseBorder = Color(0xFFFFCDD2);
const _kBg         = Color(0xFFF7F7F7);
const _kWhite      = Colors.white;
const _kTextDark   = Color(0xFF1A1A1A);
const _kTextGrey   = Color(0xFF9E9E9E);
const _kTextMid    = Color(0xFF555555);
const _kGreen      = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFFE8F5E9);
const _kGreenBorder= Color(0xFFA5D6A7);

class DiscountManagerScreen extends ConsumerWidget {
  const DiscountManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountsAsync = ref.watch(allDiscountsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          slivers: [
            // ── Gradient SliverAppBar ──────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: _kDarkRed,
              elevation: 0,
              leading: GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: _kWhite, size: 16),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _HeroHeader(onAddTap: () => _openDiscountForm(context, ref)),
              ),
            ),

            // ── Section label ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: discountsAsync.maybeWhen(
                  data: (discounts) => Row(
                    children: [
                      Container(
                        width: 4, height: 18,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kDarkRed, _kRed],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('All Discounts',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextDark)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kLightRed,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kRoseBorder, width: 1.5),
                        ),
                        child: Text('${discounts.length} total',
                            style: const TextStyle(fontSize: 11, color: _kRed, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ),

            // ── List / states ──────────────────────────────────────
            discountsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _kRed)),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorCard(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(allDiscountsProvider),
                ),
              ),
              data: (discounts) {
                if (discounts.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyDiscountsCard());
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _DiscountCard(
                        discount: discounts[index],
                        index: index,
                        onTap: () => _openDiscountForm(context, ref, discount: discounts[index]),
                      ),
                      childCount: discounts.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDiscountForm(BuildContext context, WidgetRef ref, {Discount? discount}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DiscountFormSheet(discount: discount),
    );
  }
}

// ─── HERO HEADER ──────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final VoidCallback onAddTap;
  const _HeroHeader({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B0000), _kDarkRed, _kRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30,
              child: Container(width: 130, height: 130,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
          Positioned(right: 40, bottom: 20,
              child: Container(width: 70, height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
          Positioned(left: -20, bottom: -20,
              child: Container(width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.local_offer_rounded, color: _kWhite, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Discount Manager',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kWhite)),
                          Text('Offers, coupons & deals',
                              style: TextStyle(fontSize: 11, color: Colors.white60)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── CREATE DISCOUNT inline banner ──────────────
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); onAddTap(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: _kRed.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: const Icon(Icons.add_rounded, color: _kWhite, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Create New Discount',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextDark)),
                                Text('Add percentage, BOGO or bulk deals',
                                    style: TextStyle(fontSize: 11, color: _kTextGrey)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: _kRed.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: const Text('+ Add',
                                style: TextStyle(color: _kWhite, fontSize: 12, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DISCOUNT CARD ────────────────────────────────────────────────
class _DiscountCard extends ConsumerWidget {
  final Discount discount;
  final int index;
  final VoidCallback onTap;

  const _DiscountCard({required this.discount, required this.index, required this.onTap});

  static const _typeGradients = {
    DiscountType.percentage: [Color(0xFFB22222), Color(0xFFDC143C)],
    DiscountType.bogo:       [Color(0xFF1565C0), Color(0xFF1E88E5)],
    DiscountType.bulk:       [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
  };

  static const _typeIcons = {
    DiscountType.percentage: Icons.percent_rounded,
    DiscountType.bogo:       Icons.card_giftcard_rounded,
    DiscountType.bulk:       Icons.layers_rounded,
  };

  static const _typeLabels = {
    DiscountType.percentage: 'Percentage',
    DiscountType.bogo:       'BOGO',
    DiscountType.bulk:       'Bulk Deal',
  };

  String _scopeLabel() => discount.scope == DiscountScope.product ? 'Product' : 'Category';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradient = _typeGradients[discount.type]!;
    final icon     = _typeIcons[discount.type]!;
    final typeLabel= _typeLabels[discount.type]!;

    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kRoseBorder, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x0EB22222), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: icon + name + toggle
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [BoxShadow(color: gradient.last.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Icon(icon, color: _kWhite, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(discount.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextDark),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _TypeChip(label: typeLabel, gradient: gradient),
                            const SizedBox(width: 6),
                            _PlainChip(label: _scopeLabel(), icon: Icons.track_changes_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActiveToggle(discount: discount),
                ],
              ),

              const SizedBox(height: 12),
              Container(height: 1, color: _kRoseBorder),
              const SizedBox(height: 10),

              // Bottom row: badge + edit button
              Row(
                children: [
                  DiscountBadge(discount: discount),
                  const Spacer(),
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); onTap(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kLightRed,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kRoseBorder, width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, color: _kRed, size: 13),
                          SizedBox(width: 4),
                          Text('Edit', style: TextStyle(fontSize: 11, color: _kRed, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  const _TypeChip({required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: _kWhite, fontWeight: FontWeight.w700)),
    );
  }
}

class _PlainChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlainChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kRoseBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: _kTextMid),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: _kTextMid, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── ACTIVE TOGGLE ────────────────────────────────────────────────
class _ActiveToggle extends ConsumerStatefulWidget {
  const _ActiveToggle({required this.discount});
  final Discount discount;

  @override
  ConsumerState<_ActiveToggle> createState() => _ActiveToggleState();
}

class _ActiveToggleState extends ConsumerState<_ActiveToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.discount.isActive;
  }

  @override
  void didUpdateWidget(_ActiveToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discount.isActive != widget.discount.isActive) {
      _value = widget.discount.isActive;
    }
  }

  Future<void> _toggle(bool newValue) async {
    final previous = _value;
    setState(() => _value = newValue);
    try {
      await ref.read(discountServiceProvider).setActive(widget.discount.id, newValue);
    } catch (e) {
      setState(() => _value = previous);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _toggle(!_value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _value ? _kGreenLight : _kLightRed,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _value ? _kGreenBorder : _kRoseBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: _value ? _kGreen : _kRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _value ? 'Active' : 'Off',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _value ? _kGreen : _kRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── EMPTY STATE ──────────────────────────────────────────────────
class _EmptyDiscountsCard extends StatelessWidget {
  const _EmptyDiscountsCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _kLightRed, shape: BoxShape.circle,
                border: Border.all(color: _kRoseBorder, width: 2),
              ),
              child: const Icon(Icons.local_offer_outlined, size: 38, color: _kRoseBorder),
            ),
            const SizedBox(height: 16),
            const Text('No discounts yet',
                style: TextStyle(color: _kTextDark, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Use "Create New Discount" above\nto add your first offer',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTextGrey, fontSize: 12, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ─── ERROR CARD ───────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kLightRed,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kRoseBorder, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _kRed, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(color: _kDarkRed, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: _kRed.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Text('Retry',
                      style: TextStyle(color: _kWhite, fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── DISCOUNT FORM SHEET ──────────────────────────────────────────
class _DiscountFormSheet extends ConsumerStatefulWidget {
  const _DiscountFormSheet({this.discount});
  final Discount? discount;

  @override
  ConsumerState<_DiscountFormSheet> createState() => _DiscountFormSheetState();
}

class _DiscountFormSheetState extends ConsumerState<_DiscountFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late final TextEditingController _buyQtyController;
  late final TextEditingController _freeQtyController;
  late final TextEditingController _minQtyController;
  late final TextEditingController _discountPercentController;

  late DiscountType  _type;
  late DiscountScope _scope;
  String? _targetId;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.discount != null;

  @override
  void initState() {
    super.initState();
    final d = widget.discount;
    _nameController             = TextEditingController(text: d?.name ?? '');
    _valueController            = TextEditingController(text: d?.value?.toString() ?? '');
    _buyQtyController           = TextEditingController(text: d?.buyQty?.toString() ?? '');
    _freeQtyController          = TextEditingController(text: d?.freeQty?.toString() ?? '');
    _minQtyController           = TextEditingController(text: d?.minQty?.toString() ?? '');
    _discountPercentController  = TextEditingController(text: d?.discountPercent?.toString() ?? '');
    _type     = d?.type  ?? DiscountType.percentage;
    _scope    = d?.scope ?? DiscountScope.product;
    _targetId = d?.targetId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _buyQtyController.dispose();
    _freeQtyController.dispose();
    _minQtyController.dispose();
    _discountPercentController.dispose();
    super.dispose();
  }

  String? _validatePositiveDouble(String? v, String label, {double min = 0, double max = 100}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    final n = double.tryParse(v.trim());
    if (n == null) return '$label must be a number';
    if (n <= min || n > max) return '$label must be > $min and ≤ $max';
    return null;
  }

  String? _validatePositiveInt(String? v, String label, {int min = 1}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    final n = int.tryParse(v.trim());
    if (n == null) return '$label must be a whole number';
    if (n < min) return '$label must be ≥ $min';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetId == null) {
      setState(() => _errorMessage = 'Please select a target.');
      return;
    }
    setState(() { _isSubmitting = true; _errorMessage = null; });
    HapticFeedback.mediumImpact();

    final service = ref.read(discountServiceProvider);
    final id = widget.discount?.id ??
        FirebaseFirestore.instance.collection('discounts').doc().id;

    final discount = Discount(
      id: id,
      name: _nameController.text.trim(),
      type: _type,
      scope: _scope,
      targetId: _targetId!,
      isActive: widget.discount?.isActive ?? true,
      createdAt: widget.discount?.createdAt ?? DateTime.now(),
      value: _type == DiscountType.percentage
          ? double.parse(_valueController.text.trim()) : null,
      buyQty: _type == DiscountType.bogo
          ? int.parse(_buyQtyController.text.trim()) : null,
      freeQty: _type == DiscountType.bogo
          ? int.parse(_freeQtyController.text.trim()) : null,
      minQty: _type == DiscountType.bulk
          ? int.parse(_minQtyController.text.trim()) : null,
      discountPercent: _type == DiscountType.bulk
          ? double.parse(_discountPercentController.text.trim()) : null,
    );

    try {
      if (_isEditing) {
        await service.updateDiscount(discount);
      } else {
        await service.createDiscount(discount);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categoriesAsync = ref.watch(adminCategoriesProvider);
    final productsAsync   = ref.watch(adminProductsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 44, height: 4,
                    decoration: BoxDecoration(color: _kRoseBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                // Sheet header
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF0F0), _kWhite],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _kRoseBorder, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: _kRed.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Icon(_isEditing ? Icons.edit_rounded : Icons.local_offer_rounded, color: _kWhite, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_isEditing ? 'Edit Discount' : 'Create Discount',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _kTextDark)),
                            const SizedBox(height: 2),
                            Text(_isEditing ? 'Update discount details' : 'Set up your offer below',
                                style: const TextStyle(fontSize: 11, color: _kTextGrey)),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),

                // Error banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kLightRed,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kRoseBorder, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: _kRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage!,
                            style: const TextStyle(color: _kDarkRed, fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Name
                _StyledField(
                  controller: _nameController,
                  label: 'Discount Name',
                  icon: Icons.label_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),

                // Type selector
                _SectionLabel(label: 'Discount Type'),
                const SizedBox(height: 8),
                Row(
                  children: DiscountType.values.map((t) {
                    final selected = _type == t;
                    const icons  = {
                      DiscountType.percentage: Icons.percent_rounded,
                      DiscountType.bogo:       Icons.card_giftcard_rounded,
                      DiscountType.bulk:       Icons.layers_rounded,
                    };
                    const labels = {
                      DiscountType.percentage: 'Percent',
                      DiscountType.bogo:       'BOGO',
                      DiscountType.bulk:       'Bulk',
                    };
                    return Expanded(
                      child: GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); setState(() => _type = t); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(right: t != DiscountType.bulk ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(colors: [_kDarkRed, _kRed])
                                : null,
                            color: selected ? null : _kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selected ? _kRed : _kRoseBorder, width: 1.5),
                            boxShadow: selected
                                ? [BoxShadow(color: _kRed.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: Column(
                            children: [
                              Icon(icons[t]!, color: selected ? _kWhite : _kTextMid, size: 20),
                              const SizedBox(height: 4),
                              Text(labels[t]!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? _kWhite : _kTextMid,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Scope selector
                _SectionLabel(label: 'Applies To'),
                const SizedBox(height: 8),
                Row(
                  children: DiscountScope.values.map((s) {
                    final selected = _scope == s;
                    final label = s == DiscountScope.product ? 'Product' : 'Category';
                    final icon  = s == DiscountScope.product ? Icons.inventory_2_rounded : Icons.category_rounded;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); setState(() { _scope = s; _targetId = null; }); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(right: s == DiscountScope.product ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(colors: [_kDarkRed, _kRed])
                                : null,
                            color: selected ? null : _kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selected ? _kRed : _kRoseBorder, width: 1.5),
                            boxShadow: selected
                                ? [BoxShadow(color: _kRed.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: selected ? _kWhite : _kTextMid, size: 16),
                              const SizedBox(width: 6),
                              Text(label,
                                  style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700,
                                    color: selected ? _kWhite : _kTextMid,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Target dropdown
                _SectionLabel(label: _scope == DiscountScope.category ? 'Select Category' : 'Select Product'),
                const SizedBox(height: 8),
                if (_scope == DiscountScope.category)
                  categoriesAsync.when(
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: _kRed))),
                    error: (e, _) => Text('Error loading categories: $e',
                        style: const TextStyle(color: _kRed, fontSize: 12)),
                    data: (categories) => _StyledDropdown<String>(
                      value: _targetId,
                      hint: 'Choose a category',
                      icon: Icons.category_rounded,
                      items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _targetId = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Category is required' : null,
                    ),
                  )
                else
                  productsAsync.when(
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: _kRed))),
                    error: (e, _) => Text('Error loading products: $e',
                        style: const TextStyle(color: _kRed, fontSize: 12)),
                    data: (products) => _StyledDropdown<String>(
                      value: _targetId,
                      hint: 'Choose a product',
                      icon: Icons.inventory_2_rounded,
                      items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: (v) => setState(() => _targetId = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Product is required' : null,
                    ),
                  ),
                const SizedBox(height: 14),

                // Type-specific fields
                if (_type == DiscountType.percentage) ...[
                  _SectionLabel(label: 'Discount Value'),
                  const SizedBox(height: 8),
                  _StyledField(
                    controller: _valueController,
                    label: 'Discount %',
                    icon: Icons.percent_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validatePositiveDouble(v, 'Discount %'),
                  ),
                ],
                if (_type == DiscountType.bogo) ...[
                  _SectionLabel(label: 'BOGO Settings'),
                  const SizedBox(height: 8),
                  _StyledField(
                    controller: _buyQtyController,
                    label: 'Buy Qty',
                    icon: Icons.shopping_cart_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) => _validatePositiveInt(v, 'Buy Qty'),
                  ),
                  const SizedBox(height: 10),
                  _StyledField(
                    controller: _freeQtyController,
                    label: 'Free Qty',
                    icon: Icons.card_giftcard_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) => _validatePositiveInt(v, 'Free Qty'),
                  ),
                ],
                if (_type == DiscountType.bulk) ...[
                  _SectionLabel(label: 'Bulk Settings'),
                  const SizedBox(height: 8),
                  _StyledField(
                    controller: _minQtyController,
                    label: 'Min Qty',
                    icon: Icons.layers_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) => _validatePositiveInt(v, 'Min Qty', min: 2),
                  ),
                  const SizedBox(height: 10),
                  _StyledField(
                    controller: _discountPercentController,
                    label: 'Discount %',
                    icon: Icons.percent_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validatePositiveDouble(v, 'Discount %'),
                  ),
                ],
                const SizedBox(height: 22),

                // Submit
                GestureDetector(
                  onTap: _isSubmitting ? null : _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isSubmitting
                            ? [const Color(0xFFCC5555), const Color(0xFFCC5555)]
                            : [_kDarkRed, _kRed],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isSubmitting ? [] :
                      [BoxShadow(color: _kRed.withOpacity(0.38), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: _kWhite))
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isEditing ? Icons.save_rounded : Icons.local_offer_rounded, color: _kWhite, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing ? 'Save Changes' : 'Create Discount',
                            style: const TextStyle(color: _kWhite, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SECTION LABEL ────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kTextMid));
  }
}

// ─── STYLED DROPDOWN ──────────────────────────────────────────────
class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      validator: validator,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: _kRed, size: 20),
        filled: true,
        fillColor: _kLightRed,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:             OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kRoseBorder, width: 1.5)),
        enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kRoseBorder, width: 1.5)),
        focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kRed, width: 2)),
        errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kDarkRed, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kDarkRed, width: 2)),
      ),
      items: items,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kRed),
      dropdownColor: _kWhite,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextDark),
    );
  }
}

// ─── STYLED TEXT FIELD ────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _kTextGrey, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: _kRed, size: 20),
        filled: true,
        fillColor: _kLightRed,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:             OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kRoseBorder, width: 1.5)),
        enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kRoseBorder, width: 1.5)),
        focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kRed, width: 2)),
        errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kDarkRed, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kDarkRed, width: 2)),
      ),
    );
  }
}