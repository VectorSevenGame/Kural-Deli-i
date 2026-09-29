import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/inventory_store.dart';
import '../../data/models/item.dart';
import '../../data/models/room.dart';
import '../item/item_detail_screen.dart';
import '../item/item_edit_screen.dart';
import '../widgets/item_photo.dart';
import '../widgets/warranty_badge.dart';

/// Ana ekran: oda oda esya listesi.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InventoryStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home_outlined),
            tooltip: 'Oda ekle',
            onPressed: () => _promptNewRoom(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Esya ekle'),
      ),
      body: store.loading
          ? const Center(child: CircularProgressIndicator())
          : store.items.isEmpty
              ? const _EmptyState()
              : _RoomList(store: store),
    );
  }

  static Future<void> _openEditor(BuildContext context, {Item? item}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ItemEditScreen(item: item)),
    );
  }

  static Future<void> _promptNewRoom(BuildContext context) async {
    final store = context.read<InventoryStore>();
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Oda ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Orn. Cocuk Odasi'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await store.addRoom(name);
    }
  }
}

class _RoomList extends StatelessWidget {
  const _RoomList({required this.store});

  final InventoryStore store;

  @override
  Widget build(BuildContext context) {
    final sections = <(String, List<Item>)>[
      for (final Room room in store.rooms)
        (room.name, store.itemsInRoom(room.id)),
      if (store.unassignedItems.isNotEmpty)
        ('Odasiz', store.unassignedItems),
    ].where((section) => section.$2.isNotEmpty).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final (name, items) = sections[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Row(
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${items.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            for (final item in items) _ItemCard(item: item),
          ],
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final subtitle = [item.brand, item.model]
        .where((value) => value != null && value.isNotEmpty)
        .join(' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(itemId: item.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ItemPhoto(path: item.photoPath),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      WarrantyBadge(item: item),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: scheme.primary),
            const SizedBox(height: 24),
            Text(
              'En pahali esyanla basla',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Buzdolabi, televizyon, kombi... Faturasini ekle, '
              'garantisinin ne zaman bittigini bir daha hic merak etme.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
