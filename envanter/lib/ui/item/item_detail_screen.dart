import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/inventory_store.dart';
import '../../data/models/item.dart';
import '../../domain/warranty.dart';
import '../../util/formatters.dart';
import '../widgets/item_photo.dart';
import '../widgets/warranty_pill.dart';
import 'item_edit_screen.dart';

/// Eşya detayı: kimlik, garanti sayacı, künye.
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InventoryStore>();
    final item = store.itemById(itemId);
    final scheme = Theme.of(context).colorScheme;

    // Eşya silindiyse ekran bir kare boş kalabilir.
    if (item == null) return const Scaffold(body: SizedBox.shrink());

    final roomName = store.rooms
        .where((r) => r.id == item.roomId)
        .map((r) => r.name)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eşya Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Sil',
            onPressed: () => _confirmDelete(context, item),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    side: BorderSide(color: scheme.outline),
                    foregroundColor: scheme.onSurface,
                  ),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ItemEditScreen(item: item),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Düzenle'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ItemPhoto(
                path: item.photoPath,
                size: double.infinity,
                radius: 22,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SoftChip(label: roomName ?? 'Odasız', icon: Icons.room_outlined),
              SoftChip(label: item.category.label),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 24),
                ),
              ),
              if (item.priceKurus != null) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPrice(item.priceKurus),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                    Text(
                      'Fatura Tutarı',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (item.model != null) ...[
            const SizedBox(height: 4),
            Text(
              item.brand == null
                  ? item.model!
                  : '${item.brand} · ${item.model}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
          ],
          const SizedBox(height: 20),
          _WarrantyCard(item: item),
          const SectionHeader('Eşya künyesi'),
          _FieldGrid(
            fields: [
              (Icons.event_outlined, 'Satın Alınma', formatDate(item.purchaseDate)),
              (Icons.storefront_outlined, 'Satıcı Mağaza', item.seller),
              (Icons.category_outlined, 'Kategori', item.category.label),
              (Icons.sell_outlined, 'Marka', item.brand),
            ],
          ),
          if (item.serialNumber != null) ...[
            const SizedBox(height: 12),
            _SerialRow(serial: item.serialNumber!),
          ],
          if (item.note != null) ...[
            const SectionHeader('Not'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(item.note!, style: const TextStyle(height: 1.5)),
              ),
            ),
          ],
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
          'Eşya, fotoğrafı ve bağlı belgeleri kalıcı olarak silinir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
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

class _WarrantyCard extends StatelessWidget {
  const _WarrantyCard({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final status = item.warrantyStatus(now: now);
    final days = item.warrantyDaysRemaining(now: now);
    final progress = Warranty.progress(
      item.purchaseDate,
      item.warrantyMonths,
      now: now,
    );
    final colors = warrantyColors(context, status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(colors.icon, size: 18, color: colors.foreground),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Garanti Durumu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  warrantyStatusLabel(status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                ),
              ),
            ],
          ),
          if (days == null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'Alım tarihi ve garanti süresi girilirse buradan geri sayım '
                'yapılır.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                  fontSize: 13,
                ),
              ),
            )
          else ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  days < 0 ? '${-days}' : '$days',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: status == WarrantyStatus.expired
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  days < 0 ? 'Gün Önce Bitti' : 'Gün Kaldı',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (progress != null)
                  Text(
                    '%${(progress * 100).round()} Geçti',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: status == WarrantyStatus.active
                    ? scheme.secondary
                    : scheme.tertiary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DateStamp(
                  icon: Icons.event_available_outlined,
                  text: formatShortDate(item.purchaseDate),
                ),
                _DateStamp(
                  icon: Icons.flag_outlined,
                  text: formatShortDate(item.warrantyEndDate),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DateStamp extends StatelessWidget {
  const _DateStamp({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.fields});

  final List<(IconData, String, String?)> fields;

  @override
  Widget build(BuildContext context) {
    final visible = fields
        .where((f) => f.$3 != null && f.$3!.isNotEmpty && f.$3 != '—')
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (icon, label, value) in visible)
          LayoutBuilder(
            builder: (context, _) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 44) / 2,
              child: _FieldTile(icon: icon, label: label, value: value!),
            ),
          ),
      ],
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SerialRow extends StatelessWidget {
  const _SerialRow({required this.serial});

  final String serial;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_2, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seri Numarası',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  serial,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: serial));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seri numarası kopyalandı')),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 15),
            label: const Text('Kopyala'),
          ),
        ],
      ),
    );
  }
}
