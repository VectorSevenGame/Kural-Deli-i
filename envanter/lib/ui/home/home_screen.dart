import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/inventory_store.dart';
import '../../data/models/item.dart';
import '../../data/models/room.dart';
import '../../util/formatters.dart';
import '../item/item_detail_screen.dart';
import '../item/item_edit_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/item_card.dart';
import '../widgets/warranty_pill.dart';

/// Eşya sıralama seçenekleri.
enum ItemSort {
  newestFirst('Yeniden eskiye'),
  oldestFirst('Eskiden yeniye'),
  nameAsc('Ada göre'),
  priceDesc('Pahalıdan ucuza'),
  warrantySoonest('Garantisi yakın');

  const ItemSort(this.label);

  final String label;
}

/// Ana ekran: oda filtresi + oda özeti + eşya listesi.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// `null` = "Tümü" sekmesi.
  String? _roomId;
  ItemSort _sort = ItemSort.newestFirst;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InventoryStore>();
    final scheme = Theme.of(context).colorScheme;

    if (store.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Seçili oda silinmişse "Tümü"ne dön.
    final selectedRoom = _roomId == null
        ? null
        : store.rooms.where((r) => r.id == _roomId).firstOrNull;
    final effectiveRoomId = selectedRoom?.id;

    final items = _sorted(
      effectiveRoomId == null
          ? store.items
          : store.itemsInRoom(effectiveRoomId),
    );

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              subtitle: 'Envanter · Odalar',
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  tooltip: 'Bildirimler',
                  onPressed: () => _showSoon(context),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _Title(store: store, onSort: _pickSort),
          ),
          SliverToBoxAdapter(
            child: _RoomTabs(
              store: store,
              selectedId: effectiveRoomId,
              onSelect: (id) => setState(() => _roomId = id),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SummaryCard(
                title: selectedRoom == null
                    ? 'Tüm Ev'
                    : '${selectedRoom.name} Koleksiyonu',
                items: items,
                store: store,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(
                'Eşyalar',
                trailing: TextButton(
                  onPressed: _pickSort,
                  child: Text(_sort.label),
                ),
              ),
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(roomName: selectedRoom?.name),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ItemCard(
                    item: item,
                    roomName: store.rooms
                        .where((r) => r.id == item.roomId)
                        .map((r) => r.name)
                        .firstOrNull,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(itemId: item.id),
                      ),
                    ),
                    onMore: () => _itemMenu(context, item),
                  );
                },
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _AddPrompt(
                roomName: selectedRoom?.name,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ItemEditScreen(initialRoomId: _roomId),
                  ),
                ),
              ),
            ),
          ),
          // Alt menü ve FAB'in altında kalmasın.
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    ).withBackground(scheme.surface);
  }

  List<Item> _sorted(List<Item> source) {
    final items = [...source];
    switch (_sort) {
      case ItemSort.newestFirst:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ItemSort.oldestFirst:
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case ItemSort.nameAsc:
        items.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case ItemSort.priceDesc:
        items.sort((a, b) => (b.priceKurus ?? -1).compareTo(a.priceKurus ?? -1));
      case ItemSort.warrantySoonest:
        final now = DateTime.now();
        items.sort((a, b) {
          final left = a.warrantyDaysRemaining(now: now);
          final right = b.warrantyDaysRemaining(now: now);
          if (left == null && right == null) return 0;
          if (left == null) return 1;
          if (right == null) return -1;
          return left.compareTo(right);
        });
    }
    return items;
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<ItemSort>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sırala',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            for (final option in ItemSort.values)
              ListTile(
                title: Text(option.label),
                trailing: option == _sort ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  Future<void> _itemMenu(BuildContext context, Item item) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ItemEditScreen(item: item),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Detayı aç'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(itemId: item.id),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bildirimler yakında eklenecek.')),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.store, required this.onSort});

  final InventoryStore store;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final expiring = store.expiringSoonCount();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evim & Eşyalarım',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    _Dot(
                      color: scheme.secondary,
                      text: 'Toplam ${itemCountLabel(store.items.length)}',
                    ),
                    if (expiring > 0)
                      _Dot(
                        color: scheme.tertiary,
                        icon: Icons.schedule,
                        text: '$expiring garantisi yaklaşan',
                        textColor: scheme.tertiary,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onSort,
            icon: const Icon(Icons.tune, size: 20),
            tooltip: 'Sırala',
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.text,
    this.icon,
    this.textColor,
  });

  final Color color;
  final String text;
  final IconData? icon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon == null)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
        else
          Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor ?? scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RoomTabs extends StatelessWidget {
  const _RoomTabs({
    required this.store,
    required this.selectedId,
    required this.onSelect,
  });

  final InventoryStore store;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget tab({
      required String label,
      required int count,
      required bool selected,
      required VoidCallback onTap,
      IconData? icon,
    }) {
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Material(
          color: selected ? scheme.primary : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: selected ? scheme.onPrimary : scheme.onSurface,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: selected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.onPrimary.withValues(alpha: 0.22)
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
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

    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        children: [
          tab(
            label: 'Tümü',
            icon: Icons.auto_awesome,
            count: store.items.length,
            selected: selectedId == null,
            onTap: () => onSelect(null),
          ),
          for (final Room room in store.rooms)
            tab(
              label: room.name,
              count: store.itemsInRoom(room.id).length,
              selected: selectedId == room.id,
              onTap: () => onSelect(room.id),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.items,
    required this.store,
  });

  final String title;
  final List<Item> items;
  final InventoryStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final healthy = store.isHealthy(items);
    final value = store.totalValueKurus(items);

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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chair_outlined,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: healthy
                      ? scheme.secondaryContainer
                      : scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  healthy ? 'Sağlıklı Envanter' : 'Dikkat Gerekiyor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: healthy
                        ? scheme.onSecondaryContainer
                        : scheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Metric(
                label: 'İçindeki eşya',
                value: '${items.length} parça',
              ),
              const SizedBox(width: 28),
              _Metric(
                label: 'Tahmini değer',
                value: formatPrice(value == 0 ? null : value),
                emphasize: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 18 : 13,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
            color: emphasize ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AddPrompt extends StatelessWidget {
  const _AddPrompt({required this.roomName, required this.onTap});

  final String? roomName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_a_photo_outlined,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName == null
                          ? 'Yeni Eşya Ekle'
                          : '$roomName Odasına Eşya Ekle',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fotoğraf çekerek veya elle kaydet',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.roomName});

  final String? roomName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: scheme.primary),
          const SizedBox(height: 18),
          Text(
            roomName == null
                ? 'En pahalı eşyanla başla'
                : '$roomName odası henüz boş',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'Buzdolabı, televizyon, kombi… Faturasını ekle, garantisinin '
            'ne zaman bittiğini bir daha hiç merak etme.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  /// Sekme içeriğine kabuğun arka planını verir.
  Widget withBackground(Color color) => ColoredBox(color: color, child: this);
}
