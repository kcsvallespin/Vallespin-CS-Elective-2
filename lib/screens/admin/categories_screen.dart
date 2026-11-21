import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product_category.dart';
import '../../providers/categories_provider.dart';
import '../../utils/errors.dart';
import '../../widgets/status_message.dart';

/// Admin screen to add, rename and delete categories.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    ProductCategory? category,
  ]) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryDialog(initial: category?.name),
    );
    if (name == null || !context.mounted) return;
    final controller = ref.read(categoriesControllerProvider.notifier);
    try {
      if (category == null) {
        await controller.create(name);
      } else {
        await controller.rename(category, name);
      }
      if (context.mounted) {
        showSnack(
          context,
          category == null ? 'Added "$name"' : 'Renamed to "$name"',
        );
      }
    } catch (e) {
      if (context.mounted) showSnack(context, 'Save failed: ${errorMessage(e)}');
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ProductCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text('Delete "${category.name}"?'),
        content: Text(
          'The category "${category.name}" will be deleted. Categories that '
          'still have products cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(categoriesControllerProvider.notifier).delete(category);
      if (context.mounted) showSnack(context, 'Deleted "${category.name}"');
    } catch (e) {
      if (context.mounted) {
        showSnack(context, 'Delete failed: ${errorMessage(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: AsyncValueView(
        value: categories,
        onRetry: () =>
            ref.read(categoriesControllerProvider.notifier).refresh(),
        data: (list) => list.isEmpty
            ? const StatusMessage(
                icon: Icons.category_outlined,
                message: 'No categories yet. Add one to start adding '
                    'products.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final c = list[i];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.label_outline),
                          title: Text(c.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _edit(context, ref, c),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Rename',
                              ),
                              IconButton(
                                onPressed: () => _delete(context, ref, c),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.initial});

  final String? initial;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add category' : 'Rename category'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
