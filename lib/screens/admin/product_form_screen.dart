import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product.dart';
import '../../providers/categories_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/product_service.dart' show PickedImage, ProductInput;
import '../../utils/errors.dart';
import '../../utils/format.dart';
import '../../widgets/status_message.dart';
import 'categories_screen.dart';

/// Add or edit a product (admin only). When editing, every field starts
/// with the product's current value.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({this.product, super.key});

  final Product? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _description =
      TextEditingController(text: widget.product?.description);
  late final _price =
      TextEditingController(text: widget.product?.price.toStringAsFixed(2));
  late final _stock =
      TextEditingController(text: widget.product?.stock.toString());
  late final _imageUrl =
      TextEditingController(text: widget.product?.imageUrl);
  late int? _categoryId = widget.product?.categoryId;

  PickedImage? _picked;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final dot = file.name.lastIndexOf('.');
      final ext = dot == -1 ? 'jpg' : file.name.substring(dot + 1);
      setState(() {
        _picked = PickedImage(bytes, ext);
        _imageUrl.clear();
      });
    } catch (e) {
      if (mounted) showSnack(context, 'Could not pick image: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final input = ProductInput(
      name: _name.text,
      description: _description.text,
      price: _parsePrice(_price.text)!,
      stock: int.parse(_stock.text.trim()),
      categoryId: _categoryId!,
      imageUrl: _imageUrl.text,
      image: _picked,
    );

    setState(() => _saving = true);
    final products = ref.read(productsControllerProvider.notifier);
    try {
      if (_isEdit) {
        await products.update(widget.product!, input);
      } else {
        await products.create(input);
      }
      if (!mounted) return;
      showSnack(context, _isEdit ? 'Product updated' : 'Product added');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, 'Save failed: ${errorMessage(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesControllerProvider);
    final hasImage = _picked != null || _imageUrl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit product' : 'Add product'),
        bottom: _saving
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _preview(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(
                                hasImage ? 'Change image' : 'Upload image',
                              ),
                            ),
                          ),
                          if (hasImage) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => setState(() {
                                _picked = null;
                                _imageUrl.clear();
                              }),
                              icon: const Icon(Icons.close),
                              tooltip: 'Remove image',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'or paste an image URL',
                          prefixIcon: Icon(Icons.link),
                        ),
                        onChanged: (_) => setState(() => _picked = null),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Name *'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _description,
                        textCapitalization: TextCapitalization.sentences,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        minLines: 2,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _price,
                              decoration: const InputDecoration(
                                labelText: 'Price *',
                                prefixText: '$currencySymbol ',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Price is required';
                                }
                                final price = _parsePrice(v);
                                if (price == null) return 'Enter a number';
                                if (price < 0) return 'Must be 0 or more';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stock,
                              decoration:
                                  const InputDecoration(labelText: 'Stock *'),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final text = v?.trim() ?? '';
                                if (text.isEmpty) return 'Stock is required';
                                final stock = int.tryParse(text);
                                if (stock == null) return 'Whole number only';
                                if (stock < 0) return 'Must be 0 or more';
                                if (stock > 32767) return 'Max 32767';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      categories.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => _CategoryProblem(
                          message:
                              'Could not load categories: ${errorMessage(e)}',
                          actionLabel: 'Retry',
                          onAction: () => ref
                              .read(categoriesControllerProvider.notifier)
                              .refresh(),
                        ),
                        data: (list) {
                          if (list.isEmpty) {
                            return _CategoryProblem(
                              message: 'Add a category before adding '
                                  'products.',
                              actionLabel: 'Manage categories',
                              onAction: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CategoriesScreen(),
                                ),
                              ),
                            );
                          }
                          final valid = list.any((c) => c.id == _categoryId);
                          return DropdownButtonFormField<int>(
                            initialValue: valid ? _categoryId : null,
                            decoration:
                                const InputDecoration(labelText: 'Category *'),
                            items: [
                              for (final c in list)
                                DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                            ],
                            onChanged: (id) => setState(() => _categoryId = id),
                            validator: (id) =>
                                id == null ? 'Choose a category' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isEdit ? 'Save changes' : 'Add product'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    final url = _imageUrl.text.trim();
    final Widget child;
    if (_picked != null) {
      child = Image.memory(_picked!.bytes, fit: BoxFit.cover);
    } else if (url.isNotEmpty) {
      child = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
      );
    } else {
      child = Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: child,
      ),
    );
  }
}

/// Parses input like "1,250.50" into a number rounded to 2 decimals.
double? _parsePrice(String input) {
  final value = double.tryParse(input.replaceAll(',', '').trim());
  if (value == null || !value.isFinite) return null;
  return (value * 100).round() / 100;
}

class _CategoryProblem extends StatelessWidget {
  const _CategoryProblem({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.category_outlined),
        title: Text(message),
        trailing: TextButton(onPressed: onAction, child: Text(actionLabel)),
      ),
    );
  }
}
