import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/item.dart';
import '../providers/items_provider.dart';
import '../services/item_service.dart';
import '../widgets/shop_controls.dart';

/// Admin screen for creating, editing, and deleting items. Shares the same
/// Riverpod state (page + filter) as the shop, so changes show up there too.
class ManageItemsScreen extends ConsumerWidget {
  const ManageItemsScreen({super.key});

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, [
    Item? item,
  ]) async {
    final result = await showDialog<_ItemFormResult>(
      context: context,
      builder: (_) => _ItemFormDialog(item: item),
    );
    if (result == null || !context.mounted) return;

    final controller = ref.read(itemsControllerProvider.notifier);
    try {
      if (item == null) {
        await controller.createItem(
          name: result.name,
          description: result.description,
          imageUrl: result.imageUrl,
          price: result.price,
          image: result.image,
        );
      } else {
        await controller.updateItem(
          item,
          name: result.name,
          description: result.description,
          imageUrl: result.imageUrl,
          price: result.price,
          image: result.image,
        );
      }
      if (context.mounted) {
        _showSnack(context, item == null ? 'Item added' : 'Item updated');
      }
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Save failed: $e');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('"${item.name}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(itemsControllerProvider.notifier).deleteItem(item);
      if (context.mounted) _showSnack(context, 'Item deleted');
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itemsControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MANAGE ITEMS'),
        bottom: busyIndicator(state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.saving ? null : () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('ADD ITEM'),
      ),
      bottomNavigationBar: const PaginationBar(),
      body: Column(
        children: [
          const PriceFilterBar(),
          Expanded(
            child: AbsorbPointer(
              absorbing: state.saving,
              child: ItemsStateView(
                builder: (context, items) => ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ItemImage(
                            url: item.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item.displayPrice ?? 'No price',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => _openForm(context, ref, item),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit',
                              onPressed: () => _openForm(context, ref, item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete',
                              onPressed: () =>
                                  _confirmDelete(context, ref, item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Parses user input like "1,250.50" into a number rounded to 2 decimals.
/// Returns null for empty or invalid input.
double? _parsePrice(String input) {
  final cleaned = input.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null) return null;
  return (value * 100).round() / 100;
}

class _ItemFormResult {
  final String name;
  final String description;
  final double? price;

  /// Image URL to save when no new file was picked (may be empty to clear).
  final String imageUrl;

  /// Newly picked file to upload, if any. Takes priority over [imageUrl].
  final PickedImage? image;

  const _ItemFormResult(
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.image,
  );
}

class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog({this.item});

  final Item? item;

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _description = TextEditingController(
    text: widget.item?.description,
  );
  late final _imageUrl = TextEditingController(text: widget.item?.imageUrl);
  late final _price = TextEditingController(
    text: widget.item?.price?.toStringAsFixed(2),
  );

  PickedImage? _picked;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _price.dispose();
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
      final name = file.name;
      final dot = name.lastIndexOf('.');
      final ext = dot == -1 ? 'jpg' : name.substring(dot + 1);
      setState(() {
        _picked = PickedImage(bytes, ext);
        _imageUrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  void _removeImage() {
    setState(() {
      _picked = null;
      _imageUrl.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ItemFormResult(
        _name.text,
        _description.text,
        _parsePrice(_price.text),
        _imageUrl.text,
        _picked,
      ),
    );
  }

  Widget _preview() {
    final url = _imageUrl.text.trim();
    Widget child;
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
      child = const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 160,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final hasImage = _picked != null || _imageUrl.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(isEdit ? 'Edit item' : 'Add item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _preview(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(hasImage ? 'Change image' : 'Pick image'),
                    ),
                  ),
                  if (hasImage) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove image',
                    ),
                  ],
                ],
              ),
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(
                  labelText: 'or paste an image URL',
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() => _picked = null),
              ),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                minLines: 1,
              ),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '$currencySymbol ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final price = _parsePrice(v);
                  if (price == null) return 'Enter a valid number';
                  if (price < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(isEdit ? 'Save' : 'Add')),
      ],
    );
  }
}
