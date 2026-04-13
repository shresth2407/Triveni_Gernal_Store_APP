
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/admin/admin_data_providers.dart';
import '../../providers/admin/admin_service_providers.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────
const _kRed         = Color(0xFFDC143C);
const _kDarkRed     = Color(0xFFB22222);
const _kLightRed    = Color(0xFFFFF0F0);
const _kRoseBorder  = Color(0xFFFFCDD2);
const _kBg          = Color(0xFFF7F7F7);
const _kWhite       = Colors.white;
const _kTextDark    = Color(0xFF1A1A1A);
const _kTextGrey    = Color(0xFF9E9E9E);
const _kTextMid     = Color(0xFF555555);
const _kGreen       = Color(0xFF2E7D32);
const _kGreenLight  = Color(0xFFE8F5E9);

class ProductManagerScreen extends ConsumerWidget {
  const ProductManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          slivers: [
            // ─── CUSTOM APP BAR ─────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: _kWhite,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kLightRed,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kRoseBorder, width: 1),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: _kRed, size: 16),
                ),
                onPressed: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_kDarkRed, _kRed], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Products', style: TextStyle(color: _kWhite, fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('Manage store inventory', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── BODY CONTENT ───────────────────────────────────────
            SliverToBoxAdapter(
              child: productsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: _kRed)),
                ),
                error: (error, _) => _ErrorCard(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(adminProductsProvider),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return const _EmptyProductsCard();
                  }
                  return categoriesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: _kRed)),
                    ),
                    error: (error, _) => _ErrorCard(
                      message: 'Failed to load categories: ${error.toString()}',
                      onRetry: () => ref.invalidate(adminCategoriesProvider),
                    ),
                    data: (categories) {
                      final categoryMap = {for (final c in categories) c.id: c.name};
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        child: Column(
                          children: products.map((product) {
                            final categoryName = categoryMap[product.categoryId] ?? 'Unknown';
                            return _ProductCard(
                              product: product,
                              categoryName: categoryName,
                              onTap: () => _openProductForm(context, ref, product: product, categories: categories),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _ModernAddFab(
          onTap: () {
            final categoriesAsync = ref.read(adminCategoriesProvider);
            categoriesAsync.whenData(
                  (categories) => _openProductForm(context, ref, categories: categories),
            );
          },
        ),
      ),
    );
  }

  void _openProductForm(
      BuildContext context,
      WidgetRef ref, {
        Item? product,
        required List<Category> categories,
      }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(
        product: product,
        categories: categories,
        onSaved: () => ref.invalidate(adminProductsProvider),
      ),
    );
  }
}

// ─── PRODUCT CARD ───────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Item product;
  final String categoryName;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kRoseBorder.withOpacity(0.6), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image / Placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                  product.imageUrl,
                  width: 70, height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                )
                    : _ImagePlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoryName,
                      style: const TextStyle(fontSize: 12, color: _kTextGrey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kRed),
                        ),
                        const SizedBox(width: 8),
                        _StockBadge(inStock: product.inStock),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _kRoseBorder),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final bool inStock;
  const _StockBadge({required this.inStock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: inStock ? _kGreenLight : _kLightRed,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        inStock ? 'In Stock' : 'Out of Stock',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: inStock ? _kGreen : _kRed),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_kLightRed, _kRoseBorder]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.image_not_supported_rounded, color: _kRoseBorder),
    );
  }
}

// ─── MODERN FAB ─────────────────────────────────────────────────
class _ModernAddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ModernAddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: _kRed.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: _kWhite, size: 22),
              SizedBox(width: 8),
              Text('Add Product', style: TextStyle(color: _kWhite, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PRODUCT FORM SHEET ─────────────────────────────────────────
class _ProductFormSheet extends ConsumerStatefulWidget {
  const _ProductFormSheet({
    this.product,
    required this.categories,
    required this.onSaved,
  });

  final Item? product;
  final List<Category> categories;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();

  String _offerType = 'none'; // none | percentage | bogo | bulk

  final _discountController = TextEditingController();
  final _minQtyController = TextEditingController();
  final _buyQtyController = TextEditingController();
  final _freeQtyController = TextEditingController();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;

  String? _selectedCategoryId;
  bool _inStock = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _priceController =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _quantityController =
        TextEditingController(text: p != null ? p.quantity.toString() : '');
    _selectedCategoryId = p?.categoryId;
    _inStock = p?.inStock ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _discountController.dispose();
    _minQtyController.dispose();
    _buyQtyController.dispose();
    _freeQtyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final service = ref.read(adminProductServiceProvider);

    // LOGIC PRESERVED FROM ORIGINAL
    final product = Item(
      id: widget.product?.id ??
          FirebaseFirestore.instance.collection('products').doc().id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      quantity: int.parse(_quantityController.text.trim()),
      categoryId: _selectedCategoryId!,
      inStock: _inStock,
    );

    try {
      if (_isEditing) {
        await service.updateProduct(product);
      } else {
        await service.addProduct(product);
      }

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── LIGHT HEADER SECTION ─────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kLightRed, _kWhite],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.6, 1.0],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: _kRoseBorder, borderRadius: BorderRadius.circular(2)),
                ),
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: _kRed.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Icon(_isEditing ? Icons.edit_rounded : Icons.inventory_2_rounded, color: _kWhite, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Edit Product' : 'New Product',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kTextDark),
                          ),
                          Text(
                            _isEditing ? 'Update product details' : 'Add to inventory',
                            style: const TextStyle(fontSize: 12, color: _kTextGrey, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── FORM BODY SECTION ───────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF9A9A), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: _kRed, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: _kDarkRed, fontSize: 12, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Fields
                    _StyledField(controller: _nameController, label: 'Product Name', icon: Icons.label_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
                    const SizedBox(height: 12),

                    _StyledField(controller: _descriptionController, label: 'Description', icon: Icons.description_rounded, maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null),
                    const SizedBox(height: 12),

                    _StyledField(controller: _imageUrlController, label: 'Image URL', icon: Icons.image_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Image URL is required' : null),
                    const SizedBox(height: 12),

                    _StyledDropdown(
                      value: _selectedCategoryId,
                      label: 'Category',
                      icon: Icons.category_rounded,
                      items: widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Category is required' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _StyledField(controller: _priceController, label: 'Price (\$)', icon: Icons.attach_money_rounded, keyboardType: TextInputType.numberWithOptions(decimal: true), validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Price required';
                          if (double.tryParse(v.trim()) == null) return 'Invalid number';
                          return null;
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _StyledField(controller: _quantityController, label: 'Stock Qty', icon: Icons.inventory_2_rounded, keyboardType: TextInputType.number, validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Quantity required';
                          if (int.tryParse(v.trim()) == null) return 'Invalid number';
                          return null;
                        })),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kLightRed,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kRoseBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: _inStock ? _kRed : _kTextGrey, size: 20),
                              const SizedBox(width: 12),
                              const Text('In Stock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextDark)),
                            ],
                          ),
                          Switch(
                            value: _inStock,
                            onChanged: (v) => setState(() => _inStock = v),
                            activeColor: _kRed,
                          ),
                        ],
                      ),
                    ),

                    // ─── COMMENTED OUT OFFER LOGIC (PRESERVED) ─────
                    // const SizedBox(height: 12),
                    // DropdownButtonFormField<String>(
                    //   value: _offerType,
                    //   decoration: const InputDecoration(labelText: 'Offer Type'),
                    //   items: const [
                    //     DropdownMenuItem(value: 'none', child: Text('No Offer')),
                    //     DropdownMenuItem(value: 'percentage', child: Text('Percentage Discount')),
                    //     DropdownMenuItem(value: 'bogo', child: Text('Buy 1 Get 1')),
                    //     DropdownMenuItem(value: 'bulk', child: Text('Bulk Discount')),
                    //   ],
                    //   onChanged: (v) => setState(() => _offerType = v!),
                    // ),
                    //
                    // if (_offerType == 'percentage') ...[
                    //   TextFormField(
                    //     controller: _discountController,
                    //     decoration: const InputDecoration(labelText: 'Discount %'),
                    //     keyboardType: TextInputType.number,
                    //   ),
                    // ],
                    //
                    // if (_offerType == 'bogo') ...[
                    //   TextFormField(
                    //     controller: _buyQtyController,
                    //     decoration: const InputDecoration(labelText: 'Buy Qty'),
                    //     keyboardType: TextInputType.number,
                    //   ),
                    //   TextFormField(
                    //     controller: _freeQtyController,
                    //     decoration: const InputDecoration(labelText: 'Free Qty'),
                    //     keyboardType: TextInputType.number,
                    //   ),
                    // ],
                    //
                    // if (_offerType == 'bulk') ...[
                    //   TextFormField(
                    //     controller: _minQtyController,
                    //     decoration: const InputDecoration(labelText: 'Min Qty'),
                    //     keyboardType: TextInputType.number,
                    //   ),
                    //   TextFormField(
                    //     controller: _discountController,
                    //     decoration: const InputDecoration(labelText: 'Discount %'),
                    //     keyboardType: TextInputType.number,
                    //   ),
                    // ],
                    // ─────────────────────────────────────────────────

                    const SizedBox(height: 24),

                    // Submit Button
                    GestureDetector(
                      onTap: _isSubmitting ? null : _submit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: _isSubmitting ? [const Color(0xFFE57373), const Color(0xFFEF5350)] : [_kDarkRed, _kRed]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isSubmitting ? [] : [BoxShadow(color: _kRed.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: _kWhite))
                              : Text(_isEditing ? 'Save Changes' : 'Add Product', style: const TextStyle(color: _kWhite, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EMPTY STATE ─────────────────────────────────────────────────
class _EmptyProductsCard extends StatelessWidget {
  const _EmptyProductsCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _kRoseBorder, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kLightRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kRoseBorder, width: 2),
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 40, color: _kRoseBorder),
              ),
              const SizedBox(height: 20),
              const Text('No Products Found', style: TextStyle(color: _kTextDark, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Start by adding items to your store.', textAlign: TextAlign.center, style: TextStyle(color: _kTextGrey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ERROR CARD ─────────────────────────────────────────────────
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _kRed, shape: BoxShape.circle),
                child: const Icon(Icons.refresh, color: _kWhite, size: 24),
              ),
              const SizedBox(height: 16),
              Text('Oops!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kDarkRed)),
              const SizedBox(height: 4),
              Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(color: _kRed, fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    foregroundColor: _kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ─── STYLED FIELD HELPERS ────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _kTextGrey, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: _kRed, size: 22),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kRoseBorder, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kRoseBorder, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kRed, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kRed, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kRed, width: 2)),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const _StyledDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _kTextGrey, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: _kRed, size: 22),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kRoseBorder, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kRoseBorder, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kRed, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kRed, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kRed, width: 2)),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kRed),
    );
  }
}
