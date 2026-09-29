import 'package:flutter/material.dart';

import '../../data/models/item.dart';
import '../../domain/warranty.dart';
import '../../util/formatters.dart';

/// Garanti durumunun renk paleti. Tasarımdaki yeşil / amber / gri eşlemesi.
({Color background, Color foreground, IconData icon}) warrantyColors(
  BuildContext context,
  WarrantyStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    WarrantyStatus.active => (
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
        icon: Icons.verified_user_outlined,
      ),
    WarrantyStatus.expiringSoon => (
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
        icon: Icons.schedule,
      ),
    WarrantyStatus.expired => (
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
        icon: Icons.history_toggle_off,
      ),
    WarrantyStatus.unknown => (
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
        icon: Icons.help_outline,
      ),
  };
}

/// Eşya kartlarındaki küçük garanti rozeti: "14 Ay Kaldı".
class WarrantyPill extends StatelessWidget {
  const WarrantyPill({super.key, required this.item, this.now});

  final Item item;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final status = item.warrantyStatus(now: now);
    final colors = warrantyColors(context, status);
    final label = warrantyShortLabel(
      status,
      item.warrantyDaysRemaining(now: now),
      item.warrantyEndDate,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(colors.icon, size: 14, color: colors.foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nötr, ince etiket: oda adı, kategori.
class SoftChip extends StatelessWidget {
  const SoftChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: scheme.onSurfaceVariant),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bölüm başlığı: "EŞYALAR" gibi küçük, aralıklı, büyük harf.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            turkishUpper(title),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
