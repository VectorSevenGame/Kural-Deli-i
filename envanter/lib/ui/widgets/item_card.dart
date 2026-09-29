import 'package:flutter/material.dart';

import '../../data/models/item.dart';
import '../../util/formatters.dart';
import 'item_photo.dart';
import 'warranty_pill.dart';

/// Listelerdeki eşya kartı: fotoğraf, oda etiketi, ad, garanti rozeti, fiyat.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.roomName,
    required this.onTap,
    this.onMore,
  });

  final Item item;
  final String? roomName;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItemPhoto(path: item.photoPath, size: 76, radius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SoftChip(label: roomName ?? 'Odasız'),
                            ),
                          ),
                          if (onMore != null)
                            InkResponse(
                              onTap: onMore,
                              radius: 20,
                              child: Icon(
                                Icons.more_vert,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(child: WarrantyPill(item: item)),
                          const SizedBox(width: 8),
                          if (item.priceKurus != null)
                            Text(
                              formatPrice(item.priceKurus),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
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
