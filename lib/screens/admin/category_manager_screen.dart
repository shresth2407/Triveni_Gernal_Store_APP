import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/admin/admin_data_providers.dart';
import '../../providers/admin/admin_service_providers.dart';

class CategoryManagerScreen extends ConsumerWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Category Manager')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBanner(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminCategoriesProvider),
        ),
        data: (categories) => categories.isEmpty
            ? const Center(child: Text('No categories yet.'))
            : ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    title: Text(category.name),
                    subtitle: Text('Sort order: ${category.sortOrder}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openCategoryForm(context, ref, category: category),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategoryForm(context, ref),
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openCategoryForm(BuildContext context, WidgetRef ref, {Category? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryFormSheet(
        category: category,
        onSaved: () => ref.invalidate(adminCategoriesProvider),
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

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({this.category, required this.onSaved});

  final Category? category;
  final VoidCallback onSaved;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _sortOrderController;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _imageUrlController = TextEditingController(text: widget.category?.imageUrl ?? '');
    _sortOrderController = TextEditingController(
      text: widget.category != null ? widget.category!.sortOrder.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final service = ref.read(adminProductServiceProvider);
    final category = Category(
      id: widget.category?.id ??
          FirebaseFirestore.instance.collection('categories').doc().id,
      name: _nameController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      sortOrder: int.parse(_sortOrderController.text.trim()),
    );

    try {
      if (_isEditing) {
        await service.updateCategory(category);
      } else {
        await service.addCategory(category);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Category' : 'Add Category',
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
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'Image URL'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Image URL is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sortOrderController,
              decoration: const InputDecoration(labelText: 'Sort Order'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Sort order is required';
                if (int.tryParse(v.trim()) == null) return 'Must be a whole number';
                return null;
              },
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
                  : Text(_isEditing ? 'Save Changes' : 'Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}
