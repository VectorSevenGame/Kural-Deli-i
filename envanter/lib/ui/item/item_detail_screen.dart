import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/inventory_store.dart';
import '../../data/models/item.dart';
import '../../util/formatters.dart';
import '../widgets/item_photo.dart';
import '../widgets/warranty_badge.dart';
import 'item_edit_screen.dart';

/// Tek esyanin detayi: kunye, satin alma, garanti.
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InventoryStore>();
    final item = store.itemById(itemId);

    // Esya silindiyse ekran bir kare bos kalabilir; geri don.
    if (item == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final roomName = item.roomId == null
        ? 'Odasiz'
        : store.rooms
            .where((r) => r.id == item.roomId)
            .map((r) => r.name)
            .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Duzenle',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => ItemEditScreen(item: item)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Sil',
            onPressed: () => _confirmDelete(context, item),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: ItemPhoto(path: item.photoPath, size: 200, radius: 24),
          ),
          const SizedBox(height: 20),
          Center(child: WarrantyBadge(item: item)),
          if (item.warrantyEndDate != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Bitis: ${formatDate(item.warrantyEndDate)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          _Fields(
            title: 'Kunye',
            rows: [
              ('Kategori', item.category.label),
              ('Oda', roomName ?? 'Odasiz'),
              ('Marka', item.brand),
              ('Model', item.model),
              ('Seri no', item.serialNumber),
            ],
          ),
          _Fields(
            title: 'Satin alma',
            rows: [
              ('Tarih', formatDate(item.purchaseDate)),
              ('Fiyat', formatPrice(item.priceKurus)),
              ('Nereden', item.seller),
            ],
          ),
          if (item.note != null) _Fields(title: 'Not', rows: [(null, item.note)]),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Item item) async {
    final store = context.read<InventoryStore>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('"${item.name}" silinsin mi?'),
        content: const Text(
          'Esya, fotografi ve bagli belgeleri kalici olarak silinir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await store.deleteItem(item.id);
      navigator.pop();
    }
  }
}

class _Fields extends StatelessWidget {
  const _Fields({required this.title, required this.rows});

  final String title;
  final List<(String?, String?)> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = rows.where((r) => r.$2 != null && r.$2!.isNotEmpty);
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (final (label, value) in visible)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (label != null)
                            SizedBox(
                              width: 110,
                              child: Text(
                                label,
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              value!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
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
