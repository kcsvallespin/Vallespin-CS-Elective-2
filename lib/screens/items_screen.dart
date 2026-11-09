import 'package:flutter/material.dart';

import '../models/item.dart';
import '../services/item_service.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _service = ItemService();

  List<Item> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchItems();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm([Item? item]) async {
    final result = await showDialog<_ItemFormResult>(
      context: context,
      builder: (_) => _ItemFormDialog(item: item),
    );
    if (result == null) return;

    try {
      if (item == null) {
        final created = await _service.createItem(
          name: result.name,
          description: result.description,
          imageUrl: result.imageUrl,
        );
        setState(() => _items.insert(0, created));
        _showSnack('Item added');
      } else {
        final updated = await _service.updateItem(
          item.id,
          name: result.name,
          description: result.description,
          imageUrl: result.imageUrl,
        );
        setState(() {
          final i = _items.indexWhere((x) => x.id == item.id);
          if (i != -1) _items[i] = updated;
        });
        _showSnack('Item updated');
      }
    } catch (e) {
      _showSnack('Save failed: $e');
    }
  }

  Future<void> _confirmDelete(Item item) async {
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
    if (confirmed != true) return;

    try {
      await _service.deleteItem(item.id);
      setState(() => _items.removeWhere((x) => x.id == item.id));
      _showSnack('Item deleted');
    } catch (e) {
      _showSnack('Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(child: Text('No items yet. Tap + to add one.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            leading: _ItemImage(url: item.imageUrl),
            title: Text(item.name),
            subtitle: item.description == null
                ? null
                : Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () => _openForm(item),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(item),
            ),
          );
        },
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const placeholder = CircleAvatar(child: Icon(Icons.inventory_2_outlined));
    if (url == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _ItemFormResult {
  final String name;
  final String description;
  final String imageUrl;

  const _ItemFormResult(this.name, this.description, this.imageUrl);
}

class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog({this.item});

  final Item? item;

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _description =
      TextEditingController(text: widget.item?.description);
  late final _imageUrl = TextEditingController(text: widget.item?.imageUrl);

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ItemFormResult(_name.text, _description.text, _imageUrl.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit item' : 'Add item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
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
                controller: _imageUrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
                keyboardType: TextInputType.url,
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
        FilledButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
