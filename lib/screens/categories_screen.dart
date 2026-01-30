import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import 'package:uuid/uuid.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final c = categories[index];
          return ListTile(
            leading: CircleAvatar(backgroundColor: Color(c.colorValue)),
            title: Text(c.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => ref.read(categoryProvider.notifier).delete(c.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(categoryProvider.notifier).add(CategoryModel(
                    id: const Uuid().v4(),
                    name: nameCtrl.text,
                    colorValue: 0xFF9E9E9E, // Default grey
                    iconCode:
                        58826, // Icons.category (0xe16a) as int, but let's use a safe default 0xe57f (shopping_cart)
                  ));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }
}
