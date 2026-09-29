import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/inventory_store.dart';

/// Esya fotografi; yoksa kategori ikonu gosterir.
class ItemPhoto extends StatelessWidget {
  const ItemPhoto({
    super.key,
    required this.path,
    this.size = 56,
    this.radius = 12,
    this.fallbackIcon = Icons.inventory_2_outlined,
  });

  final String? path;
  final double size;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final file = context.read<InventoryStore>().photos.resolve(path);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: file == null
            ? ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  fallbackIcon,
                  color: scheme.onSurfaceVariant,
                  size: size * 0.42,
                ),
              )
            : Image.file(file, fit: BoxFit.cover),
      ),
    );
  }
}
