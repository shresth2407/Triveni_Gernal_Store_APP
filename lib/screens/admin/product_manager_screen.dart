import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/admin/admin_data_providers.dart';
import '../../providers/admin/admin_service_providers.dart';

class ProductManagerScreen extends ConsumerWidget {
  const ProductManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Product Manager')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBanner(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminProductsProvider),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products yet.'));
          }
          return categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorBanner(
              message: error.toString(),
              onRetry: () => ref.invalidate(adminCategoriesProvider),
            ),
            data: (categories) {
              final categoryMap = {for (final c in categories) c.id: c.name};
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final categoryName =
                      categoryMap[product.categoryId] ?? 'Unknown';
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      '\$${product.price.toStringAsFixed(2)} · $categoryName',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openProductForm(context, ref,
                        product: product, categories: categories),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final categoriesAsync = ref.read(adminCategoriesProvider);
          categoriesAsync.whenData(
            (categories) =>
                _openProductForm(context, ref, categories: categories),
          );
        },
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openProductForm(
    BuildContext context,
    WidgetRef ref, {
    Item? product,
    required List<Category> categories,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductFormSheet(
        product: product,
        categories: categories,
        onSaved: () => ref.invalidate(adminProductsProvider),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

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

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _priceController;
  late final TextEditingController _offerPriceController;
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
    _offerPriceController = TextEditingController(
        text: p?.offerPrice != null ? p!.offerPrice.toString() : '');
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
    _offerPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final service = ref.read(adminProductServiceProvider);
    final offerPriceText = _offerPriceController.text.trim();
    final product = Item(
      id: widget.product?.id ??
          FirebaseFirestore.instance.collection('products').doc().id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      offerPrice: offerPriceText.isNotEmpty ? double.parse(offerPriceText) : null,
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

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit Product' : 'Add Product',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Image URL is required'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Category is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Must be a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _offerPriceController,
                decoration: const InputDecoration(
                    labelText: 'Offer Price (optional)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) {
                    return 'Must be a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  if (int.tryParse(v.trim()) == null) {
                    return 'Must be a whole number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('In Stock'),
                value: _inStock,
                onChanged: (v) => setState(() => _inStock = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
