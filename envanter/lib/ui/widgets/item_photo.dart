import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/inventory_store.dart';

/// Eşya fotoğrafı; yoksa nötr bir ikon gösterir.
class ItemPhoto extends StatelessWidget {
  const ItemPhoto({
    super.key,
    required this.path,
    this.size = 56,
    this.radius = 12,
    this.fallbackIcon = Icons.inventory_2_outlined,
  });

  final String? path;

  /// `double.infinity` verilirse kapsayıcıyı doldurur.
  final double size;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = context.read<InventoryStore>().photos.imageProvider(path);
    final iconSize = size.isFinite ? size * 0.42 : 48.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: image == null
            ? ColoredBox(
                color: scheme.surfaceContainer,
                child: Icon(
                  fallbackIcon,
                  color: scheme.onSurfaceVariant,
                  size: iconSize,
                ),
              )
            : Image(image: image, fit: BoxFit.cover),
      ),
    );
  }
}
