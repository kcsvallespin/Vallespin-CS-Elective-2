import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/item.dart';
import '../providers/items_provider.dart';
import '../services/item_service.dart';
import '../widgets/item_card.dart';
import '../widgets/status_message.dart';

/// Parses user input like "1,250.50" into a number rounded to 2 decimals.
/// Returns null for empty or invalid input.
double? _parsePrice(String input) {
  final cleaned = input.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null) return null;
  return (value * 100).round() / 100;
}

class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({super.key});

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
    final controller = ref.read(itemsControllerProvider.notifier);
    final busy = state.loading || state.saving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: busy ? null : controller.refresh,
          ),
        ],
        bottom: busy && state.items.isNotEmpty
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.saving ? null : () => _openForm(context, ref),
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const _PaginationBar(),
      body: Column(
        children: [
          const _PriceFilterBar(),
          Expanded(
            child: AbsorbPointer(
              absorbing: state.saving,
              child: _buildContent(context, ref, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ItemsState state) {
    final controller = ref.read(itemsControllerProvider.notifier);

    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return StatusMessage(
        icon: Icons.wifi_off,
        message: 'Something went wrong while loading items.\n${state.error}',
        actionLabel: 'Retry',
        onAction: controller.refresh,
      );
    }
    if (state.items.isEmpty) {
      return state.priceFilter != null
          ? StatusMessage(
              icon: Icons.filter_alt_off_outlined,
              message: 'No items in this price range.',
              actionLabel: 'Clear filter',
              onAction: () => controller.setPriceFilter(null),
            )
          : StatusMessage(
              icon: Icons.inventory_2_outlined,
              message: 'No items yet. Tap + to add one.',
              actionLabel: 'Reload',
              onAction: controller.refresh,
            );
    }

    // Adaptive grid: as many ~180px-wide columns as fit the screen.
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return ItemCard(
            item: item,
            onTap: () => _openForm(context, ref, item),
            onDelete: () => _confirmDelete(context, ref, item),
          );
        },
      ),
    );
  }
}

/// Price range slider. Dragging only updates the labels; the Supabase query
/// runs when the user lets go, so we don't send a request per pixel.
class _PriceFilterBar extends ConsumerStatefulWidget {
  const _PriceFilterBar();

  @override
  ConsumerState<_PriceFilterBar> createState() => _PriceFilterBarState();
}

class _PriceFilterBarState extends ConsumerState<_PriceFilterBar> {
  RangeValues? _dragging;

  String _money(double v) => '$currencySymbol${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemsControllerProvider);
    final theme = Theme.of(context);
    final max = state.maxPrice;
    if (max <= 0) return const SizedBox.shrink();

    final applied = state.priceFilter ?? RangeValues(0, max);
    final values = _dragging ?? applied;
    final filtering = state.priceFilter != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Price', style: theme.textTheme.titleSmall),
              const SizedBox(width: 12),
              Text(
                '${_money(values.start)} – ${_money(values.end)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (filtering)
                TextButton(
                  onPressed: () => ref
                      .read(itemsControllerProvider.notifier)
                      .setPriceFilter(null),
                  child: const Text('Clear'),
                ),
            ],
          ),
          RangeSlider(
            min: 0,
            max: max,
            divisions: max.round().clamp(1, 1000),
            values: RangeValues(
              values.start.clamp(0, max),
              values.end.clamp(0, max),
            ),
            labels: RangeLabels(_money(values.start), _money(values.end)),
            onChanged: (v) => setState(() => _dragging = v),
            onChangeEnd: (v) {
              setState(() => _dragging = null);
              ref.read(itemsControllerProvider.notifier).setPriceFilter(v);
            },
          ),
          if (filtering)
            Text(
              'Items without a price are hidden while filtering.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }
}

/// Previous / next controls with "Page X of Y".
class _PaginationBar extends ConsumerWidget {
  const _PaginationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itemsControllerProvider);
    final controller = ref.read(itemsControllerProvider.notifier);
    final theme = Theme.of(context);
    final busy = state.loading || state.saving;

    if (state.totalCount == 0) return const SizedBox.shrink();

    final first = state.page * ItemsState.pageSize + 1;
    final last = first + state.items.length - 1;

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
                onPressed: state.hasPrevious && !busy
                    ? () => controller.goToPage(state.page - 1)
                    : null,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Page ${state.page + 1} of ${state.pageCount}',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      'Showing $first–$last of ${state.totalCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
                onPressed: state.hasNext && !busy
                    ? () => controller.goToPage(state.page + 1)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
