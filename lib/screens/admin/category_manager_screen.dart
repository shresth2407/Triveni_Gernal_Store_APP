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

class CategoryManagerScreen extends ConsumerWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

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
                background: _HeroHeader(onAddTap: () => _openCategoryForm(context, ref)),
              ),
            ),

            // ── Section label ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: categoriesAsync.maybeWhen(
                  data: (cats) => Row(
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
                      const Text('All Categories',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextDark)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kLightRed,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kRoseBorder, width: 1.5),
                        ),
                        child: Text('${cats.length} total',
                            style: const TextStyle(fontSize: 11, color: _kRed, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ),

            // ── List / states ──────────────────────────────────────
            categoriesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _kRed)),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorCard(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(adminCategoriesProvider),
                ),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyCategoriesCard());
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _CategoryCard(
                        category: categories[index],
                        index: index,
                        onTap: () => _openCategoryForm(context, ref, category: categories[index]),
                      ),
                      childCount: categories.length,
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

  void _openCategoryForm(BuildContext context, WidgetRef ref, {Category? category}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(
        category: category,
        onSaved: () => ref.invalidate(adminCategoriesProvider),
      ),
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
          // Decorative circles
          Positioned(right: -30, top: -30,
              child: Container(width: 130, height: 130,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
          Positioned(right: 40, bottom: 20,
              child: Container(width: 70, height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
          Positioned(left: -20, bottom: -20,
              child: Container(width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),

          // Content
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
                        child: const Icon(Icons.category_rounded, color: _kWhite, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category Manager',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kWhite)),
                          Text('Organise your store sections',
                              style: TextStyle(fontSize: 11, color: Colors.white60)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── ADD CATEGORY inline banner ─────────────────
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
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text('Add New Category',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextDark)),
                                Text('Tap to create a store category',
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

// ─── CATEGORY CARD ────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final Category category;
  final int index;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.index, required this.onTap});

  static const _gradients = [
    [Color(0xFFB22222), Color(0xFFDC143C)],
    [Color(0xFF1565C0), Color(0xFF1E88E5)],
    [Color(0xFF2E7D32), Color(0xFF43A047)],
    [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
    [Color(0xFFE65100), Color(0xFFFF6D00)],
    [Color(0xFF00695C), Color(0xFF00897B)],
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[index % _gradients.length];

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
          child: Row(
            children: [
              // Image with index badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: category.imageUrl.isNotEmpty
                        ? Image.network(
                      category.imageUrl,
                      width: 58, height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _GradientPlaceholder(gradient: gradient),
                    )
                        : _GradientPlaceholder(gradient: gradient),
                  ),
                  Positioned(
                    top: -2, left: -2,
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        shape: BoxShape.circle,
                        border: Border.all(color: _kWhite, width: 1.5),
                      ),
                      child: Center(
                        child: Text('${index + 1}',
                            style: const TextStyle(color: _kWhite, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextDark)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MiniTag(icon: Icons.sort_rounded, label: 'Sort: ${category.sortOrder}'),
                        const SizedBox(width: 6),
                        _MiniTag(
                          icon: Icons.circle,
                          label: 'Active',
                          dotColor: gradient.last,
                          dotBg: gradient.last.withOpacity(0.1),
                          dotBorder: gradient.last.withOpacity(0.25),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(color: gradient.last.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.edit_rounded, color: _kWhite, size: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  final List<Color> gradient;
  const _GradientPlaceholder({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58, height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.category_rounded, color: _kWhite, size: 28),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? dotColor;
  final Color? dotBg;
  final Color? dotBorder;

  const _MiniTag({
    required this.icon,
    required this.label,
    this.dotColor,
    this.dotBg,
    this.dotBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDot = dotColor != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDot ? dotBg : _kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDot ? dotBorder! : _kRoseBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isDot
              ? Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle))
              : Icon(icon, size: 10, color: _kTextMid),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                color: isDot ? dotColor : _kTextMid,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

// ─── EMPTY STATE ──────────────────────────────────────────────────
class _EmptyCategoriesCard extends StatelessWidget {
  const _EmptyCategoriesCard();

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
              child: const Icon(Icons.category_outlined, size: 38, color: _kRoseBorder),
            ),
            const SizedBox(height: 16),
            const Text('No categories yet',
                style: TextStyle(color: _kTextDark, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Use the "Add New Category" button above\nto get started',
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
              Text(message,
                  textAlign: TextAlign.center,
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

// ─── CATEGORY FORM SHEET ──────────────────────────────────────────
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
    _nameController      = TextEditingController(text: widget.category?.name ?? '');
    _imageUrlController  = TextEditingController(text: widget.category?.imageUrl ?? '');
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
    setState(() { _isSubmitting = true; _errorMessage = null; });
    HapticFeedback.mediumImpact();

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
      setState(() { _errorMessage = e.toString(); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
        child: Form(
          key: _formKey,
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

              // Sheet header — light gradient card
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
                      child: Icon(_isEditing ? Icons.edit_rounded : Icons.add_rounded, color: _kWhite, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Edit Category' : 'New Category',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _kTextDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isEditing ? 'Update the details below' : 'Fill in the details below',
                            style: const TextStyle(fontSize: 11, color: _kTextGrey),
                          ),
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

              // Fields
              _StyledField(
                controller: _nameController,
                label: 'Category Name',
                icon: Icons.label_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              _StyledField(
                controller: _imageUrlController,
                label: 'Image URL',
                icon: Icons.image_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Image URL is required' : null,
              ),
              const SizedBox(height: 12),
              _StyledField(
                controller: _sortOrderController,
                label: 'Sort Order',
                icon: Icons.sort_rounded,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Sort order is required';
                  if (int.tryParse(v.trim()) == null) return 'Must be a whole number';
                  return null;
                },
              ),
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
                    boxShadow: _isSubmitting
                        ? []
                        : [BoxShadow(color: _kRed.withOpacity(0.38), blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: _kWhite))
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded, color: _kWhite, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _isEditing ? 'Save Changes' : 'Add Category',
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
        border:            OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kRoseBorder, width: 1.5)),
        enabledBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kRoseBorder, width: 1.5)),
        focusedBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kRed, width: 2)),
        errorBorder:       OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kDarkRed, width: 1.5)),
        focusedErrorBorder:OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kDarkRed, width: 2)),
      ),
    );
  }
}