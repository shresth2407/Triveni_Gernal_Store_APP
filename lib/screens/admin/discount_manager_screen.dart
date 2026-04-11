import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/admin/admin_data_providers.dart';
import '../../providers/discount_providers.dart';
import '../../widgets/discount_badge.dart';

class DiscountManagerScreen extends ConsumerWidget {
  const DiscountManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountsAsync = ref.watch(allDiscountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discount Manager')),
      body: discountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBanner(
          message: error.toString(),
          onRetry: () => ref.invalidate(allDiscountsProvider),
        ),
        data: (discounts) {
          if (discounts.isEmpty) {
            return const Center(child: Text('No discounts yet.'));
          }
          return ListView.builder(
            itemCount: discounts.length,
            itemBuilder: (context, index) {
              final discount = discounts[index];
              return _DiscountTile(
                discount: discount,
                onTap: () => _openDiscountForm(context, ref, discount: discount),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDiscountForm(context, ref),
        tooltip: 'Create Discount',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openDiscountForm(BuildContext context, WidgetRef ref, {Discount? discount}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DiscountFormSheet(discount: discount),
    );
  }
}

// ─── Discount Tile ────────────────────────────────────────────────────────────

class _DiscountTile extends ConsumerWidget {
  const _DiscountTile({required this.discount, required this.onTap});

  final Discount discount;
  final VoidCallback onTap;

  String _typeLabel() {
    switch (discount.type) {
      case DiscountType.percentage:
        return 'Percentage';
      case DiscountType.bogo:
        return 'BOGO';
      case DiscountType.bulk:
        return 'Bulk';
    }
  }

  String _scopeLabel() =>
      discount.scope == DiscountScope.product ? 'Product' : 'Category';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(discount.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          DiscountBadge(discount: discount),
          const SizedBox(height: 4),
          Text('${_scopeLabel()} · ${_typeLabel()}',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
      trailing: _ActiveToggle(discount: discount),
      onTap: onTap,
    );
  }
}

// ─── Active Toggle ────────────────────────────────────────────────────────────

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
      await ref
          .read(discountServiceProvider)
          .setActive(widget.discount.id, newValue);
    } catch (e) {
      setState(() => _value = previous);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Switch(value: _value, onChanged: _toggle);
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────

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

// ─── Discount Form Sheet ──────────────────────────────────────────────────────

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

  late DiscountType _type;
  late DiscountScope _scope;
  String? _targetId;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.discount != null;

  @override
  void initState() {
    super.initState();
    final d = widget.discount;
    _nameController = TextEditingController(text: d?.name ?? '');
    _valueController =
        TextEditingController(text: d?.value?.toString() ?? '');
    _buyQtyController =
        TextEditingController(text: d?.buyQty?.toString() ?? '');
    _freeQtyController =
        TextEditingController(text: d?.freeQty?.toString() ?? '');
    _minQtyController =
        TextEditingController(text: d?.minQty?.toString() ?? '');
    _discountPercentController =
        TextEditingController(text: d?.discountPercent?.toString() ?? '');
    _type = d?.type ?? DiscountType.percentage;
    _scope = d?.scope ?? DiscountScope.product;
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

  String? _validatePositiveDouble(String? v, String label,
      {double min = 0, double max = 100}) {
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

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

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
          ? double.parse(_valueController.text.trim())
          : null,
      buyQty: _type == DiscountType.bogo
          ? int.parse(_buyQtyController.text.trim())
          : null,
      freeQty: _type == DiscountType.bogo
          ? int.parse(_freeQtyController.text.trim())
          : null,
      minQty: _type == DiscountType.bulk
          ? int.parse(_minQtyController.text.trim())
          : null,
      discountPercent: _type == DiscountType.bulk
          ? double.parse(_discountPercentController.text.trim())
          : null,
    );

    try {
      if (_isEditing) {
        await service.updateDiscount(discount);
      } else {
        await service.createDiscount(discount);
      }
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
    final categoriesAsync = ref.watch(adminCategoriesProvider);
    final productsAsync = ref.watch(adminProductsProvider);

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
                _isEditing ? 'Edit Discount' : 'Create Discount',
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
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              // Type dropdown
              DropdownButtonFormField<DiscountType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                      value: DiscountType.percentage,
                      child: Text('Percentage')),
                  DropdownMenuItem(
                      value: DiscountType.bogo, child: Text('BOGO')),
                  DropdownMenuItem(
                      value: DiscountType.bulk, child: Text('Bulk')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              // Scope dropdown
              DropdownButtonFormField<DiscountScope>(
                value: _scope,
                decoration: const InputDecoration(labelText: 'Scope'),
                items: const [
                  DropdownMenuItem(
                      value: DiscountScope.product, child: Text('Product')),
                  DropdownMenuItem(
                      value: DiscountScope.category, child: Text('Category')),
                ],
                onChanged: (v) => setState(() {
                  _scope = v!;
                  _targetId = null;
                }),
              ),
              const SizedBox(height: 12),
              // Target selector
              if (_scope == DiscountScope.category)
                categoriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading categories: $e',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  data: (categories) => DropdownButtonFormField<String>(
                    value: _targetId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _targetId = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Category is required' : null,
                  ),
                )
              else
                productsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading products: $e',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  data: (products) => DropdownButtonFormField<String>(
                    value: _targetId,
                    decoration: const InputDecoration(labelText: 'Product'),
                    items: products
                        .map((p) => DropdownMenuItem(
                            value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _targetId = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Product is required' : null,
                  ),
                ),
              const SizedBox(height: 12),
              // Type-specific fields
              if (_type == DiscountType.percentage) ...[
                TextFormField(
                  controller: _valueController,
                  decoration: const InputDecoration(labelText: 'Discount %'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      _validatePositiveDouble(v, 'Discount %'),
                ),
              ],
              if (_type == DiscountType.bogo) ...[
                TextFormField(
                  controller: _buyQtyController,
                  decoration: const InputDecoration(labelText: 'Buy Qty'),
                  keyboardType: TextInputType.number,
                  validator: (v) => _validatePositiveInt(v, 'Buy Qty'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _freeQtyController,
                  decoration: const InputDecoration(labelText: 'Free Qty'),
                  keyboardType: TextInputType.number,
                  validator: (v) => _validatePositiveInt(v, 'Free Qty'),
                ),
              ],
              if (_type == DiscountType.bulk) ...[
                TextFormField(
                  controller: _minQtyController,
                  decoration: const InputDecoration(labelText: 'Min Qty'),
                  keyboardType: TextInputType.number,
                  validator: (v) => _validatePositiveInt(v, 'Min Qty', min: 2),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discountPercentController,
                  decoration: const InputDecoration(labelText: 'Discount %'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      _validatePositiveDouble(v, 'Discount %'),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Create Discount'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
