import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/inventory_store.dart';
import '../../data/models/item.dart';
import '../../domain/warranty.dart';
import '../../util/formatters.dart';
import '../item/item_detail_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/item_photo.dart';
import '../widgets/warranty_pill.dart';

/// Garanti & Bakım Takvimi: biten, yaklaşan ve güvende olan eşyalar.
class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

enum _Filter {
  all('Tümü'),
  thisMonth('Bu Ay Bitenler'),
  soon('Yaklaşanlar');

  const _Filter(this.label);

  final String label;
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InventoryStore>();
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final watchlist = store.warrantyWatchlist(now: now);
    // Önce bitmek üzere olanlar (en yakın önde), sonra bitmişler (en yeni
    // bitmiş önde). Kullanıcı için acil olan sıranın başında durmalı.
    final expiringSoon = watchlist
        .where((i) => i.warrantyStatus(now: now) == WarrantyStatus.expiringSoon)
        .toList();
    final expired = watchlist
        .where((i) => i.warrantyStatus(now: now) == WarrantyStatus.expired)
        .toList()
        .reversed
        .toList();
    final urgent = [...expiringSoon, ...expired];
    final safe = watchlist
        .where((i) => i.warrantyStatus(now: now) == WarrantyStatus.active)
        .toList();

    final visibleUrgent = switch (_filter) {
      _Filter.all => urgent,
      _Filter.thisMonth => urgent
          .where((i) =>
              i.warrantyEndDate != null &&
              i.warrantyEndDate!.year == now.year &&
              i.warrantyEndDate!.month == now.month)
          .toList(),
      _Filter.soon => urgent
          .where((i) =>
              i.warrantyStatus(now: now) == WarrantyStatus.expiringSoon)
          .toList(),
    };

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            const AppHeader(subtitle: 'Garanti · Bakım'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: scheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'HUZURLU YUVA TAKİBİ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Garanti & Bakım Takvimi',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sürpriz masraflara son. Yaklaşan tüm tarihler kontrol altında.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final filter in _Filter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _FilterChip(
                        label: filter.label,
                        count: switch (filter) {
                          _Filter.all => urgent.length,
                          _Filter.thisMonth => urgent
                              .where((i) =>
                                  i.warrantyEndDate != null &&
                                  i.warrantyEndDate!.year == now.year &&
                                  i.warrantyEndDate!.month == now.month)
                              .length,
                          _Filter.soon => urgent
                              .where((i) =>
                                  i.warrantyStatus(now: now) ==
                                  WarrantyStatus.expiringSoon)
                              .length,
                        },
                        selected: _filter == filter,
                        onTap: () => setState(() => _filter = filter),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    'Acil dikkat gerektirenler',
                    trailing: Text(
                      itemCountLabel(visibleUrgent.length),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (visibleUrgent.isEmpty)
                    _Reassurance(
                      icon: Icons.check_circle_outline,
                      text: watchlist.isEmpty
                          ? 'Henüz garanti bilgisi girilmiş eşya yok.'
                          : 'Şu an acil bir şey yok. Her şey kontrol altında.',
                    )
                  else
                    for (final item in visibleUrgent)
                      _UrgentCard(item: item, now: now),
                  if (safe.isNotEmpty) ...[
                    SectionHeader(
                      'Garantisi güvende olanlar',
                      trailing: Text(
                        itemCountLabel(safe.length),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        for (final item in safe.take(6))
                          _SafeTile(item: item, now: now),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? scheme.onPrimary.withValues(alpha: 0.85)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({required this.item, required this.now});

  final Item item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = item.warrantyStatus(now: now);
    final days = item.warrantyDaysRemaining(now: now)!;
    final accent =
        status == WarrantyStatus.expired ? scheme.outline : scheme.tertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(itemId: item.id),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ItemPhoto(path: item.photoPath, size: 52, radius: 12),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatShortDate(item.warrantyEndDate),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                status == WarrantyStatus.expired
                                    ? 'Garanti ${humanDuration(-days)} önce bitti'
                                    : 'Garanti $days Gün Sonra Bitiyor!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: status == WarrantyStatus.expired
                                      ? scheme.onSurfaceVariant
                                      : scheme.primary,
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
          ),
        ),
      ),
    );
  }
}

class _SafeTile extends StatelessWidget {
  const _SafeTile({required this.item, required this.now});

  final Item item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = Warranty.progress(
          item.purchaseDate,
          item.warrantyMonths,
          now: now,
        ) ??
        0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(itemId: item.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                warrantyShortLabel(
                  item.warrantyStatus(now: now),
                  item.warrantyDaysRemaining(now: now),
                  item.warrantyEndDate,
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 1 - progress,
                  minHeight: 5,
                  color: scheme.secondary,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reassurance extends StatelessWidget {
  const _Reassurance({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
